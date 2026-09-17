# Phase 18.2 — Constitutional Cognitive Kernel Report

## Mission Lifecycle

The kernel defines seven mission states with a deterministic lifecycle:

```
                  +----------+
                  | submitted|
                  +----+-----+
                       |
                       v
                  +----+-----+
            +-----> running  <----+
            |     +----+-----+    |
            |          |          |
            |          v          |
            |     +----+-----+    |
            |     |  paused   +---+
            |     +----+-----+
            |          |
            |          v
            |     +----+------+
            |     | completed |
            |     +----+------+
            |          |
            |          v
            |     +----+-----+
            |     |  failed   |
            |     +----+-----+
            |          |
            |          v
            |     +----+------+
            +-----> archived  |
                  +-----------+
```

1. **submitted** — Mission artifact validated and accepted into kernel state
2. **running** — Mission is actively being processed through the execution pipeline
3. **paused** — Execution suspended; may be resumed later
4. **resumed** — Returns to running without re-creating the mission
5. **completed** — All tasks successfully dispatched; terminal success state
6. **failed** — A failure was encountered; terminal error state
7. **archived** — Immutable record retained for replay and lineage

Transitions: submitted → running, running ↔ paused, running → completed/failed, completed/failed → archived.

## Execution Pipeline

```
  +-------------------+     +--------------------+
  | Mission Submission+---->+ MissionController  |
  +-------------------+     +---------+----------+
                                       |
                                       v
                              +--------+---------+
                              |  ContextBuilder  |
                              +--------+---------+
                                       |
                                       v
                              +--------+---------+
                              |AttentionCoord.   |
                              +--------+---------+
                                       |
                                       v
                              +--------+---------+
                              |  TaskDispatcher  |
                              +--------+---------+
                                       |
                                       v
                              +--------+---------+
                              |EvidenceCollector |
                              +--------+---------+
                                       |
                                       v
                              +--------+---------+
                              | ReplayCoordinator |
                              +--------+---------+
                                       |
                                       v
                              +--------+---------+
                              |ArchaeologyRecord. |
                              +--------+---------+
                                       |
                                       v
                              +--------+---------+
                              |  Mission Complete |
                              +-------------------+
```

### Stage Descriptions

| Stage | Component | Responsibility |
|-------|-----------|----------------|
| 1 | Mission Submission | Caller provides mission artifact (objective, goal_graph, task_graph, dependencies) |
| 2 | MissionController | Validates mission artifact and creates deterministic mission state with `:submitted` status; transitions to `:running` |
| 3 | ContextBuilder | Assembles cognitive context from working memory, knowledge graph refs, world model refs, discovery refs, and mathematics refs; sorts all refs deterministically by content hash |
| 4 | AttentionCoordinator | Orders tasks by priority, dependency_order, submission_order, and content hash; produces deterministic attention state |
| 5 | TaskDispatcher | Routes ordered tasks to certified subsystem references; produces dispatch intents (intent-only — no execution) |
| 6 | EvidenceCollector | Converts each pipeline transition into an evidence artifact with ledger hash |
| 7 | ReplayCoordinator | Builds replay root from evidence chain; all artifacts must carry evidence_id |
| 8 | ArchaeologyRecorder | Captures full lineage (mission, dispatch, evidence chain, replay root) as an archaeology artifact |
| 9 | Mission Complete | Kernel state updated with mission, evidence, replay, and archaeology entries |

## Dispatcher Architecture

The `TaskDispatcher` routes tasks by their `target_subsystem` field to certified subsystem references registered at kernel initialization.

### Routing Table

| Task Type | Target Subsystem | Certified Phase |
|-----------|-----------------|-----------------|
| `scientific_discovery` | SMCP | Phase 15 |
| `research` | REA | Phase 16 |
| `mathematics` | Mathematics Epistemic Substrate | Phase 16.X |
| `world_model` | WorldModel | Phase 17.2–17.6 |
| `simulation` | DigitalTwin | Phase 17.7 |
| `experiment` | ARPE | Phase 17.8 |

Each task in `attention_state.ordered_tasks` carries a `target_subsystem` key. The dispatcher matches it against the subsystem's `subsystem` key in the certified subsystems list. If no match is found, dispatch halts with an error.

## Evidence Flow

Every pipeline transition emits an `EvidenceReference` (`EvidenceCollector.collect_transition/3`) containing:

```
%{
  evidence_id:     "cckevidence_<content_hash>",
  stage:           :mission_running | :context_built | :attention_allocated | :dispatch_intents_created,
  payload_ref:     <fingerprint of payload>,
  payload:         <the stage payload>,
  replay_timestamp: <caller-supplied replay timestamp>
}
```

The chain is:

```
mission_evidence → context_evidence → attention_evidence → dispatch_evidence
```

Each evidence artifact is content-addressed via `Artifact.content_id/2` with the `"cckevidence"` prefix. The evidence chain is appended to `kernel_state.evidence_ledger`.

## Replay Flow

Every mission produces a replay root via `ReplayCoordinator.build/1`:

```
%{
  replay_root_id: "cckreplay_<content_hash>",
  evidence_ids:   [list of evidence_id strings],
  evidence_hashes: [list of fingerprints]
}
```

- Each replay root is keyed by `(mission_id, sequence_number)` implicitly through its evidence chain
- Replay roots are built from **immutable evidence artifacts only** — no live state is consulted
- All evidence artifacts in the chain must carry `:evidence_id`; validation occurs in `ReplayCoordinator.build/1`
- Replay roots are appended to `kernel_state.replay_roots`

## Archaeology Flow

Every mission, task, and dispatch has an archaeology record via `ArchaeologyRecorder.record/1`:

```
%{
  archaeology_id: "cckarch_<content_hash>",
  mission_ref:    <fingerprint of mission_state>,
  dispatch_ref:   <fingerprint of dispatch_root>,
  evidence_refs:  [fingerprints of each evidence artifact],
  replay_ref:     <fingerprint of replay_root>
}
```

- Provides full lineage from mission artifact through execution and replay
- All references are content-addressed fingerprints (deterministic)
- Archaeology records are appended to `kernel_state.archaeology_ledger`

## Integration Coverage

The `TaskDispatcher` integrates with the following Phase 15–17 certified subsystems (intent-only; no execution):

| Phase | Subsystem | Role |
|-------|-----------|------|
| 15 | SMCP (Scientific Meta-Cognition Protocol) | Scientific discovery tasks |
| 16 | REA (Research Exchange Agent) | Research tasks |
| 16.X | Mathematics Epistemic Substrate | Mathematics verification tasks |
| 17.2–17.6 | WorldModel | World model prediction and reasoning |
| 17.7 | DigitalTwin | Simulation tasks |
| 17.8 | ARPE (Autonomous Research Proposal Engine) | Experiment tasks |

Integration is limited to dispatch intent creation. Subsystem execution requires Phase 18.3+ real binding.

## Failure Coverage

All failure modes result in a **fail-closed** response (`{:error, reason}`):

| Failure Mode | Detection Point | Behavior |
|-------------|----------------|----------|
| Missing subsystem | `TaskDispatcher.dispatch/2` — subsystem not found in certified list | Halts dispatch, returns `{:error, "certified subsystem is unavailable for target ..."}` |
| Invalid mission | `MissionController.create/2` — missing required fields | Returns `{:error, "... is required"}` |
| Dependency failure | `ExecutiveKernel.submit_mission/3` — any `with` clause fails | Pipeline halts immediately, returns error |
| Replay mismatch | `ReplayCoordinator.build/1` — evidence missing `:evidence_id` | Returns `{:error, "all evidence artifacts must contain evidence_id"}` |
| Hash corruption | `Artifact.fingerprint/1` — non-deterministic input | Content hash mismatch detectable on replay |
| Mission timeout | Not yet implemented (see limitations) | N/A — timeout is a future extension |
| Non-existent mission | `ExecutiveKernel.fetch_mission/2` — mission_id not in kernel state | Returns `{:error, "mission <id> is not present in kernel state"}` |
| Invalid transition | `MissionController.transition/3` — status not in valid list | Returns `{:error, "transition received invalid transition input"}` |

## Metrics Collected

The kernel maintains the following counters and latency measurements (all initialized to zero):

| Metric | Type | Description |
|--------|------|-------------|
| `missions_submitted` | counter | Total missions submitted |
| `missions_completed` | counter | Missions that reached completed status |
| `missions_failed` | counter | Missions that reached failed/cancelled status |
| `scheduling_latency` | timer | Time spent in MissionController |
| `dispatch_latency` | timer | Time spent in TaskDispatcher |
| `context_latency` | timer | Time spent in ContextBuilder |
| `evidence_latency` | timer | Time spent in EvidenceCollector |
| `replay_latency` | timer | Time spent in ReplayCoordinator |
| `archaeology_latency` | timer | Time spent in ArchaeologyRecorder |

Metrics are available via `ExecutiveKernel.status/1` which reports kernel_id, status, mission_count, evidence_count, replay_root_count, and archaeology_count.

## Known Limitations

1. **No persistence layer** — Missions exist only in kernel state (in-memory map). Restart destroys all state.
2. **No distributed execution** — All components run in a single process. No cluster or multi-node support.
3. **Subsystem execution is simulated** — `TaskDispatcher` creates dispatch intents only. Real subsystem binding requires Phase 18.3+.
4. **No timeout mechanism** — Missions run indefinitely until explicitly paused, completed, cancelled, or failed.
5. **No metrics instrumentation** — Latency counters are placeholders; no telemetry emission is wired yet.
6. **Linear evidence chain** — Evidence artifacts form a flat list; no branching or parallel evidence paths.

## Future Extension Points

1. **Persistence backend** — Store kernel state, evidence ledger, replay roots, and archaeology ledger in Mnesia or similar.
2. **Distributed mission coordination** — Distribute missions across cluster nodes with consensus-based handoff.
3. **Real subsystem binding** — Replace dispatch intents with actual IPC/NATS calls to certified Phase 15–17 subsystems.
4. **Performance optimization** — Add parallel pipeline execution, caching of content hashes, and lazy archaeology recording.
5. **Timeout and preemption** — Add mission-level timeouts with preemption signals and graceful shutdown.
6. **Telemetry and metrics** — Wire OpenTelemetry/metrics instrumentation for all pipeline stages.
7. **Branching evidence** — Support forked evidence chains and multi-path replay verification.
