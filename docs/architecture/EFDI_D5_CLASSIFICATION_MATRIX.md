# EFDI D5 — Classification Matrix

**Gate:** EFDI-D5 (Phase 1) · **Date:** 2026-09-02 · **Basis:** LIVE repository scan.
All rows resolved from actual code — no `UNKNOWN / REPO_SCAN_PENDING` for scan-able items.

## Classification legend

- **REUSE** — compose as-is (read-only where the source is canonical).
- **ADAPTER** — wrap an existing substrate behind a D5-facing interface; no mutation.
- **EXTEND** — extend an existing certified pattern/interface additively.
- **NEW** — genuinely new D5 surface (confirmed absent in scan).
- *(defer)* — out of D5 scope (D6 or governance).

## Matrices

| # | Capability | Classification | Live evidence | Rationale |
|---|-----------|----------------|---------------|-----------|
| 1 | Mean / variance (population) | **REUSE** | `Math.Statistics.{mean,variance,standard_deviation}` | D5 dispersion metrics compose these |
| 2 | Variance (sample, n-1) | **REUSE** | `Numerics.variance/1` (`:insufficient_samples` for n<2) | sample variance is exactly the repetition-disagreement metric |
| 3 | Cohen's d effect size | **REUSE** | `Numerics.cohens_d/2` | model/evaluator pairwise disagreement magnitude |
| 4 | Shannon entropy | **REUSE** | `Math.Probability.shannon_entropy`, `Foundations.InformationTheory.shannon_entropy` | probability dispersion / uncertainty |
| 5 | KL divergence | **REUSE** | `Foundations.InformationTheory.kl_divergence/2` | model disagreement distance, prior perturbation |
| 6 | Bayesian update | **REUSE** | `Math.Probability.bayes_update/3` | prior-perturbation / posterior-sensitivity |
| 7 | D2 Calibration (reliability + variance) | **REUSE** | `Forecasting.Calibration` | systematic-directional (bias) anchor; forecast-robustness target |
| 8 | D2 Forecast (incl. `:disagreement` field) | **REUSE** (read-only target) | `Forecasting.Contracts.Forecast`, `ForecastRegistry` | D5 analyzes, never rewrites; field ready to populate as *derived* |
| 9 | D3 Decision + snapshot | **REUSE** (read-only target) | `Decision`, `DecisionSnapshot`, `DecisionRegistry` | decision-robustness target; snapshots immutable |
| 10 | D4 Counterfactual / attribution / selection / RTM | **REUSE** (read-only target) | D4 modules | counterfactual-sensitivity target; D4 status ontology authoritative |
| 11 | D4→D3 temporal firewall | **EXTEND** | `TemporalFirewall` | extend pattern for D5 `POST_OUTCOME_ANALYSIS` + D5→D3/D2/D4 firewall |
| 12 | Disagreement + minority preservation | **REUSE / ADAPTER** | `OS.DistributedValidationResult` (`disagreement_map`, `has_minority_position?`) | mirror/adapt the preserve-not-collapse discipline for evaluator/model disagreement |
| 13 | Consensus / voting engine | **ADAPTER** (boundary) | `OS.OCM.voting_system`, `consensus_manager` | governance-scoped; D5 does NOT use voting to assert truth — boundary only |
| 14 | EventStore lineage | **REUSE** | `Executive.EventStore` | INPUT→PERTURBATION→RUN→OUTPUT→AGGREGATION→CLASSIFICATION chain |
| 15 | Evidence provenance / certification gate | **REUSE** | `Evidence.{Provenance, CertificationGate, HistoricalQuarantine}` | admissibility of perturbation/run evidence |
| 16 | V-gate no-trust verifier | **EXTEND** | `certification/forecasting/verifiers/EFDI_D{1,2,3,4}_*.py` | continue V36+ |
| 17 | Value-of-information decision sensitivity | **ADAPTER** | `Forecasting.ValueOfInformation.decision_sensitivity/1` | reuse decision-sensitivity notion; D5 provides contract-defined thresholds (its 0.1/0.2/0.5 are local constants) |
| 18 | MultiWorld constraint-relaxation sensitivity | **REUSE (reference)** | `Simulation.MultiWorld.ConstraintRelaxer.analyze_sensitivity/1` | reference pattern for sensitivity aggregation; D5 target registry may reference |
| 19 | Perturbation *analysis framework* | **NEW** | none (only ad-hoc `random_perturbation` / sandbox `apply_perturbation`) | PerturbationSpec + budget/rationale/invariance + bounded designs |
| 20 | Repeated-judgment execution records | **NEW** | none | SINGLE_OBSERVATION vs REPEATED_EVIDENCE; n=1 ⇒ no noise claim |
| 21 | D5 disagreement metrics/record | **NEW** | none (KL/entropy exist, no record aggregation) | individuals primary; aggregates derived |
| 22 | Noise-source decomposition | **NEW** | none | identifiability-constrained; untested source ⇒ UNKNOWN |
| 23 | Robustness classification | **NEW** | none | contract-defined classes; untested ⇒ UNKNOWN |
| 24 | Regime tagging + mismatch guard | **NEW** | none | REGIME_MISMATCH / cross-regime aggregation rejected |
| 25 | Bounded-computation budget enforcement | **NEW** | none | MAX_* budgets, deterministic rejection |
| 26 | Ensemble reasoning (as a *system*) | **NEW** | no `ensemble` anywhere | D5 models evaluator/model plurality; no parallel ensemble engine exists to reuse — but D5 must NOT build a new probability engine; it aggregates *existing* outputs |
| 27 | Monte Carlo / stochastic simulation | **NEW (bounded)** | none | D5 does NOT need general MC — bounded representative perturbation sets; if a later stage wants sampling it stays bounded |
| 28 | Institutional learning / lessons | *(defer)* | — | D6 owns learning; D5 schema declares it out of scope |

## Net footprint

- **REUSE:** ~15 (stats, entropy, calibration, forecast/decision/counterfactual targets, EventStore, evidence, distributed-validation discipline)
- **ADAPTER:** ~3 (disagreement discipline, consensus-boundary, VoI sensitivity)
- **EXTEND:** 2 (temporal firewall, V-gate verifier)
- **NEW:** ~7 bounded boundary/analysis modules (`repeated_judgment`, `perturbation`,
  `disagreement`, `noise_decomposition`, `sensitivity`, `robustness`, `regime`/budget)

Mirrors D4's adapter-over-substrate precedent: the genuinely-NEW surface is the
analysis/boundary layer; the statistical + disagreement substrate is reused, not rebuilt.

## STOP

Classification resolved from live scan. No implementation. Phase 2 (contract) only after
human Council authorization. D6 untouched.
