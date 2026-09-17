# Tiannara — Claim Registry

**Phase 1 deliverable.** Machine-relevant registry of Tiannara's major empirical claims, mapped to verified evidence. Each claim carries `claim_id`, statement, originating phase, supporting artifacts, current evidence level, required evidence, falsification condition, baseline, measurement method, confounders, status, provenance.

**Governing rule:** these claims are recorded **so they can be attacked**. No claim is assumed true. Every status below is **UNKNOWN / UNTESTED / SIMULATED_ONLY / ABSENT** unless genuine, reproducible, tested evidence exists.

**Date:** 2026-09-03 · **HEAD:** `3bd1601` · Evidence levels follow the mission certification model:
`UNTESTED → TESTED → REPLICATED → PARTIALLY_VALIDATED → VALIDATED_BOUNDED → ROBUSTLY_VALIDATED · FALSIFIED · INCONCLUSIVE · UNKNOWN`.

---

## Evidence-level reference (mission certification model)

| Level | Meaning |
|---|---|
| UNTESTED | No empirical test performed |
| TESTED | Single controlled/baselined trial passed |
| REPLICATED | Independent seeds/cohorts reproduce |
| PARTIALLY_VALIDATED | Bounded evidence, some gaps |
| VALIDATED_BOUNDED | Robust within declared bounds |
| ROBUSTLY_VALIDATED | Survives perturbation + replication |
| FALSIFIED | A falsification condition was met |
| INCONCLUSIVE / UNKNOWN | Cannot decide from current evidence |

---

## Registry

### CLAIM-E01 — Tiannara maintains adaptive diversity.

- **statement:** The substrate sustains adaptive ecological/behavioral diversity over time rather than collapsing to monoculture.
- **originating_phase:** Phase 7 (Diversity & Monoculture) of master prompt; underlying `ecology.ex` (Shannon diversity), `evolution/`.
- **supporting_artifacts:** `lib/tiannara/ecology.ex`; root `simulation_output/*.csv` (synthetic).
- **current_evidence_level:** **UNTESTED** (ecology tracker is REAL but untested; CSV "diversity" is synthetic trend data).
- **required_evidence:** repeated seed cohorts measuring lineage entropy, niche occupancy, dominance share, with/without intervention.
- **falsification_condition:** Convergence to a single lineage (dominance share → 1) or entropy stalled at floor across independent seeds AND interventions.
- **baseline:** not yet frozen (needs Phase 2 manifest).
- **measurement_method:** Shannon diversity index + lineage entropy + dominance share over epochs.
- **confounders:** stabilizer-forced homogeneity; metric-gaming by diversity headline.
- **status:** **UNTESTED**
- **provenance:** recon C-06/C-07; I-18 (CSV synthetic).

### CLAIM-E02 — Tiannara avoids monoculture attractors.

- **statement:** The system does not settle into a single self-reinforcing behavioral attractor.
- **supporting_artifacts:** `ecology.ex`, `evolution/trajectory.ex` (monoculture detection), stabilizer stack.
- **current_evidence_level:** **UNTESTED**
- **required_evidence:** cross-seed trajectory analysis; counterfactual "no stabilizer" arm.
- **falsification_condition:** >1 independent seed converges to identical attractor in the absence of genuine interaction (stabilizer artifact).
- **status:** **UNKNOWN**

### CLAIM-E03 — Stabilization preserves emergence rather than suppressing it.

- **statement:** OLEF/OCM/HSV/CTL regulate without destroying adaptive exploration.
- **supporting_artifacts:** `stabilization/{olef,ocm,hsv,ctl}.ex` (REAL, **untested**).
- **current_evidence_level:** **UNTESTED**
- **required_evidence:** stabilization on/off/aggressive matrix measuring novelty, diversity, exploration loss, recovery, collapse (mission Phase 8).
- **falsification_condition:** Aggressive stabilization reduces novelty/exploration to floor while preventing collapse (regulatory order, not genuine emergence) OR stabilizers are required to produce all observed order (no spontaneous emergence without them).
- **status:** **UNKNOWN** — this is the top risk candidate (stabilizer-only emergence).

### CLAIM-E04 — Distinct civilizations maintain meaningful behavioral diversity.

- **statement:** Civilizations produce distinct, non-identical behavior.
- **supporting_artifacts:** `ecology/civilization.ex` (organism, REAL); `civics/` (STUBBED).
- **current_evidence_level:** **UNTESTED** (organism is REAL; no civilizational diversity measurement; civics placeholder).
- **required_evidence:** per-civilization behavioral fingerprints across seeds.
- **falsification_condition:** All civilizations converge to identical behavior despite distinct seeds/lineages.
- **status:** **UNKNOWN**

### CLAIM-E05 — Intelligence tiers correspond to measurable capability differences.

- **statement:** Tiered intelligence levels map to empirically distinct capabilities.
- **supporting_artifacts:** NONE in runnable code ("intelligence tier" = **0 matches** in `lib/`).
- **current_evidence_level:** **ABSENT**
- **required_evidence:** a tier model would first need to exist; then per-tier abstraction/horizon/accuracy/transfer measurement.
- **falsification_condition:** Tier N does not consistently outperform Tier N-1 after controlling compute/population/exposure/luck/evaluator/environment.
- **status:** **ABSENT** — not falsifiable as phrased; must be recorded as ABSENT, not assumed.

### CLAIM-E06 — Novelty is sustained rather than recycled.

- **statement:** The system generates new semantic content over time, not recycled prior patterns.
- **supporting_artifacts:** `discovery/engine.ex`, `archaeology.ex`, `epistemic_mirror/` (all **SIMULATED**); `discovery/pipeline_telemetry.ex` (honest live).
- **current_evidence_level:** **SIMULATED_ONLY** (novelty numbers are hardcoded).
- **required_evidence:** a novelty-recycling CONTROL — feed prior patterns back; measure whether any subsystem classifies recycling as novelty.
- **falsification_condition:** Recycling previously-seen patterns is classified as novel (semantic recycling mistaken for emergence).
- **empirical_result_2026-09-03:** **FALSIFIED at function level** — Phase 3 probe `Discovery.Engine.discover(:novelty_trap, ...)` with `payload.claim = :brand_new` AND `payload.claim = :recycled` produced **identical** "Truth > Novelty verified, rejecting useless novelties" log + identical hardcoded push. A genuine novelty detector would distinguish these. See `FALSE_EMERGENCE_TEST_PLAN.md` §3.2.
- **status:** **FALSIFIED (at the discovery-engine level)** — the claim cannot be supported by these handlers. Real novelty detection must exist elsewhere to support the claim; none observed in this campaign.

### CLAIM-E07 — Semantic continuity survives long-horizon evolution.

- **statement:** Meaning/identity persist across long evolution horizons.
- **supporting_artifacts:** `archaeology.ex`, `epistemic_mirror/` (SIMULATED); `stubs/longitudinal_memory.ex` (STUB).
- **current_evidence_level:** **SIMULATED_ONLY / STUBBED**
- **required_evidence:** controlled disruptions measuring recover/fragment/mutate/lose-identity/false-continuity (mission Phase 13).
- **falsification_condition:** Identity reconstruction returns fabricated (plateau) values instead of measured lineage (as the stub currently returns `leoc: [1.0,0,0,0]`).
- **empirical_result_2026-09-03:** **FALSIFIED at function level** — Phase 3 probe of `Archaeology.IdentityPreserver.preserve/2`, `Archaeology.SemanticReconstructor.reconstruct/2`, `Archaeology.EpochCompressor.compress/2`, and `Discovery.ArchaeologicalRecall.recall/2` confirmed all emit "identity remains continuous with origin" / "semantic meaning restored" / "universal truths preserved" as single `Logger.info` lines **independent of the input payload** (the signatures use `_payload`). The archaeology support for CLAIM-E07 is theatrical. See `FALSE_EMERGENCE_TEST_PLAN.md` §3.1.
- **status:** **FALSIFIED (at the archaeology / discovery surface)** — the semantic-continuity claim cannot be supported by these handlers.

### CLAIM-E08 — Adaptive behavior is not merely stochastic noise.

- **statement:** Observed "adaptation" is distinguishable from random drift (D5 variance ≠ noise discipline).
- **supporting_artifacts:** `forecasting/d5/*` (certified, 354 tests); structure is analysis-grade.
- **current_evidence_level:** **VALIDATED_BOUNDED at the analytical(D5)-level only**; empirical adaptation claims UNTESTED.
- **required_evidence:** randomized control comparing adaptive decisions to stochastic processes (mission Phase 3A).
- **falsification_condition:** Adaptation metrics are statistically indistinguishable from random baselines.
- **status:** **INCONCLUSIVE** for the empirical claim.

### CLAIM-E09 — Orbit classes represent reproducible dynamical regimes.

- **statement:** Orbit classifications correspond to stable, repeatable dynamical states.
- **supporting_artifacts:** `orbital/classifier.ex` (trivial); `discoveries/orbit_*.ex` (real math over `data/orbit_transitions.ndjson`, provenance unknown).
- **current_evidence_level:** **PARTIAL/UNKNOWN** (no tests; data provenance unverified).
- **required_evidence:** independent seeds reproduce orbit populations; sensitivity of classification to thresholds.
- **falsification_condition:** Orbit classes are an artifact of the classifier thresholds / synthetic data rather than of system dynamics.
- **status:** **UNKNOWN**

### CLAIM-E10 — Some orbit transitions are controllable.

- **statement:** Intervention sequences can steer orbits toward targets.
- **supporting_artifacts:** `discoveries/orbit_transitions.ex`; `orbital/`.
- **current_evidence_level:** **UNTESTED**
- **required_evidence:** pre-registered target orbit + intervention budget + success/failure condition (mission Phase 9).
- **falsification_condition:** Observed P(A→B) is indistinguishable from the unperturbed transition matrix / noise.
- **status:** **UNKNOWN** — treat as hypothesis until supported.

### CLAIM-E11 — Forecasts are calibrated.

- **statement:** D2 forecast probabilities match long-run frequencies.
- **supporting_artifacts:** `forecasting/calibration.ex`; D2 certification (certified bounded).
- **current_evidence_level:** **CERTIFIED at the module level; empirically UNTESTED** (no real outcome corpus).
- **required_evidence:** true holdout Brier/log-loss/reliability over locked outcomes vs baselines (mission Phase 10).
- **falsification_condition:** Calibration curve deviates from diagonal beyond tolerance on held-out outcomes.
- **status:** **INCONCLUSIVE** without a real empirical outcome corpus.

### CLAIM-E12 — Decisions remain distinguishable from outcomes.

- **statement:** Decision-time quality is not rewritten by retrospective outcome (no resulting / hindsight / outcome leakage).
- **supporting_artifacts:** D3 (certified), `forecasting/decision_engine.ex`.
- **current_evidence_level:** **CERTIFIED analytically; empirically UNTESTED**.
- **required_evidence:** the 2×2 matrix (good/bad decision × good/bad outcome) verifying no post-outcome rewrite across four cells.
- **falsification_condition:** A good-decision→bad-outcome case is relabeled bad, or vice versa, after the outcome is known.
- **status:** **INCONCLUSIVE**

### CLAIM-E13 — D5 correctly identifies instability, disagreement and sensitivity.

- **statement:** D5's classifications (unstable/sensitive/fragile/robust; disagreement; bias) reflect real system behavior and not merely its own formulas.
- **supporting_artifacts:** `forecasting/d5/*` — 354 tests, certified bounded (analytical correctness).
- **current_evidence_level:** **VALIDATED_BOUNDED (formula correctness); empirical grounding UNTESTED** (no real perturbed-system corpus fed through D5).
- **required_evidence:** run D5 over actual perturbed runs (mission Phase 5: different seeds/prompts/evidence-orders/models/evaluators) and verify classifications against gold-standard labels.
- **falsification_condition:** D5 labels a material, replicable change as UNKNOWN/negligible, or noise from a correlated lineage as independent consensus.
- **status:** **PARTIALLY_VALIDATED** (analytically) — `empirical grounding UNTESTED`.

### CLAIM-E14 — Counterfactual reasoning does not contaminate observed reality.

- **statement:** D4 hypothetical/alternative records never promote to OBSERVED or rewrite D3/time-of-decision evidence.
- **supporting_artifacts:** D4 (certified), `forecasting/counterfactual.ex`, `regression_to_mean.ex`, `temporal_firewall.ex`.
- **current_evidence_level:** **VALIDATED_BOUNDED (analytic firewall, 354 suite)**; empirical contamination test = run forensic string on live runs (mission Phase 12).
- **falsification_condition:** A hypothetical record becomes OBSERVED, or post-outcome info reaches decision-time fields, on any live path.
- **status:** **VALIDATED_BOUNDED** (as an analytic invariant) — empirical recon NOT yet run on live substrate.

### CLAIM-E15 — Governance interventions improve resilience without destroying exploration.

- **statement:** Governance/control improves survival without suppressing exploration.
- **supporting_artifacts:** `council/`, `cis/`, `stabilization/`, `evolution/` (control is REAL, mostly untested).
- **current_evidence_level:** **UNTESTED**
- **required_evidence:** intervention on/off/over-force matrix measuring resilience + exploration loss (mission Phases 7–8, 15).
- **falsification_condition:** Interventions improve resilience only by eliminating exploration (no bounded adaptive emergence).
- **status:** **UNKNOWN**

> Note: CLAIM-E01–E15 are the mission's exemplar seed set. A fuller registry (beyond 15) can be derived once an experiment + evidence ledger exists (mission Phase 16+). Additional claims implied by the live substrate (e.g., "stabilizers prevent collapse", "archaeology reconstructs lineage", "epistemic mirror reflects state") are NOT listed above because their supporting subsystems are SIMULATED/STUBBED; they are instead recorded as FALSE-EMERGENCE targets in the classification matrix, not as validatable claims.

## Global status summary

| Claim | Status |
|-------|--------|
| E01 adaptive diversity | UNTESTED |
| E02 avoid monoculture attractors | UNKNOWN |
| E03 stabilization preserves emergence | **UNKNOWN (top risk)** |
| E04 civilizations behavioral diversity | UNKNOWN |
| E05 intelligence tiers | **ABSENT** |
| E06 novelty sustained (not recycled) | **FALSIFIED** (Phase 3, discovery-engine level) |
| E07 semantic continuity | **FALSIFIED** (Phase 3, archaeology/discovery surface) |
| E08 adaptation ≠ noise | INCONCLUSIVE |
| E09 orbit regimes reproducible | UNKNOWN |
| E10 orbit transitions controllable | UNKNOWN (hypothesis) |
| E11 forecasts calibrated | INCONCLUSIVE (no corpus) |
| E12 decision ≠ outcome | INCONCLUSIVE |
| E13 D5 identifies instability/sensitivity | PARTIALLY_VALIDATED (analytic); grounding UNTESTED |
| E14 counterfactual doesn't contaminate | VALIDATED_BOUNDED (analytic) — live recon pending |
| E15 governance improves resilience | UNKNOWN |

## Phase 3 recorded storage-layer finding (most severe)

`Tiannara.Forecasting.StrategicPlanner.evaluate_and_act(:intervention_quality, _payload)` writes a **hardcoded** record to the live `Tiannara.Forecasting.DecisionArchive`:

```elixir
DecisionArchive.record(%{predicted: "Stabilization",
                       chosen:   "Quarantine node X",
                       actual:   "Stabilization",
                       regret:   0.04})
```

`chosen: "Quarantine node X"`, `regret: 0.04`, `predicted: "Stabilization"`, and `actual: "Stabilization"` are literal constants in the source, independent of the planner's input. The write occurs for every invocation regardless of payload. **This is fabrication at the storage layer, not just at the log layer**, and any downstream D3/D4/D5 measurement that reads from `DecisionArchive` is exposed to fabricated records masquerading as measured outcomes. Logged as a **GAP** in `FALSE_EMERGENCE_TEST_PLAN.md` §5; not fixed in this mission per the NO-ARCHITECTURAL-EXPANSION rule.

## Non-goals honored

No code modified · D1–D5 frozen · no experiments executed · no fabrication of evidence · claims recorded strictly at their **verified** evidence level; nothing is promoted to VALIDATED/BOUNDED without real, reproducible, baselined evidence.
