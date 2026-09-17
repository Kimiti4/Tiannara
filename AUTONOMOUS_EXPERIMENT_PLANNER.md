# Phase 17.8.3 — Autonomous Experiment Planner

document_version: 17.8.3
phase: 17.8
status: Complete
owner: Constitutional Research Council
depends_on:
  - KNOWLEDGE_GAP_PRIORITIZATION.md (Phase 17.8.2)
  - AUTONOMOUS_RESEARCH_RUNTIME_FREEZE.md (APIs: ARPEExperimentPlanner)
  - RESEARCH_EXECUTION_PIPELINE.md (Stages 3–4: PROGRAM_PLANNING, EXPERIMENT_DESIGN)

---

## Scope

Phase 17.8.3 implements the ARPEExperimentPlanner (Stages 3–4 of the ARPE pipeline).

It generates complete `ExperimentDesignRecord` artifacts from a `ResearchProgram`
and a `KnowledgeGapPriorityRecord`. Each design record is a constitutional artifact:
deterministic, content-addressed, replayable, and archaeologically explainable.

---

## Constitutional Constraints (All Enforced)

- All design parameters come from the `ResearchProgram` and `ExperimentDesignConfig`
  artifacts — never hardcoded.
- If `ExperimentDesignConfig` is absent, `design/4` returns `{:error, %DesignConfigMissing{}}`.
- `gap_type` must be supplied explicitly from the originating `KnowledgeGap` artifact —
  it is not inferred or defaulted.
- Empty `evidence_observable_mappings` → `{:error, %EvidenceMappingEmpty{}}` — an
  experiment that produces no evidence is constitutionally invalid.
- The `deterministic_seed` is SHA-256 over `program_id | knowledge_gap_id | epoch_id`.
  No `random`, no `DateTime.utc_now()`, no `System.unique_integer()`.
- `total_ticks` is derived from `resource_constraints.max_experiments` — not hardcoded.
- Validation types are resolved from `ExperimentDesignConfig.required_validation_types_by_gap_type`
  — not hardcoded per gap type in the engine.

---

## Files Implemented

### New Structs

| File | Module | Purpose |
|---|---|---|
| `experiment_design_config.ex` | `ExperimentDesignConfig` | Epoch-frozen config: validation type map, min observables, stopping types, seed strategy |
| `experiment_design_record.ex` | `ExperimentDesignRecord` | Complete experiment design artifact with all fields required |

### Rebuilt Engine

| File | Module | Violations Fixed |
|---|---|---|
| `engines/experiment_planner.ex` | `Engines.ExperimentPlanner` | Removed all hardcoded defaults (`effect_size: 0.3`, `sample_size: 100`, `significance_level: 0.05`, `max_trials: 100`, budget values); removed `extract_variables_from_text` heuristic (string splitting to infer variables is not constitutional — variables must come from the gap's measurement definitions); removed fabricated `predicted_outcome` generation; removed non-deterministic `DateTime.utc_now()` in IDs; seed is now deterministic SHA-256 |

---

## ExperimentDesignConfig (Epoch-Frozen Config Artifact)

Carries all design-time constraints:
- `required_validation_types_by_gap_type` — map from gap_type atom to required
  validation type atoms; fully populated per epoch
- `min_evidence_observables` — minimum observable mappings (positive integer)
- `required_stopping_condition_types` — which stopping condition types are required
- `seed_derivation_strategy` — label identifying the seed algorithm (frozen string)

Content-addressed ID: `edcfg_<sha256>`.

Validated constraints:
- All gap_type keys must be known gap types
- All validation type values must be known validation types
- `min_evidence_observables` must be a positive integer

---

## ExperimentDesignRecord (Output Artifact)

Complete experiment design per gap. Fields:
- Full lineage references: `program_id`, `knowledge_gap_id`, `priority_record_id`, `epoch_id`, `design_config_id`
- Measurement definitions derived from `evidence_requirements`
- Sampling plan with deterministic seed reference
- Robustness design: which assumptions to stress
- Evidence-to-measurement mapping (Twin output → evidence field)
- Required validation types (from config, keyed by gap_type)
- Stopping criteria (from program's `stopping_criteria` list)
- Scenario binding: `variable_mappings`, `evidence_observable_mappings`, `stopping_condition_mappings`
- `deterministic_seed` — SHA-256 hash, not random
- `total_ticks` — derived from `resource_constraints.max_experiments`

Content-addressed ID: `edr_<sha256>`.

Constraints enforced at construction:
- `evidence_observable_mappings` must be non-empty
- `stopping_criteria` must be non-empty
- All `required_validation_types` must be known types

---

## Determinism Guarantee

Given identical inputs:
- same `ResearchProgram` (same field values, same `config_hash`)
- same `KnowledgeGapPriorityRecord` (same `priority_record_id`)
- same `ExperimentDesignConfig` (same `config_id`)
- same `gap_type`

The output `ExperimentDesignRecord` is identical:
- same `deterministic_seed` (SHA-256 is deterministic)
- same `design_record_id` (content-addressed)
- same measurement definitions (derived from `evidence_requirements`)
- same total_ticks (derived from `resource_constraints`)

This satisfies LEVEL1 and LEVEL3 replay requirements for Stages 3–4.

---

## Failure Taxonomy

| Failure | Struct | Condition |
|---|---|---|
| Config absent | `DesignConfigMissing` | `design_config` nil or not `ExperimentDesignConfig` |
| Config ID invalid | `DesignConfigMissing` | `ExperimentDesignConfig.verify_id/1` fails |
| Unknown gap_type in config | `DesignConfigMissing` | Config has no validation types for the supplied gap_type |
| Required program field absent | `ProgramFieldMissing` | Any of: `program_id`, `schema_version`, `statistical_requirements`, `stopping_criteria`, `evidence_requirements`, `resource_constraints` |
| Empty evidence mappings | `EvidenceMappingEmpty` | `evidence_requirements` produce no observable mappings |
| Gap type not supplied | `GapTypeMissing` | 3-arity `design/3` called (gap_type must be supplied explicitly via 4-arity form) |

---

## Archaeology Support

Every `ExperimentDesignRecord` carries:
- `priority_record_id` → traces to the scoring decision
- `design_config_id` → traces to the config that determined validation types
- `deterministic_seed` → derived from program + gap + epoch IDs (reproducible by any auditor)
- `measurement_definitions` → derived from `evidence_requirements` (traces to gap artifact)

An independent auditor can reconstruct the full design from immutable artifacts.

---

## Phase 17.8.3 Decision

**AUTONOMOUS EXPERIMENT PLANNING: COMPLETE**

Phase 17.8.4 (Portfolio Optimization) may now proceed.

---

## Dependency Chain

```
KNOWLEDGE_GAP_PRIORITIZATION (17.8.2)
    │
    ▼
AUTONOMOUS_EXPERIMENT_PLANNER (17.8.3 — this document)
    │
    ▼
RESEARCH_PORTFOLIO_OPTIMIZATION (17.8.4 — next)
```
