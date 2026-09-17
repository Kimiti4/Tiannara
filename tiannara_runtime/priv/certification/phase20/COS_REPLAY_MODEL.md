# Phase 20.1 — COS Replay Model

## Overview
Every constitutional object supports deterministic replay. Replay must reproduce identical SHA-256 hashes at every step. The replay chain is rooted in the `generation_id` field.

## Replay Types

| Replay Type | Description |
|-------------|-------------|
| Creation Replay | Reconstruct the object from its initial inputs. Must produce identical `id` and `fingerprint`. |
| Mutation Replay | Reconstruct every mutation applied to the object in order. Each intermediate state must match the recorded hash. |
| Integration Replay | Reconstruct the integration of the object into a generation. Must reproduce the `constitutional_hash` of the resulting RuntimeGeneration. |
| Retirement Replay | Reconstruct the retirement sequence. Must reproduce the retirement chain and updated ExtensionRegistry. |
| Generation Replay | Reconstruct an entire generation from genesis. Starting from generation 0, apply every proposal, candidate, benchmark, deployment, and retirement in order. Must reproduce the final `constitutional_hash`. |

## Replay Chain

- Each replay type produces a chain of step hashes.
- Each step hash is `SHA-256(previous_hash || step_data)`.
- The complete chain is stored in the `replay_root` field of the object.
- The `EvolutionReplay` object captures the full replay chain for a generation.

## Deterministic Ordering

Replay steps are ordered by the following criteria, applied in sequence:

1. **Priority** — lower numeric priority executes first (defined per object type).
2. **Dependency graph** — objects must be replayed in dependency order (DAG). A dependency must be replayed before its dependent.
3. **Timestamp** — within the same priority and dependency level, earlier timestamps replay first.
4. **Content hash** — as a final tiebreaker, lexicographically smaller content hashes replay first.

## Verification

- Every replay step must produce an identical SHA-256 hash to the recorded value.
- If any step produces a different hash, the replay is considered failed.
- A failed replay triggers a RollbackEvent and alerts the constitutional monitoring system.
- The ReplayRegistry tracks all replay roots and their verification status.

## Replay Registry

| Function | Description |
|----------|-------------|
| register | Register a new replay root and its chain |
| lookup | Retrieve a replay chain by root hash |
| verify | Verify that a replay chain produces the claimed final hash |

## Constraints

- Replay must be fully deterministic: same inputs always produce same outputs.
- Replay must be acyclic: no replay step may depend on a later step.
- Replay must be content-addressed: every intermediate hash uniquely identifies that state.
