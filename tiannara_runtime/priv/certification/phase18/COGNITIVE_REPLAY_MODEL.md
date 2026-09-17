# Phase 18.0 — Cognitive Replay Model

## 1. Deterministic Replay

The Executive Cognitive Kernel guarantees deterministic replay of any past pipeline invocation. Replay requires only immutable artifacts from the cognitive ledger. No runtime memory, live state, or mutable subsystem state may participate in replay.

## 2. Replay Roots

| Field | Value |
|---|---|
| **Identifier** | `mission_id + sequence_number` |
| **mission_id** | Unique identifier assigned at mission creation. Stable for the lifetime of the mission. |
| **sequence_number** | Monotonically increasing integer scoped to a mission. Each pipeline invocation increments the sequence. |
| **Uniqueness** | The tuple `(mission_id, sequence_number)` is globally unique and permanently resolvable. |

## 3. Replay Ordering

- **Strict sequential** by `sequence_number` within a mission.
- Replay processes pipeline invocations in ascending sequence number order.
- No out-of-order replay is permitted for a given mission.

### 3.1 Tie-Breaking

- If two replay roots share the same `(mission_id, sequence_number)` — which is prohibited by construction but must be handled — **content hash** is the tie-breaker.
- The content hash is the SHA-256 hash of the complete ReplayRecord artifact.
- The root with the **lower content hash** (interpreted as a big-endian unsigned integer) replays first.
- Tie-breaking is deterministic and itself recorded.

## 4. Context Reconstruction

- **Source artifacts**: Mission archive + Task archive + Evidence archive
- **Procedure**: Replay loads the Mission record for `mission_id`, loads each CognitiveTask record by sequence number, and loads all EvidenceReferences attached to each task.
- **Reconstruction guarantee**: The full CognitiveContext present at the time of the original pipeline invocation is recoverable from these three archives.

## 5. Memory Reconstruction

- **Source artifacts**: Archived WorkingMemory snapshots
- **Procedure**: Replay loads the WorkingMemorySnapshot recorded at the Observation Ingest stage of the target pipeline invocation.
- **Reconstruction guarantee**: The exact transient state at pipeline entry is restored.
- **Constraint**: WorkingMemory snapshots are read-only. Replay may not mutate them.

## 6. Attention Reconstruction

- **Source artifacts**: AttentionState archives
- **Procedure**: Replay loads the AttentionState record associated with the target `(mission_id, sequence_number)`.
- **Reconstruction guarantee**: The attention allocation (active missions, priorities, urgency signals) at the time of decision is fully restored.

## 7. Decision Reconstruction

- **Source artifacts**: Decision archives + Evidence chain
- **Procedure**: Replay loads the DecisionRecord for the target invocation, then loads all supporting EvidenceReferences to reconstruct the full evidence chain.
- **Reconstruction guarantee**: The decision, all alternatives, and the complete evidence basis for the selection are restored.
- **Constraint**: Replay evaluates only that the evidence chain is intact; it does not re-evaluate the decision itself.

## 8. Planning Reconstruction

- **Source artifacts**: Plan archives + Simulation evidence
- **Procedure**: Replay loads the PlanRecord for the target invocation, including all bid responses, then loads the SimulationRecord for each plan step.
- **Reconstruction guarantee**: The plan structure, all submitted bids, the selected plan, and all simulation outputs are restored.

## 9. Scheduler Reconstruction

- **Source artifacts**: SchedulerState archives
- **Procedure**: Replay loads the SchedulerState record timestamped to the target pipeline invocation.
- **Reconstruction guarantee**: The scheduler queue (pending, active, completed tasks) at the time of invocation is restored.

## 10. Mission Reconstruction

- **Source artifacts**: Goal archives + Mission archives
- **Procedure**: Replay loads the Mission record for `mission_id`, then loads all Goal records referenced by the mission.
- **Reconstruction guarantee**: The full goal set and mission definition at the time of invocation are restored.

## 11. Immutability Constraint

**No runtime memory may participate in replay.** Specifically:

- No live subsystem state may be queried or loaded.
- No WorkingMemory outside of archived snapshots may be accessed.
- No mutable caches, connection pools, or in-memory indexes may be consulted.
- All data must resolve from the immutable cognitive ledger.

## 12. Replay Verification

Replay is considered verified when:

1. All replay roots for the target sequence range are loaded.
2. All evidence chains are intact (no broken references, all hashes match).
3. All archaeology entries are complete.
4. Context, memory, attention, decision, planning, scheduler, and mission reconstruction all complete without error or data loss.

## 13. Replay Failure Modes

| Failure | Handling |
|---|---|
| Missing replay root | Replay halts; failure is recorded; mission marked as incomplete in audit. |
| Corrupted artifact | Replay halts; artifact hash mismatch recorded; constitutional audit triggered. |
| Broken evidence chain | Replay continues with degraded reconstruction; broken link recorded. |
| Irresolvable reference | Replay halts; unresolvable reference recorded; constitutional audit triggered. |
