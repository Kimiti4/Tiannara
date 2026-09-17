# Phase 20.5 — Runtime Replay Model

## Overview

The Runtime Replay Model defines how every runtime generation, migration, merge, and rollback supports deterministic replay. Replay must reproduce identical SHA-256 hashes at every step, across all generation operations.

## Replay Types

### Generation Replay
Reconstruct a complete runtime generation from its constituent artifacts. Starting from generation metadata, reconstruct all modules, knowledge graph, mathematics framework, world models, configuration, and registries. Must reproduce identical constitutional_hash.

### Migration Replay
Reconstruct the transition from source generation to target generation. Starting from pre-migration snapshot, apply all migration transforms in order. Must reproduce identical intermediate state hashes and final state hash.

### Merge Replay
Reconstruct a constitutional merge. Starting from source and target branch generations, apply merge resolution transforms. Must reproduce identical merge_hash and final generation state.

### Rollback Replay
Reconstruct a rollback from a target generation back to source generation. Starting from post-migration state, apply inverse migration transforms. Must reproduce identical pre-migration state hash.

### Branch Replay
Reconstruct the complete evolution of a single branch. Starting from branch genesis, replay every generation, migration, and merge on the branch in order. Must reproduce identical final branch state.

### Full System Replay
Reconstruct the entire operating system evolution from genesis. Starting from generation 0, replay every generation, migration, merge, and rollback across all branches. Must reproduce identical generation hashes at every step.

## Replay Chain Structure

Each replay type produces a chain of step hashes:

```
step_hash[0] = SHA-256(genesis_seed || replay_type || source_generation_hash)
step_hash[N] = SHA-256(step_hash[N-1] || step_data[N])
root_hash = step_hash[N]  (final step)
```

Where:
- step_data[N] = canonical binary encoding of step N's inputs and outputs
- root_hash = stored in the object's replay_root field

## Deterministic Ordering

Replay steps are ordered by:

1. **Priority** — lower priority executes first (defined per object type)
2. **Dependency graph** — objects replay in dependency order (DAG; dependency before dependent)
3. **Timestamp** — within same priority and dependency level, earlier timestamps first
4. **Content hash** — as final tiebreaker, lexicographically smaller content hashes first

## Ordering Rules

| Object Type | Priority | Dependencies |
|-------------|----------|--------------|
| RuntimeGeneration | 1 | Parent generation |
| RuntimeMigration | 2 | Source generation, target generation |
| RuntimeMerge | 3 | Source branch generation |
| RuntimeFreeze | 4 | RuntimeGeneration |
| RuntimeBranch | 5 | Base generation |

## Verification

- Every replay step must produce an identical SHA-256 hash to the recorded value
- If any step produces a different hash, replay is considered failed
- A failed replay triggers a RollbackEvent and alerts constitutional monitoring
- The ReplayRegistry tracks all replay roots and verification status

## Constraints

- Replay must be fully deterministic: same inputs always produce same outputs
- Replay must be acyclic: no replay step depends on a later step
- Replay must be content-addressed: every intermediate hash uniquely identifies that state
- Replay must be independent of runtime state: cold storage replay must reproduce identical hashes
- Full system replay from genesis must reproduce every generation hash exactly
