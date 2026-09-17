# Phase 20.9 — Rollforward Engine

## Role

The Rollforward Engine governs constitutional forward migration after successful validation. Unlike rollback (which restores a previous state), rollforward specifies how the operating system transitions to a new runtime generation while preserving all state, knowledge, mathematics, and archaeology.

## Inputs

- ProductionCandidate with transition plan
- Source generation (Current)
- Target generation (Production Candidate)
- All certification and verification artifacts

## Outputs

- RollforwardRecord with transition hash, migrated state hashes, verification results

## Rollforward Transformations

### State Transformation
Deterministic transformation of runtime state from source to target generation.

| Domain | Transformation |
|--------|---------------|
| Module state | Apply module state deltas from integration |
| Configuration | Apply configuration changes |
| Registry state | Update registry entries for new generation |
| Resource allocation | Reallocate resources per new generation requirements |

### Knowledge Migration
Deterministic migration of knowledge from source to target generation.

| Domain | Transformation |
|--------|---------------|
| Knowledge graph | Apply knowledge updates from validated experiments |
| Ontology | Apply ontology extensions |
| Cross-references | Update cross-references for new knowledge structure |
| Provenance | Preserve and extend evidence provenance chains |

### Mathematical Migration
Deterministic migration of mathematical framework.

| Domain | Transformation |
|--------|---------------|
| Formal proofs | Preserve all proofs; add new proofs from integration |
| Symbolic state | Migrate symbolic engine state |
| Mathematical objects | Add new objects; preserve existing |
| Cross-proof dependencies | Update dependency graph for new proofs |

### World Model Migration
Deterministic migration of world model state.

| Domain | Transformation |
|--------|---------------|
| Model state | Apply model updates from validated experiments |
| Simulation state | Migrate simulation configurations |
| Prediction models | Update prediction models |
| Coverage maps | Update world model coverage |

### Planning Migration
Deterministic migration of planning state.

| Domain | Transformation |
|--------|---------------|
| Active plans | Preserve and revalidate active plans |
| Planning schedules | Update schedules for new generation |
| Planning constraints | Apply new constraints |
| Plan dependencies | Update dependency graph |

### Runtime Migration
Deterministic migration of runtime infrastructure.

| Domain | Transformation |
|--------|---------------|
| Runtime configuration | Apply configuration changes |
| Service registration | Update service registry |
| Resource allocation | Apply resource allocation changes |
| Monitoring configuration | Update monitoring setup |

### Archaeology Migration
Deterministic migration of archaeological records.

| Domain | Transformation |
|--------|---------------|
| Generation archaeology | Create archaeology record for new generation |
| Lineage update | Add generation transition to lineage |
| Evidence chain | Extend evidence chain with transition artifacts |
| Root hashes | Compute new archaeology_root for target generation |

## Rollforward Determinism

- All transformations are pure functions: same source → same target
- Each transformation produces an intermediate state hash
- The complete rollforward produces a rollforward_hash
- Rollforward is fully replayable from cold storage

## Rollforward Verification

After rollforward, verify:

| Check | Description |
|-------|-------------|
| State hash match | Target state hash equals predicted value |
| Knowledge continuity | Knowledge graph consistent and continuous |
| Mathematical consistency | All proofs valid in target generation |
| Replay continuity | Replay chain connects source to target |
| Archaeology completeness | Both generations have complete archaeology |

## Rollback After Rollforward

Rollback is always possible after rollforward:

- Source generation remains frozen and available
- Rollback restores source generation state
- Knowledge, mathematics, and archaeology are restored to pre-transition state
- Rollback produces its own RollbackRecord and archaeology

## Constraints

- All transformations are deterministic and replayable
- No data is lost during rollforward (immutable source preserved)
- Rollforward produces verifiable intermediate hashes at every step
- Rollforward supports complete rollback to source generation
- All rollforward artifacts are immutable and content-addressed
