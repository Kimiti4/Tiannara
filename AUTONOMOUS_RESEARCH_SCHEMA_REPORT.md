# Phase 17.8.1 — Autonomous Research Schema Report

document_version: 17.8.1
phase: 17.8
status: Complete
owner: Constitutional Research Council
depends_on:
  - AUTONOMOUS_RESEARCH_RUNTIME_FREEZE.md (Phase 17.8.05)
  - RESEARCH_PROGRAM_DATA_MODEL.md (Phase 17.8.0 CAR)

---

## Scope

This document reports the results of Phase 17.8.1: Ontology implementation.

Phase 17.8.1 implements:
- All structs, validators, serialization, canonicalization, and content-addressed IDs
  defined in RESEARCH_PROGRAM_DATA_MODEL.md
- Fixes to pre-existing structs that carried constitutional violations
- A shared canonical serialization utility (single source of truth)

No runtime logic is implemented here. No behaviour implementations.
No hardcoded domain values. No mock data.

---

## Files Implemented

### New: Shared Canonical Utility

| File | Module |
|---|---|
| `tiannara_runtime/lib/tiannara_runtime/shared/canonical.ex` | `TiannaraRuntime.Shared.Canonical` |

**Purpose:** Single source of truth for canonical serialization, content-addressed ID
generation, and ID verification. Eliminates the `deep_struct_to_map/1` duplication that
existed in every pre-existing struct module.

**Functions:**
- `to_canonical_map/1` — deep struct-to-map with sorted string keys
- `encode!/1` — canonical JSON encoding (raises on non-encodable terms)
- `generate_id/3` — content-addressed ID: sha256(canonical_json(struct minus id_field))
- `verify_id/3` — verifies a recorded ID matches the current field values

---

### New Phase 17.8.1 Schemas

| File | Module | ID Prefix |
|---|---|---|
| `simulation_scenario_binding.ex` | `SimulationScenarioBinding` | `ssb_` |
| `program_replay_fingerprint.ex` | `ProgramReplayFingerprint` | `rf_` |
| `mathematical_verification_result.ex` | `MathematicalVerificationResult` | `mvr_` |

---

### Rebuilt (Constitutional Violations Fixed)

The following pre-existing structs were rebuilt to eliminate hardcoded defaults,
remove duplicated `deep_struct_to_map/1`, and migrate to `TiannaraRuntime.Shared.Canonical`:

| File | Module | Violations Fixed |
|---|---|---|
| `research_program.ex` | `ResearchProgram` | Hardcoded `priority: 0.5`, `status: :active`; restructured to Phase 16.1 schema alignment with Phase 17.8 extension fields |
| `experiment_budget.ex` | `ExperimentBudget` | Hardcoded `max_compute_units: 100`, `max_simulations: 10`, `max_wall_clock_ms: 3600000`, `priority_weight: 0.5`; replaced with required-field contract |
| `experiment_portfolio.ex` | `ExperimentPortfolio` | Hardcoded `diversity_score: 0.0`, `expected_information_gain: 0.0`; restructured to freeze-aligned schema |
| `experiment_schedule.ex` | `ExperimentSchedule` | Hardcoded `adaptive: true`; restructured with dispatch_intent validation |
| `research_evidence.ex` | `ResearchEvidence` | Hardcoded `confidence: 0.5`, `timestamp: 0`, invalid type list; restructured to Phase 16.1 schema with phase_17_8_ext |
| `research_outcome.ex` | `ResearchOutcome` | Hardcoded `supported: false`, `effect_size: 0.0`, `confidence: 0.0`; restructured to freeze-aligned schema |
| `research_campaign.ex` | `ResearchCampaign` | Missing schedule_id linkage; status :interrupted added; restructured |
| `program_metrics.ex` | `ProgramMetrics` | All counters defaulted to 0; restructured as required-field snapshots with tick reference |

---

## Schema Audit Results

### Schema Audit
PASS — All 11 modules (1 shared utility + 3 new + 7 rebuilt) have correct struct
shapes matching the frozen data model in RESEARCH_PROGRAM_DATA_MODEL.md.

### Serialization Audit
PASS — `TiannaraRuntime.Shared.Canonical.to_canonical_map/1` is the single
canonicalization path. All modules use it via `generate_id/3`. No module
has its own serialization logic.

### Hash Stability Audit
PASS — ID generation is deterministic: same field values → same canonical JSON
→ same SHA-256 hash → same content-addressed ID.

The ID field itself is excluded from the hash input, preventing circular
dependencies. Verified via `verify_id/3` contract in each module.

### Validator Audit
PASS — Every schema has a `validate/1` function. Every validator:
- checks for nil/empty on all required fields
- checks types and shapes
- produces a descriptive `{:error, "ModuleName: field_name reason"}` tuple
- never produces a partial valid struct (the `with :ok <- validate(...)` pattern
  prevents ID assignment on invalid data)
- contains no hardcoded domain thresholds or magic numbers

### No Hardcoded Values Audit
PASS — No `Keyword.get(opts, :key, hardcoded_default)` for any domain value.
The only defaults in `new/1` functions are for optional fields that are
explicitly nil by specification (e.g., `certificate_id`, `divergence_report_id`).

### No Mock Data Audit
PASS — No `random/0`, no `System.unique_integer/0`, no fabricated test values.
ID generation uses SHA-256 over real field content only.

### Duplication Audit
PASS — `deep_struct_to_map/1` no longer exists in individual modules.
Single canonical implementation at `TiannaraRuntime.Shared.Canonical.to_canonical_map/1`.

### Diagnostics Audit
PASS — Zero compiler diagnostics across all 12 files.

---

## ID Prefix Register

| Prefix | Module |
|---|---|
| `rp_` | ResearchProgram |
| `pf_` | ExperimentPortfolio |
| `bd_` | ExperimentBudget |
| `sc_` | ExperimentSchedule |
| `rc_` | ResearchCampaign |
| `re_` | ResearchEvidence |
| `rout_` | ResearchOutcome |
| `pm_` | ProgramMetrics |
| `ssb_` | SimulationScenarioBinding |
| `rf_` | ProgramReplayFingerprint |
| `mvr_` | MathematicalVerificationResult |

---

## Archaeology Compliance

Every schema satisfies Explain() at the struct level:
- `verify_id/1` allows any module to confirm an artifact's ID matches its content
- Provenance fields (experiment_id, program_id, portfolio_id, config_hash, etc.)
  are required on all dependent schemas
- No orphaned structs — every entity references its upstream artifacts by content-addressed ID

---

## Phase 17.8.1 Decision

**ONTOLOGY: COMPLETE**

Phase 17.8.2 (Knowledge Gap Prioritization) may now proceed.

---

## Dependency Chain

```
AUTONOMOUS_RESEARCH_RUNTIME_FREEZE (17.8.05)
    │
    ▼
AUTONOMOUS_RESEARCH_SCHEMA_REPORT (17.8.1 — this document)
    │
    ▼
KNOWLEDGE_GAP_PRIORITIZATION (17.8.2 — next)
```
