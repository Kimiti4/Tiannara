# Phase 17.8.2 — Knowledge Gap Prioritization

document_version: 17.8.2
phase: 17.8
status: Complete
owner: Constitutional Research Council
depends_on:
  - AUTONOMOUS_RESEARCH_SCHEMA_REPORT.md (Phase 17.8.1)
  - KNOWLEDGE_GAP_ENGINE.md (Phase 16.2 — extended, not replaced)
  - QUESTION_GENERATION.md (Phase 16.3 — informing scoring dimensions)
  - RESEARCH_EXECUTION_PIPELINE.md (Stage 2 — PRIORITIZATION)

---

## Scope

Phase 17.8.2 implements the ARPEPriorityScorer (Stage 2 of the ARPE pipeline).

It expands Phase 16 knowledge gaps — which may originate from the World Model,
Causal Graph, Prediction residuals, Counterfactual divergences, or Composition
inconsistencies — into ranked, executable priority records that feed the
ARPEProgramPlanner.

---

## Constitutional Constraints (All Enforced)

- All scoring weights come from a `ScoringConfig` artifact — never hardcoded.
- If `ScoringConfig` is absent or invalid, the prioritizer fails closed with a
  `ScoringConfigMissing` error artifact.
- All five score signal fields are required on every gap — no fallback values.
- If any required field is absent, the prioritizer fails closed with a
  `GapFieldMissing` error artifact for that specific gap.
- Tie-breaking is deterministic: ascending lexicographic over `knowledge_gap_id`.
- No wall-clock, no random, no network access at scoring time.

---

## Files Implemented

### New Structs

| File | Module | Purpose |
|---|---|---|
| `scoring_config.ex` | `ScoringConfig` | Epoch-frozen config artifact carrying all weights |
| `knowledge_gap_priority_record.ex` | `KnowledgeGapPriorityRecord` | Output artifact per gap, with full score breakdown |

### Rebuilt Engine

| File | Module | Violations Fixed |
|---|---|---|
| `engines/knowledge_gap_prioritizer.ex` | `Engines.KnowledgeGapPrioritizer` | Removed `@default_weights` module attribute with hardcoded values; removed all `Map.get(x, :key, 0.5)` fallback patterns; removed `Map.get(context, :weights, @default_weights)` fallback; fail-closed on missing config; all five score signals now required from gap fields |

---

## ScoringConfig (Epoch-Frozen Config Artifact)

All five weights are required at construction time.
Weights must sum to 1.0 (validated within floating-point tolerance).
The tolerance constant is named `@weight_sum_tolerance` in the module — not an inline literal.

Fields:
- `epoch_id` — links this config to a specific scoring epoch
- `schema_version` — tracks the scoring contract version
- `w_uncertainty` — weight for uncertainty reduction signal
- `w_impact` — weight for estimated impact signal
- `w_feasibility` — weight for feasibility signal
- `w_civilization_relevance` — weight for civilization relevance signal
- `w_information_gain` — weight for information gain signal
- `tie_break_field` — the field used for lexicographic tie-breaking
- `tie_break_direction` — `:asc` or `:desc`

Content-addressed ID: `scfg_<sha256>`.

---

## KnowledgeGapPriorityRecord (Output Artifact)

One record per gap, produced by the prioritizer. Contains:
- `knowledge_gap_id` — links back to the source gap
- `epoch_id` — the epoch this record belongs to
- `scoring_config_id` — the config that produced this score (archaeology)
- `composite_score` — the weighted sum
- `score_components` — full breakdown (uncertainty, impact, feasibility,
  civilization_relevance, information_gain)
- `rank` — ordinal rank within this epoch's priority list (0-indexed)
- `twin_provenance_hash` — the World Model snapshot hash that produced the gap

Content-addressed ID: `kgpr_<sha256>`.

---

## Scoring Function

```
score(gap) =
  config.w_uncertainty           × uncertainty(gap)
  + config.w_impact              × impact(gap)
  + config.w_feasibility         × feasibility(gap)
  + config.w_civilization_relevance × civilization_relevance(gap)
  + config.w_information_gain    × information_gain(gap)
```

All weights come from ScoringConfig. All signals come from the gap's own fields.

### Signal Derivations

| Signal | Source Fields | Formula |
|---|---|---|
| uncertainty | `current_confidence`, `target_confidence` | `max(0.0, min(1.0, target - current))` |
| impact | `estimated_impact` | Direct field value (required: float in [0.0, 1.0]) |
| feasibility | `feasibility` | Direct field value (required: float in [0.0, 1.0]) |
| civilization_relevance | `civilization_relevance` | Direct field value (required: float in [0.0, 1.0]) |
| information_gain | `information_gain` | Direct field value (required: float in [0.0, 1.0]) |

All five fields are required on every KnowledgeGap passed to the prioritizer.
Absence of any field produces a `GapFieldMissing` failure artifact.

---

## Failure Semantics

| Failure | Typed Error Struct | Condition |
|---|---|---|
| Config absent | `ScoringConfigMissing` | `scoring_config` is nil or not a `ScoringConfig` struct |
| Config ID invalid | `ScoringConfigMissing` | `ScoringConfig.verify_id/1` fails |
| Gap field missing | `GapFieldMissing` | Any of the five signal fields is absent or wrong type |
| Provenance absent | `GapProvenanceMissing` | `phase_17_8_ext.twin_provenance_hash` is absent |

All failures halt the scoring pipeline via `Enum.reduce_while/3`.
No partial results are returned when any gap fails.

---

## Determinism Guarantee

Given identical inputs:
- same gaps (same field values)
- same ScoringConfig (same config_id, same weights)
- same epoch_id

The output list is identical:
- same composite scores (IEEE 754 deterministic arithmetic)
- same sort order (score desc, gap_id asc for ties)
- same ranks
- same KnowledgeGapPriorityRecord IDs (content-addressed)

This satisfies the LEVEL1 and LEVEL3 replay requirements for Stage 2.

---

## Archaeology Support

Every `KnowledgeGapPriorityRecord` carries:
- `scoring_config_id` → explains which weights were used
- `score_components` → explains the breakdown behind each rank decision
- `twin_provenance_hash` → traces back to the World Model snapshot

An independent auditor can reconstruct the entire priority list from:
- the gap artifacts (immutable)
- the ScoringConfig artifact (immutable, content-addressed)
- the prioritizer algorithm version (frozen in epoch config)

---

## Phase 17.8.2 Decision

**KNOWLEDGE GAP PRIORITIZATION: COMPLETE**

Phase 17.8.3 (Autonomous Experiment Planning) may now proceed.

---

## Dependency Chain

```
AUTONOMOUS_RESEARCH_SCHEMA_REPORT (17.8.1)
    │
    ▼
KNOWLEDGE_GAP_PRIORITIZATION (17.8.2 — this document)
    │
    ▼
AUTONOMOUS_EXPERIMENT_PLANNER (17.8.3 — next)
```
