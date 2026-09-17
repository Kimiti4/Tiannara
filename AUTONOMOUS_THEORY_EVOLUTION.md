# Autonomous Theory Evolution (Phase 17.8.6 Specification)

## Mission
Develop Tiannara's Constitutional Theory Evolution engine to automatically strengthen, weaken, reject, merge, split, and audit scientific theories based on newly collected evidence within the digital twin simulation, keeping all operations deterministic, config-driven, and archaeologically traceable.

---

## 1. Architectural Integrity & Ownership
The theory evolution subsystem is governed by **Phase 17.8.6**.

- **Canonical Owner**: `TiannaraRuntime.WorldModel.AutonomousResearch.Engines.TheoryUpdater`
- **Replayability**: State updates can be fully replayed and reconstructed from the immutable `TheoryEvolutionRecord` logs and corresponding `TheoryEvolutionConfig` blocks. No non-deterministic values (such as system clock calls) are permitted; all timestamps are explicitly passed as inputs from the execution context.
- **Explainability**: Every change to a theory's confidence or status traces directly to a content-addressed `ResearchEvidence` record via a `TheoryEvolutionRecord`.

---

## 2. Mathematical Formulations

All mathematical operations inside `TheoryUpdater` are configuration-driven.

### A. Evidence Strength
Evidence strength represents the statistical power and quality of a given piece of evidence. It is a weighted sum of three factors:

$$\text{Evidence Strength} = (C \cdot w_{\text{confidence}}) + (S \cdot w_{\text{size}}) + (E \cdot w_{\text{effect}})$$

Where:
- $C$ is the evidence's internal confidence value (between 0.0 and 1.0).
- $S$ is the normalized sample size factor:
  $$S = \min\left(\frac{\ln(\text{sample\_size} + 1)}{\ln(\text{normalization\_base})}, 1.0\right)$$
- $E$ is the normalized effect size factor:
  $$E = \min(\text{effect\_size} \cdot 2.0, 1.0)$$
- $w_{\text{confidence}}, w_{\text{size}}, w_{\text{effect}}$ are weights defined in `TheoryEvolutionConfig` and must sum to exactly 1.0.

### B. Theory Updating

#### 1. Strengthening
If support is high and evidence strength is high:

$$\text{Confidence}_{\text{new}} = \min(\text{Confidence}_{\text{current}} + \text{Evidence Strength} \cdot \text{Support} \cdot \text{boost\_factor}, 1.0)$$

#### 2. Weakening
If a contradiction is detected or support is low:

$$\text{Confidence}_{\text{new}} = \max(\text{Confidence}_{\text{current}} - \text{Evidence Strength} \cdot (1.0 - \text{Support}) \cdot \text{penalty\_factor}, 0.0)$$

#### 3. Rejection
A theory is rejected if its confidence drops below a given threshold:

$$\text{Confidence} < \text{rejection\_confidence\_threshold}$$
$$\text{or } (\text{Contradiction Score} > \text{rejection\_contradiction\_score\_threshold} \text{ and } \text{Confidence} < \text{rejection\_contradiction\_confidence\_threshold})$$

---

## 3. Data Schema Definitions

### A. `TheoryEvolutionConfig` (`tecfg_<sha256>`)
| Field | Type | Description |
|---|---|---|
| `config_id` | `String` | SHA-256 hash over canonical fields, prefixed with `tecfg` |
| `epoch_id` | `String` | The governing scientific epoch |
| `schema_version` | `String` | Semantic version of the config |
| `support_threshold` | `Float` | Support ratio threshold for strengthening |
| `strength_threshold` | `Float` | Evidence strength threshold for updating |
| `reject_support_threshold`| `Float` | Support ratio threshold for rejection checking |
| `boost_factor` | `Float` | Multiplier for confidence strengthening |
| `penalty_factor` | `Float` | Multiplier for confidence weakening |
| `rejection_confidence_threshold` | `Float` | Absolute low confidence limit before rejection |
| `rejection_contradiction_score_threshold` | `Float` | Limit for contradiction score beyond recovery |
| `rejection_contradiction_confidence_threshold` | `Float`| Confidence limit when checking contradiction score |
| `contradiction_difference_limit` | `Float` | Minimum delta to declare prediction contradiction |
| `support_match_difference_limit` | `Float` | Maximum delta to count as a matching prediction |
| `min_sample_size` | `Integer` | Min sample size for strength calculations |
| `sample_size_normalization_base` | `Float` | Denominator base for sample size log normalization |
| `w_confidence` | `Float` | Strength weight for evidence confidence |
| `w_size` | `Float` | Strength weight for sample size |
| `w_effect` | `Float` | Strength weight for effect size |

### B. `TheoryEvolutionRecord` (`terc_<sha256>`)
| Field | Type | Description |
|---|---|---|
| `record_id` | `String` | Content-addressed SHA-256 ID, prefixed with `terc` |
| `config_id` | `String` | Target `TheoryEvolutionConfig` ID |
| `theory_id` | `String` | Associated Theory ID |
| `evidence_id` | `String` | Associated Evidence ID |
| `pre_confidence` | `Float` | Confidence level prior to the update |
| `post_confidence`| `Float` | Confidence level after the update |
| `action` | `Atom` | `:strengthened`, `:weakened`, `:rejected`, `:unaffected` |
| `rejection_reason` | `String` | Populated if action is `:rejected` |
| `evidence_support` | `Float` | Calculated support level of the evidence |
| `evidence_strength`| `Float` | Calculated strength level of the evidence |
| `contradiction_detected` | `Boolean` | True if predictions directly contradicted evidence values |
| `timestamp` | `String` | ISO8601 UTC timestamp provided by the context |

---

## 4. Replay & Archaeology Constraints

- **Single Source of Truth**: All updates are calculated from the inputs. No hidden state remains.
- **Full Traceability**: A split or merged theory lists its direct ancestors in `:parent_theories` or `:parent_theory_id`.
- **Fail-Closed Operations**: If config ID verification fails, the engine blocks the update and returns an error immediately.

---

## 5. Success Criteria
1. No hardcoded constants exist inside the theory evolution engine.
2. No stubbed theory operations exist; strengthen, weaken, reject, merge, split, and contradiction handling must execute through real code paths.
3. No mock evidence may be accepted as theory-update evidence outside isolated test fixtures.
4. The engine executes deterministically under exact input replay.
5. Compilation reports zero warnings or errors.
6. Independent verification shows mathematical alignment with defined thresholds.

## 6. Phase 17.8+ Proof Discipline

Theory evolution is not complete because expected actions are described. It is complete
only when real `ResearchEvidence`, `TheoryEvolutionConfig`, and immutable
`TheoryEvolutionRecord` artifacts can replay the same theory history without importing
runtime internals.

If required evidence, config, or prior theory state is missing or unverifiable,
`TheoryUpdater` must fail closed. It must not infer substitute values, fabricate evidence,
or use mock data to advance a theory.

This proof discipline carries forward into Phase 18 CCOS. Cognitive orchestration may
consume theory-evolution artifacts only when those artifacts are content-addressed,
replayable, and independently auditable. It must not promote a theory update, memory,
plan, decision, or archive entry that depends on hardcoded defaults, stubbed success
paths, mock evidence, or hidden runtime state.
