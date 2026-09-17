# Phase 18.5 — Plan Replay Model

## Replay Key

Every replay artifact is indexed by a composite key:

```
(planning_session_id, iteration_number, step_name)
```

- `planning_session_id` — UUID v4, unique per planning session.
- `iteration_number` — Monotonically increasing counter. When the same mission is re-planned, iteration increments.
- `step_name` — One of: `goal_decomposition`, `task_planning`, `alternative_generation`, `constraint_evaluation`, `tradeoff_analysis`, `plan_ranking`, `plan_assembly`, `ledger_append`.

## Replay Artifact Structure

Each replay artifact is a self-contained JSON document with the following mandatory fields:

```jsonc
{
  "session_id": "uuid",
  "iteration": 1,
  "step": "goal_decomposition",
  "parent_hash": "sha256-of-previous-step-artifact",
  "hash": "sha256-of-this-artifact",
  "inputs": { /* deterministic input references */ },
  "outputs": { /* step output */ },
  "internal_state": { /* step-specific state for exact reconstruction */ },
  "timestamp": "ISO-8601",
  "runtime_version": "semver"
}
```

### Hash Chain

Replay artifacts form a hash chain:

```
hash_0 = H(genesis || session_id || iteration)
hash_1 = H(step_1_artifact || hash_0)
hash_2 = H(step_2_artifact || hash_1)
...
```

This ensures:
- **Integrity** — Tampering with any step breaks the chain.
- **Ordering** — Steps cannot be reordered or omitted.
- **Completeness** — Missing steps are detected by hash gaps.

## Replay Reconstruction

To reconstruct a planning session:

1. **Locate** all replay artifacts for `(session_id, iteration)` ordered by step sequence.
2. **Verify** the hash chain from genesis to final step.
3. **Execute** each step's logic using only `inputs` from the replay artifact:
   - `GoalDecomposer.replay(inputs)` → goals
   - `TaskPlanner.replay(inputs)` → task_graph
   - `AlternativeGenerator.replay(inputs)` → alternatives
   - `ConstraintEvaluator.replay(inputs)` → constraints
   - `TradeoffAnalyzer.replay(inputs)` → tradeoffs
   - `PlanRanker.replay(inputs)` → ranking
   - `PlanAssembler.replay(inputs)` → assembled plan
4. **Assert** that the output of each `replay()` matches the `outputs` field in the artifact.

## Immutability Guarantee

Replay artifacts are written once and never modified. They are stored in:

```
.replay/phase18/plans/{session_id}/{iteration}/{step_name}.json
```

- The `.replay/` directory is append-only.
- No runtime process may delete or alter a replay artifact.
- Replay artifacts are backed up before any ledger compaction.

## No Runtime Memory

Replay does not access:
- Working memory (Phase 18.3)
- Attention state (Phase 18.4)
- Kernel process heap
- Any mutable global state

All information required for replay is contained within the replay artifacts and the immutable constitutional constraint definitions (Phase 18.1).

## Replay Consumers

| Consumer | Use Case |
|----------|----------|
| Audit subsystem | Verify that the chosen plan followed proper procedure |
| Debugger | Step-through reconstruction of failed planning sessions |
| Archaeology | Aggregate replay artifacts across sessions |
| Certification | Validate that Phase 18.5 implementation matches spec |
| Constitutional review | Check that constraint evaluation was faithful |

## Replay Error Handling

If replay produces output that does not match the recorded `outputs`, the replay artifact is marked `corrupt` and the session is flagged for manual review. Possible causes:
- Runtime version mismatch (mitigated by `runtime_version` field)
- Non-deterministic step logic (bug)
- Artifact tampering (security incident)
