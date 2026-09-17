# EFDI D5 — Architecture Reconnaissance

**Gate:** EFDI-D5 (Phase 1 — reconnaissance only) · **Date:** 2026-09-02
**Evidence basis:** LIVE repository scan (git rev reachable, `lib/tiannara/**` scanned).

> **Correction to prior D5 reconnaissance draft:** an earlier package claimed the
> repository was "not reachable from this session" and marked every inventory row
> `UNKNOWN / REPO_SCAN_PENDING`. That premise was **false** — the repo is live and was
> scanned for this package. All rows below are resolved from **actual code**, not assumed.

---

## 1. Certified campaign state (input)

```text
D1  Signal Intelligence                    CERTIFIED_BOUNDED   92 tests
D2  Forecast + Calibration                 CERTIFIED_BOUNDED  104 tests
D3  Decision Intelligence                  CERTIFIED_BOUNDED   73 tests   V1–V19
D4  Counterfactual / Alternative Histories CERTIFIED_BOUNDED   31 tests   V20–V35
CUMULATIVE                                                  300 / 300
```

D4 precedent to honor: **adapter/boundary over canonical substrate, no duplicated engine.**

---

## 2. Live architecture inventory

### 2.1 Statistical & probabilistic substrate (verified present)

| Module | Capability | Path |
|--------|-----------|------|
| `Tiannara.Math.Statistics` | `mean/1`, `variance/1`, `standard_deviation/1` (population var) | `lib/tiannara/math/statistics.ex` |
| `Tiannara.Math.Probability` | `bayes_update/3` (P(H\|E)), `shannon_entropy/1` | `lib/tiannara/math/probability.ex` |
| `Tiannara.Foundations.InformationTheory` | `shannon_entropy/1`, `kl_divergence/2` | `lib/tiannara/foundations/information_theory.ex` |
| `Tiannara.Numerics` | `mean/1`, `variance/1` (sample, n-1, `:insufficient_samples`), `cohens_d/2`, `round/2` | `lib/tiannara/numerics.ex` |
| `Tiannara.Forecasting.Calibration` | `variance/1`, reliability, entropy (D2) | `lib/tiannara/forecasting/calibration.ex` |
| `Tiannara.REA.Causal.Channel` | variance (disagreement-in-population) | `lib/tiannara/rea/causal/channel.ex` |

### 2.2 Disagreement / consensus / minority-preservation substrate (verified present)

| Module | Capability | Path |
|--------|-----------|------|
| `TiannaraOS.DistributedValidationResult` | `:disagreement_map` preserving per-institution **position + evidence_summary**; `has_minority_position?/1`; `:contested` state | `lib/tiannara/os/distributed_validation_result.ex` |
| `TiannaraOS.OCM` + `voting_system.ex` + `consensus_manager.ex` | weighted voting, consensus building (governance, not epistemic-analysis) | `lib/tiannara/stabilization/ocm/` |

### 2.3 Sensitivity / variance in existing analysis paths (verified present, but local/piecemeal)

| Module | Capability | Path |
|--------|-----------|------|
| `Tiannara.Forecasting.ValueOfInformation` | `decision_sensitivity/1`, gap thresholds (0.1/0.2/0.5 hard-coded) | `lib/tiannara/forecasting/value_of_information.ex` |
| `Tiannara.Simulation.MultiWorld.ConstraintRelaxer` | `analyze_sensitivity/1` over relaxations | `lib/tiannara/simulation/multiworld/constraint_relaxer.ex` |
| `Tiannara.Simulation.MultiWorld.WorldComparisonAnalyzer` | `compute_variance/1`, narrative "sensitivity to injected changes" | `lib/tiannara/simulation/multiworld/world_comparison_analyzer.ex` |
| `Tiannara.CEL.Services.DecisionPredictor` | `compute_variance/1` | `lib/tiannara/cel/services/decision_predictor.ex` |
| `TiannaraOS.StatisticalValidation` | parameter-scenario sensitivity runs (OS simulation context) | `lib/tiannara/os/statistical_validation.ex` |
| `Tiannara.CEL.Services.ExecutiveDigitalTwin` | `apply_perturbation/2` per-scenario (sandbox) | `lib/tiannara/cel/services/executive_digital_twin.ex` |

### 2.4 D5-anticipated surfaces (verified present)

- `Tiannara.Forecasting.Contracts` moduledoc explicitly lists **D5 = "identical problem
  through multiple paths → disagreement"** and surfaces the constitutional rule
  **"model disagreement ≠ evidence contradiction"**.
- `Forecast` contract already carries a **`:disagreement`** field (empty/`nil` by default)
  — D2 forecast struct anticipates D5 output without yet populating it.
- D4 `TemporalFirewall` pattern (`firewall_intact?`, `:hindsight_contamination`,
  `:d3_write_attempt`) is the reusable certification-property template.
- EventStore (`Tiannara.Executive.EventStore`) + `Tiannara.Evidence.{Provenance,
  CertificationGate, HistoricalQuarantine}` for lineage and evidence-admissibility.

### 2.5 Confirmed ABSENT (genuinely NEW surface)

| Capability | Search result |
|-----------|---------------|
| Ensemble reasoning / model comparison | **absent** (no `ensemble`) |
| Monte Carlo / stochastic simulation / MCMC / SimulatedAnnealing | **absent** |
| Perturbation *analysis framework* (spec + budget + rationale + invariance) | **absent** (only ad-hoc `random_perturbation` / sandbox perturb) |
| Repeated-judgment / repeated-evaluation execution machinery | **absent** |
| D5 disagreement *metrics* (per-evaluator, dispersion, flip-rate) | **absent** (KL/entropy exist; no record aggregation) |
| Robustness / noise classification (contract-defined thresholds) | **absent** |
| Regime tagging + cross-regime mismatch guard | **absent** |
| POST_OUTCOME_ANALYSIS labeling | **absent** (D4 firewall exists; D5 temporal extension does not) |
| Bounded-computation budget enforcement (MAX_*) | **absent** |

---

## 3. Reuse map (integration composition)

D5 is an **epistemic analysis layer** composing the substrate, all read-only on the
source side:

```text
D2 Forecast          ──read──▶ D5 Forecast Robustness      ──derived──▶ D2 Calibration context
D3 Decision          ──read──▶ D5 Decision Robustness      ──derived──▶ D3 Decision Review
D4 Counterfactual    ──read──▶ D5 Counterfactual Sensitivity ──derived▶ D4 Interpretation
```

Decisive reuse findings from the live scan:

1. **Statistics are already here — do not rebuild.** Variance (population AND sample),
   standard deviation, mean, Cohen's d, KL divergence, Shannon entropy, Bayesian update
   all exist in `math/statistics.ex`, `math/probability.ex`,
   `foundations/information_theory.ex`, `numerics.ex`. D5 computes disagreement/sensitivity
   metrics by composing these; it must not add a parallel stats module.
2. **Bias/noise anchor:** D2 `Calibration` (reliability + variance) is the existing
   systematic-directional evidence source; D5 adds target-level *noise* via repetition.
3. **Minority preservation pattern exists:** `DistributedValidationResult` already models
   disagreement WITHOUT collapsing it (per-institution position + evidence, `:contested`,
   `has_minority_position?`). D5 can mirror this discipline for evaluator/model disagreement
   rather than inventing a new one, or ADAPT it.
4. **Temporal firewall:** extend D4 `TemporalFirewall` pattern (`POST_OUTCOME_ANALYSIS`
   label; bar from decision-time quality).
5. **Consensus infra is governance-scoped** (`OCM`/voting) — **ADAPTER boundary only**, do
   NOT reuse voting to produce epistemic "truth"; D5 keeps disagreement as information.
6. **Certification harness:** extend V-gate no-trust verifier V1–V35 → V36+.
7. **Immutability:** content-address + read-only adapters over D2/D3/D4 records (as D4 did).

---

## 4. Proposed D5 boundary (feeds contract, Phase 2)

```yaml
contract: EFDI_D5_NOISE_ROBUSTNESS_BOUNDED
status: PROPOSED — PENDING_COUNCIL_AUTHORIZATION
position: epistemic_analysis_layer_composing_D1-D4
canonical_untouched:
  - probability_engine: D2 substrate reused
  - causal_engine: D4 substrate reused
  - world_model: read-only
  - statistics: Tiannara.Math.* / Foundations.InformationTheory / Numerics reused
  - authorization: Council · execution: AEO · constitution: CIS

in_scope:
  - repeated_judgment_records            # SINGLE_OBSERVATION vs REPEATED_EVIDENCE
  - perturbation_specs_with_budgets      # bounded, rationale-linked, malformed rejected
  - disagreement_preservation            # individuals primary, aggregates derived
  - noise_source_decomposition           # identifiability-constrained
  - sensitivity_and_robustness_classes   # contract-defined + provenance-linked thresholds
  - decision_robustness_annotations      # never rewrites D3
  - forecast_robustness_annotations      # never rewrites D2
  - counterfactual_sensitivity           # never alters D4 status ontology
  - regime_tagging_and_mismatch_guards
  - post_outcome_analysis_labeling

out_of_scope (hard prohibitions):
  - institutional_lessons               # D6
  - execution_or_authorization
  - modification_of_any_historical_record
  - new_probability/causal/statistics/world_model/memory subsystem
  - robustness_claims_without_perturbation_coverage
  - noise_claims_without_repetition
  - agreement==correctness, disagreement==error, confidence==robustness
```

---

## 5. Gap analysis (live-confirmed)

| Gap | Evidence | Severity | Closing mechanism |
|-----|----------|----------|-------------------|
| G1 repeated vs single judgment | no repeated-eval machinery | Critical | RepeatedJudgmentRecord; n=1 ⇒ no noise claim |
| G2 perturbation framework | only ad-hoc perturb | Critical | PerturbationSpec contract; bounded designs |
| G3 preservation of individuals | only aggregate paths | Critical | DisagreementRecord; individuals primary |
| G4 noise-source identifiability | no crossed-design modelling | High | decomposition valid only under crossing; else UNKNOWN |
| G5 sensitivity tracking | piecemeal thresholds (e.g. 0.1/0.2/0.5 in VoI) | High | contract-defined thresholds + provenance; no code-constants |
| G6 robustness classification | absent | High | class defs in contract; untested ⇒ UNKNOWN |
| G7 confidence/robustness separation | no dual-axis schema | High | separate axes; no conflation field |
| G8 regime tagging | absent | High | regime metadata mandatory; REGIME_MISMATCH |
| G9 correlated-model consensus | no diversity metadata | High | effective-independent-count; downgrade unknown-lineage consensus |
| G10 POST_OUTCOME labeling | absent | Critical | firewall extension + label |
| G11 bounded computation | absent | High | MAX_* budgets; deterministic rejection |
| G12 metric semantics | metrics lack declared applicability/min-n | Medium | every metric: output-type + min-n |

---

## 6. Risk register (top items)

| ID | Risk | Severity | Mitigation |
|----|------|----------|------------|
| R1 | fake robustness (insufficient coverage) | Critical | UNKNOWN default; min-coverage for class |
| R2 | fake consensus (correlated models) | Critical | diversity/effective-independent-count |
| R3 | averaging away disagreement | Critical | individuals primary; V56 |
| R4 | arbitrary thresholds | High | contract-defined + adversarial threshold test |
| R5 | confidence inflation | High | separated axes; V46 |
| R6 | bias/noise confounding | High | bias←D2 calibration; noise←repetition; else UNKNOWN |
| R7 | combinatorial explosion | High | MAX_* budgets pre-execution |
| R8 | temporal contamination | Critical | firewall extension + labeling |
| R9 | historical mutation | Critical | read-only adapters + hashes |
| R12 | replay nondeterminism | High | pinned seeds/versions; documented nondeterminism |
| R13 | D6 scope creep | Medium | schema has no lesson fields |
| R14 | duplicate existing substrate | High | **scan-resolved: stats/disagreement already present → REUSE** |

---

## 7. Files likely to change

**Phase 1 (this package):** `docs/architecture/EFDI_D5_ARCHITECTURE_RECONNAISSANCE.md`
(this file), `docs/architecture/EFDI_D5_CLASSIFICATION_MATRIX.md`.

**Phase 2 (proposals only, no fabricated authorization):**
`certification/forecasting/contracts/EFDI_D5_CONTRACT.md`,
`certification/forecasting/authorization/EFDI_D5_AUTHORIZATION.md`.

**Phases 3–6 (post-authorization):** implementation in `lib/tiannara/forecasting/`
as `*.ex` modules (expected footprint: ~6 boundary modules + read-only adapters,
mirroring D4), plus the `EFDI_D5_*` architecture/verification/certification set.

**Expected NEW modules (pending contract):**
`repeated_judgment.ex`, `perturbation.ex`, `disagreement.ex`, `noise_decomposition.ex`,
`sensitivity.ex`, `robustness.ex` (+ D5 temporal-firewall extension), and read-only
adapters for D2/D3/D4 targets. **If scan identifies an even closer existing substrate,
these reduce to ADAPTERS.**

---

## 8. STOP

Phase 1 reconnaissance complete (live-scan corrected). **No implementation performed.**
No authorization fabricated. D6 untouched. Next step is Phase 2 (contract) ONLY after
human Council authorization for D5 to proceed from reconnaissance.
