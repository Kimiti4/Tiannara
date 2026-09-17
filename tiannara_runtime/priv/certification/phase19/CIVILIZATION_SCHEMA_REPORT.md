# Phase 19 — Civilization Schema Report

## Summary

Phase 19 defines 10 struct schemas across 6 modules. All schemas are frozen.

## Schema Inventory

| # | Struct | Module | Field Count | ID Prefix | Validation Rules | Frozen |
|---|--------|--------|-------------|-----------|------------------|--------|
| S1 | Civilization | civilizational_controller | 6 | CIV | id unique, status transitions, min 1 institution | ✓ |
| S2 | Institution | institution_manager | 7 | INST | id unique, type immutable, capital ≥ 0, no revival from Dissolved | ✓ |
| S3 | ResearchProgram | research_program | 11 | PROG | score sum ≤ 1.0, no circular deps, lifecycle order | ✓ |
| S4 | ResearchPortfolio | portfolio_governor | 4 | PORT | allocation sum ≤ total capital, append-only log, version +1 | ✓ |
| S5 | Collaboration | collaboration_engine | 5 | COLLAB | min 2 programs, no duplicate edges, deterministic hash | ✓ |
| S6 | ScientificEconomy | scientific_economy | 4 | ECON | total = sum ledger, monotonic version, certified reward refs | ✓ |
| S7 | CivilizationEvidence | evidence_store | 5 | EVID | globally unique id, valid producer hash | ✓ |
| S8 | CivilizationReplay | civilization_replay | 4 | REPLAY | final hash = hash(replay_log, root), all subsystems present | ✓ |
| S9 | CivilizationArchaeology | civilization_archaeology | 5 | ARCH | unique per civ_id, confidence ∈ [0,1], verifiable provenance | ✓ |
| S10 | CivilizationMetrics | civilizational_controller | 8 | METRICS | non-negative counts, aggregate scores ∈ [0,1] | ✓ |

## Module Paths

| Module | Path |
|--------|------|
| civilizational_controller | tiannara_runtime.lib.civilization.controller |
| institution_manager | tiannara_runtime.lib.civilization.institution |
| research_program | tiannara_runtime.lib.civilization.program |
| portfolio_governor | tiannara_runtime.lib.civilization.portfolio |
| collaboration_engine | tiannara_runtime.lib.civilization.collaboration |
| scientific_economy | tiannara_runtime.lib.civilization.economy |
| evidence_store | tiannara_runtime.lib.civilization.evidence |
| civilization_replay | tiannara_runtime.lib.civilization.replay |
| civilization_archaeology | tiannara_runtime.lib.civilization.archeology |

## ID Prefix Summary

| Prefix | Used By |
|--------|---------|
| CIV | Civilization |
| INST | Institution |
| PROG | ResearchProgram |
| PORT | ResearchPortfolio |
| COLLAB | Collaboration |
| ECON | ScientificEconomy |
| EVID | CivilizationEvidence |
| REPLAY | CivilizationReplay |
| ARCH | CivilizationArchaeology |
| METRICS | CivilizationMetrics |

## Field Count Distribution

- Minimum: 4 (ResearchPortfolio, ScientificEconomy, CivilizationReplay, CivilizationArchaeology)
- Maximum: 11 (ResearchProgram)
- Mean: 5.8
- Total fields: 58

## Frozen Status

All 10 structs are frozen as of Phase 19. Any modification requires a formal Phase 20 process.
