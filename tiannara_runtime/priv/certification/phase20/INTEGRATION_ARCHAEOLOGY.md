# Phase 20.4 — Integration Archaeology

## Role

Integration Archaeology records complete, immutable lineage for every integration attempt — successful or failed. Every integration answers the Seven Archaeological Questions, preserving full context for future reconstruction and audit.

## The Seven Archaeological Questions (Integration)

Every integration must answer:

1. **Why was this integration performed?** — The bottleneck, opportunity, or requirement that motivated the integration. Reference to the originating EvolutionOpportunity (Phase 20.3) and candidate certification.

2. **Who approved it?** — The certifying authority, auditor identity, and constitutional authority that authorized the integration. All approval references include decision artifacts.

3. **Which experiments justified it?** — Complete references to the constitutional experiments (Phase 20.3 Evolution Sandbox) that produced the evidence supporting this integration. Each experiment reference includes its evidence_root, replay_root, and certification artifacts.

4. **Which benchmarks were passed?** — Complete benchmark results from candidate evaluation, integration simulation, and activation verification. All benchmark artifacts are content-addressed and replayable.

5. **Which systems were replaced or deprecated?** — The previous runtime generation, modules superseded by this integration, and any subsystems retired or deprecated as a result. Includes before/after state hashes for each affected system.

6. **Which dependencies changed?** — Complete dependency graph diff: added dependencies, removed dependencies, updated dependency versions, and any dependency graph restructuring. Includes topological ordering artifacts.

7. **Which migrations occurred and which rollbacks exist?** — Complete migration history including all intermediate state hashes, migration steps, and any rollback events. Rollback artifacts include trigger evidence and restored state verification.

## Integration Archaeology Record

Each integration produces an archaeology record containing:

### Identity
- integration_id: Content-addressed identifier
- candidate_id: Reference to originating IntegrationCandidate
- generation: RuntimeGeneration associated with this integration

### Temporal
- intake_timestamp: Deterministic timestamp of Stage 1 intake
- activation_timestamp: Deterministic timestamp of Stage 10 activation
- freeze_timestamp: Deterministic timestamp of Stage 12 freeze

### Lineage
- previous_generation: RuntimeGeneration before integration
- current_generation: RuntimeGeneration after integration
- parent_reference: Link to parent generation archaeology
- child_references: Links to successor generations

### Decision Log
- All approval records with certifying authorities
- All audit records with findings and resolutions
- All promotion decisions with evidence
- All rollback decisions with trigger evidence

### Evidence Chain
- Full evidence chain from candidate certification through freeze
- All benchmark results, simulation reports, and verification artifacts
- All audit artifacts and certifications

### Migration History
- MigrationPlan with all steps
- MigrationResult with intermediate and final state hashes
- Per-step transform evidence
- Rollback records (if any)

## Archaeology Registry

| Function | Description |
|----------|-------------|
| register | Register an integration's archaeological record |
| explain | Given an integration_id, return answers to all 7 archaeology questions |
| lineage | Return complete integration lineage (ancestors and descendants) |
| integration_history | Return all integrations for a given subsystem |
| rollback_history | Return all rollbacks for a given integration |

## Lineage Traversal

Integration lineage forms a directed acyclic graph rooted at generation 0:

```
Generation N (pre-integration)
    │
    ▼
Integration X (candidate A)
    │
    ▼
Generation N+1 (post-integration X)
    │
    ├──→ Integration Y (candidate B) [success]
    │         │
    │         ▼
    │    Generation N+2
    │
    └──→ Integration Z (candidate C) [rollback]
              │
              ▼
         Generation N+1 (restored)
```

Each node stores integration_id, candidate_id, before/after generation numbers, migration_replay_root, archaeology_root, rollback references.

## Cold Storage Reconstruction

From cold storage alone:

1. Read integration replay chain from migration_replay_root
2. Reconstruct each integration step in order
3. For each step, derive answers to the 7 archaeological questions from replay + evidence data
4. Compute archaeology_root = SHA-256(answers)
5. Verify archaeology_root matches stored value
6. Reconstruct complete integration lineage

## Constraints

- No integration record is ever deleted
- Failed and rolled-back integrations are fully preserved
- Archaeology is reconstructable from cold storage (no runtime state required)
- Archaeology is deterministic (same evidence + replay → same answers)
- Archaeology supports cryptographic verification of all records
