# Phase 20.2 — Execution Replay Model

Every mission and execution artifact supports replay. Replay must reproduce identical ordering, identical hashes, and identical artifacts.

## Core Principle

Given the same inputs, replay always produces identical outputs. Replay is the foundation of constitutional accountability.

## Replay Types

| Replay Type | Description |
|---|---|
| Mission Replay | Replay the full mission lifecycle |
| Queue Replay | Replay queue state mutations |
| Execution Replay | Replay subsystem execution trace |
| Knowledge Replay | Replay knowledge integration sequence |
| Event Replay | Replay the full event sequence |
| Resource Replay | Replay resource allocation sequence |
| System Replay | Replay the full system state evolution |

## Replay Chain

Every mission has a replay chain rooted in mission_id. The replay chain is an ordered sequence of replay artifacts, each linked to the previous via content hashes.

## Deterministic Ordering

Ordering is determined by (in order of precedence):
1. **Priority** — Higher priority missions execute first
2. **Dependency graph** — Missions with satisfied dependencies execute before those with unsatisfied
3. **Timestamp** — Earlier timestamps execute before later
4. **Content hash** — Tie-breaking via content hash for deterministic ordering

## Replay Artifacts

Each replay step produces:
- Replay artifact with step data
- Content hash linking to previous step
- Evidence of the replayed state
- Archaeology lineage record

## Failure Handling

Failures during execution produce:
- MissionFailed event
- Failure evidence (all evidence produced before failure)
- Failure replay artifacts (execution trace up to failure point)
- Failure archaeology artifacts (lineage of the failure)
- Failure metrics (resource utilization, timing)
- Rollback recommendation (deterministic rollback path)

Failures never disappear. Once recorded, a failure is an immutable constitutional artifact.
