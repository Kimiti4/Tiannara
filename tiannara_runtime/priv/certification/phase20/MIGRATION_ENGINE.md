# Phase 20.4 — Migration Engine

## Role

The Migration Engine executes deterministic state transforms that transition the runtime from its current version to the target version defined by the integration candidate. Every migration is version-aware, fully replayable, and reversible.

## Responsibilities

### 1. Version-Aware Migration

The Migration Engine maintains awareness of:

- Current runtime version (source_version)
- Target runtime version (target_version)
- All intermediate versions between source and target
- Migration history (all previous migrations with hashes)
- State schema version for each state domain

Migrations are applied as ordered sequences of version transitions. Each transition moves from version N to version N+1. Skipping versions is prohibited.

### 2. Immutable Migration Plans

Every migration is guided by an immutable MigrationPlan:

- Generated deterministically from candidate specification and current runtime state
- Contains ordered migration steps
- Each step specifies a deterministic state transform
- Each step specifies its inverse (for rollback)
- Each step specifies verification criteria
- The plan is content-addressed and cannot be modified after generation

### 3. Deterministic State Transforms

Each state transform is a pure function:
`transform(current_state, step_parameters) → new_state + evidence`

Properties:
- Same inputs always produce same outputs
- No side effects outside the transform
- No dependency on system time, random values, or external state
- Produces audit evidence for each transform
- Each transform produces a step hash for replay chain

### 4. Migration Replay

The Migration Engine supports full replay of any migration:

- Replay reproduces identical intermediate state hashes at every step
- Replay reproduces identical final state hash
- Replay from cold storage (no runtime state) produces identical results
- Replay is verified against the migration_replay_root stored in MigrationResult

### 5. Migration Archaeology

Every migration produces:

- MigrationPlan (immutable, content-addressed)
- Intermediate state snapshots (one per migration step)
- Per-step transform evidence
- MigrationResult with intermediate and final state hashes
- Migration replay chain
- Migration archaeology root

All archaeology is reconstructable from cold storage.

### 6. Rollback Generation

For every migration, the Migration Engine generates rollback capability:

- Inverse transforms for each migration step
- Complete state restoration plan
- Knowledge graph restoration plan
- Mathematical graph restoration plan
- Scientific capital restoration plan
- Replay chain re-verification after restoration

Rollback is tested during migration simulation (Stage 5) before deployment.

## State Domains

The Migration Engine manages transforms across all runtime state domains:

| Domain | Description |
|--------|-------------|
| Module state | Runtime module instances and their internal state |
| Knowledge graph | Knowledge graph nodes, edges, and metadata |
| Mathematical graph | Mathematical objects, proofs, and dependencies |
| Scientific capital | Scientific capital records and balances |
| Working memory | Reasoning and planning state |
| Metacognition state | Meta-cognitive oversight state |
| Governance state | Constitutional governance state |
| Civilization state | Civilization-scale state (Phase 19) |
| Registry state | All registry contents |

Each domain has versioned schemas and supports independent migration.

## Migration Fingerprint

The complete migration produces a deterministic fingerprint:

`migration_fingerprint = SHA-256(canonical_form(MigrationPlan) || final_state_hash || migration_replay_root)`

This fingerprint is used for:
- Verification against predicted value
- Audit trail anchoring
- Archaeology chain linking
- Rollback target identification

## Constraints

- Migration must be fully deterministic
- Migration must be fully replayable from cold storage
- Migration must produce identical state hashes every time
- Migration must support full rollback to any intermediate state
- Migration must not lose any archaeological data
- Migration must not modify historical replay chains
- Migration step order is fixed by the MigrationPlan and cannot be reordered
