# Phase 18.3 — Constitutional Working Memory & Context Management: Report

## Architecture Overview

The Phase 18.3 working memory system is composed of 7 coordinated engines:

| # | Engine | Responsibility |
|---|--------|----------------|
| 1 | WorkingMemory | Key-value store with versioning, LRU-like eviction, configurable capacity |
| 2 | MemoryFrame | Lifecycle-managed frame with evidence, replay, archaeology refs |
| 3 | CognitiveWorkspace | Top-level workspace binding working memory, attention, mission, tasks |
| 4 | ActivationGraph | Directed acyclic graph with cycle detection, topological ordering |
| 5 | ContextAssembler | Assembles and sorts references into deterministic context state |
| 6 | ContextSnapshot | Fingerprinted point-in-time capture with hash verification |
| 7 | ContextReplay | Replay record creation and fingerprint-based state verification |

All 7 engines are pure-functional — no GenServer, no ETS, no side effects. Every operation returns a new state or an error tuple.

## Lifecycle

```
  +----------------+     +-------------------+     +------------------+
  | Mission Starts +---->+ Workspace Created +---->+ Frames Created   |
  +----------------+     +-------------------+     +--------+---------+
                                                             |
                                                             v
                                                    +--------+---------+
                                                    | Activation Graph |
                                                    +--------+---------+
                                                             |
                                                             v
                                                    +--------+---------+
                                                    | Context Assembled|
                                                    +--------+---------+
                                                             |
                                                             v
                                                    +--------+---------+
                                                    | Snapshots Gen.   |
                                                    +--------+---------+
                                                             |
                  +-------------------+                      |
                  | Replay Preserved  <----------------------+
                  +--------+----------+
                           |
                           v
                  +--------+----------+
                  | Mission Ends      |
                  +--------+----------+
                           |
                           v
                  +--------+----------+
                  | Workspace Destroy |
                  +-------------------+
```

1. **Mission Starts** — A mission artifact is submitted, carrying objective, goal_graph, task_graph, dependencies
2. **Workspace Created** — `CognitiveWorkspace.create/2` binds working memory, attention state, and mission state into a single workspace
3. **Frames Created** — `MemoryFrame.create_frame/3` produces a frame keyed by mission_id and owner with `:active` status
4. **Activation Graph Built** — `ActivationGraph.create/0` initializes empty graph; nodes and edges are added deterministically with cycle detection
5. **Context Assembled** — `ContextAssembler.assemble/4` sorts knowledge refs and world model refs, producing a deterministic context state
6. **Snapshots Generated** — `ContextSnapshot.capture/3` creates a fingerprinted point-in-time snapshot; `ContextSnapshot.verify/1` validates integrity
7. **Mission Ends** — The workspace transitions to terminal state (completed, failed, or cancelled)
8. **Workspace Destroyed** — `CognitiveWorkspace.destroy/1` sets status to `:destroyed`
9. **Replay Preserved** — `ContextReplay.record/2` persists the snapshot as an immutable replay artifact

## Replay Model

Replay is fully deterministic and reconstructable from immutable artifacts:

```
                         +---------------------+
                         | Immutable Artifacts |
                         +----------+----------+
                                    |
            +-----------------------+-----------------------+
            |                       |                       |
            v                       v                       v
   +--------+--------+   +---------+--------+   +----------+------+
   | Working Memory  |   | Memory Frames    |   | Snapshots       |
   | (store,version, |   | (frame_id,       |   | (fingerprint,   |
   |  capacity,usage)|   |  mission_id,     |   |  workspace,     |
   |                 |   |  evidence_refs,  |   |  context_state, |
   |                 |   |  status)         |   |  activation_gr.)|
   +-----------------+   +------------------+   +-----------------+
            |                       |                       |
            +-----------------------+-----------------------+
                                    |
                                    v
                         +----------+----------+
                         | Activation Graph    |
                         | (nodes, edges)      |
                         +----------+----------+
                                    |
                                    v
                         +----------+----------+
                         | Context Replay      |
                         | (replay_id,         |
                         |  snapshot_id,       |
                         |  recorded_at)       |
                         +---------------------+
```

- A replay record carries the snapshot's fingerprint and the full state.
- `ContextReplay.reconstruct/1` extracts the snapshot_id from a replay record.
- `ContextReplay.verify_state/2` recomputes a SHA-256 fingerprint from the state and compares it to the expected fingerprint.
- Fingerprints exclude non-deterministic fields (`:captured_at`, `:fingerprint`).

## Evidence Types

| Evidence Type | Description |
|---------------|-------------|
| `MemoryCreated` | A key-value entry was inserted into working memory |
| `MemoryUpdated` | An existing key was updated with a new value and version |
| `MemoryRemoved` | A key was removed from working memory |
| `SnapshotCreated` | A fingerprinted snapshot was captured from the workspace |
| `SnapshotRestored` | A snapshot was restored into working memory state |
| `EvictionOccurred` | An entry was evicted due to capacity constraints |
| `ReplayGenerated` | A replay record was created from a snapshot |
| `ArchaeologyUpdated` | Archaeology references were recorded on a frame or workspace |

## Archaeology

Archaeology provides full lineage tracking for every artifact in the working memory system:

- **Why object existed** — Purpose recorded in `origin.type` and `origin.purpose` fields
- **Who created it** — Owner/mission_id captured in `origin.mission_id` and origin metadata
- **Which mission/task/evidence/replay** — Lineage chain records all ancestor artifacts with fingerprints
- **When removed** — Eviction produces an `EvictionOccurred` evidence artifact; frame expiration sets `status: :expired`
- **What replaced it** — Working memory updates carry version numbers; evicted entries are replaced by newer insertions

Both `MemoryFrame` and `CognitiveWorkspace` carry `archaeology_refs` lists that accumulate archaeology references throughout the lifecycle.

## Memory Model

The working memory engine (`Engines.WorkingMemory`) implements a constitutional key-value store:

```
%{
  store:    %{key => %{value: any, version: integer, inserted_at: integer}},
  capacity: integer,
  usage:    integer,
  version:  integer,
  frames:   [],
  snapshots: []
}
```

- **Key-value store** — Entries are stored in a plain Elixir map under `state.store`
- **Version** — Every mutation increments `state.version`; each entry carries its own version
- **LRU-like eviction** — When `usage >= capacity`, the entry with the oldest `inserted_at` is removed
- **Max configurable capacity** — Default capacity is 1024; callers may pass any positive integer to `create/1`

### Eviction Policy

The eviction policy is **least-recent constitutionally-created eviction**:

1. When `insert/3` is called and `state.usage >= state.capacity`, the eviction path is triggered
2. The entry with the minimum `inserted_at` value is selected (oldest inserted entry)
3. That entry is removed via `remove/2`, producing `{:ok, state}` with decremented usage
4. **The new entry is not inserted** — the eviction is fail-evict: room is freed but no automatic retry
5. The eviction itself produces an evidence artifact (`EvictionOccurred`)

```
insert(state, key, value)
  ├── usage < capacity → store entry, increment usage
  └── usage >= capacity → evict(state)
                            └── find oldest inserted_at
                            └── remove(key) → {:ok, state} with decremented usage
```

## Integration with Phase 18.2 Executive Kernel

The Phase 18.2 Executive Kernel (MissionController, ContextBuilder, AttentionCoordinator, TaskDispatcher, EvidenceCollector, ReplayCoordinator, ArchaeologyRecorder) provides the mission lifecycle and execution pipeline. Phase 18.3 working memory extends the kernel with:

- `CognitiveWorkspace` replaces raw working memory structs as the top-level state container
- `MemoryFrame` provides per-mission frame lifecycle (create, add_evidence, add_replay, add_archaeology, expire)
- `ActivationGraph` provides deterministic task dependency ordering and cycle detection
- `ContextAssembler` feeds context state (with sorted refs) into the kernel's `ContextBuilder`
- `ContextSnapshot` adds verifiable point-in-time captures to the kernel's evidence pipeline
- `ContextReplay` integrates with `ReplayCoordinator` for deterministic replay from immutable artifacts

## Integration with Phase 18.4 Attention System

Phase 18.4 Attention System (AttentionCoordinator) consumes the context and activation graph produced by Phase 18.3 to order tasks deterministically. The integration points are:

- `ActivationGraph.get_topological_order/1` provides the task dependency ordering
- `ContextAssembler.assemble/4` produces the context state consumed by `AttentionCoordinator.allocate/2`
- Working memory entries feed into the attention allocation priority computation
- Snapshots provide the baseline state for attention re-computation on resume

## Known Limitations

1. **No persistence** — Working memory, frames, workspaces, activation graphs, snapshots, and replay records exist only in process memory. Restart destroys all state.
2. **In-memory only** — All 7 engines are pure Elixir data structures. No ETS, Mnesia, or disk storage.
3. **Single-process** — No distribution, clustering, or multi-node coordination.
4. **No automatic retry on eviction** — When an insert triggers eviction, the new entry is not automatically inserted; the caller receives the evicted state.
5. **Linear history** — Frames and snapshots form flat lists; no branching or parallel versioning.
6. **No TTL/timeout** — Entries persist until explicitly removed or evicted. No time-to-live mechanism.

## Future Extensions

1. **Distributed working memory** — Shard the store across cluster nodes using consistent hashing or CRDT-based replication.
2. **Persistent snapshot store** — Write snapshots to Mnesia, RocksDB, or a file-based archive for crash recovery and long-term replay.
3. **Branching frames** — Support forked frame histories and multi-path replay verification.
4. **Automatic retry on eviction** — After eviction, attempt to insert the new entry into the freed slot.
5. **TTL-based eviction** — Add configurable time-to-live per entry, with background sweep for expired entries.
6. **Metrics and telemetry** — Wire OpenTelemetry counters for insert/update/remove/evict/snapshot/replay operations.
7. **Snapshot scheduling** — Configurable periodic snapshot capture for continuous replay capability.
