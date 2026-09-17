# Runtime Handbook — CSOS v1.0

## Purpose

Comprehensive guide to the runtime architecture of the Constitutional Scientific Operating System. Covers generation management, versioning, branching, migration, lineage, replay, and the cognitive/civilizational runtimes.

## Runtime Layers

### Cognitive Runtime (Phase 18)
Location: `lib/tiannara_runtime/cognitive/`
- 69 structs, 63 engines, 17 behaviours
- Subsystems: perception, reasoning, meta-cognition, metacognitive, memory, attention, learning
- 257 tests

### Civilizational Runtime (Phase 19)
Location: `lib/tiannara_runtime/civilization/`
- 61 modules across 8 subdirectories
- Subsystems: ontology, registry, runtime, economy, portfolio, coordination, planning, scenarios
- 65 tests

### Constitutional Runtime (Phase 20, architecture-only)
Location: `priv/certification/phase20/`
- Generation management, versioning, branching, migration, lineage, replay, archaeology
- Runtime evolution engine, rollback engine, rollforward engine

## Generation Lifecycle

```
Blueprint → Candidate → Validated → IntegrationReady → 
Sandbox → Canary → ProductionCandidate → Current → Historical
```

Each transition is deterministic and replayable.

## Generation Management

- Each generation is content-addressed by its generation hash
- Generations form a lineage tree (parent → child relationships)
- The current generation is the active constitutional state
- Historical generations are preserved in archaeology

## Versioning (Phase 20.5)

- Semantic versioning for generations
- Branching for parallel evolution tracks
- Migration between generations with full rollback
- Freeze points for permanent snapshots

## Replay

- Every runtime operation produces a replay record
- Replay chain from Genesis through current generation
- Full OS replay from cold storage only
- Identical hashes required for certification

## Runtime Evolution

- Runtime evolution engine manages generation transitions
- Rollback engine restores previous generation state
- Rollforward engine executes forward migration
- All transitions are deterministic and replayable
