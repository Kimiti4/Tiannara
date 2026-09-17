# Tiannara — Empirical Validation: Classification Matrix

**Phase 0 deliverable.** Maps every mission-named capability / infrastructure area to a verified live-code classification. Classification is **REAL / PARTIAL / SIMULATED / STUBBED / ABSENT / UNKNOWN** and was determined by reading the actual `lib/tiannara/` source — never by trusting filenames, docs, module names, or claimed certification.

**Date:** 2026-09-03 · **HEAD:** `3bd1601`

## Classification key

- **REAL** — genuine implementation with actual logic (+ tested where noted).
- **PARTIAL** — exists but trivial/under-implemented for the claim it carries.
- **SIMULATED** — "looks real, is not": logs hardcoded values / fake measurements.
- **STUBBED** — genuine placeholder (raises, returns default, or empty).
- **ABSENT** — does not exist in runnable code.
- **UNKNOWN** — cannot be validated from current state (provenance/data unverifiable).

## Capabilities

| ID | Capability | Class | Tested? | Primary evidence (file) |
|----|-----------|-------|---------|-------------------------|
| C-01 | World state / world model | REAL | Yes (19 files) | `world/unified_world_model.ex`, `version_manager.ex`, `replay_engine.ex` |
| C-02 | Simulation engine | REAL | Yes | `simulation/simulation_engine.ex` + 4 test files |
| C-03 | Multiworld / counterfactual forks | REAL | Yes | `simulation/multiworld/*` |
| C-04 | Scenario builder / horizon planner / impact forecaster | REAL | Yes | `simulation/scenario_builder.ex`, `horizon_planner.ex`, `impact_forecaster.ex` |
| C-05 | P9X ecosystem | STUBBED | No | `p9x_ecosystem/supervisor.ex` (empty children) |
| C-06 | Ecology organism | REAL | No | `ecology/civilization.ex` (REA behaviour, 236L) |
| C-07 | Ecology tracker (Shannon diversity) | REAL | No | `ecology.ex` (ETS, 380L) |
| C-08 | Ecology regime ladder | SIMULATED | No | `ecology/regime_ladder.ex` (hardcoded gate values, `# Mock`) |
| C-09 | Civics / civilization constitution | STUBBED | No | `civics/constitution.ex` (10L placeholder) |
| C-10 | Orbit classifier | PARTIAL | No | `orbital/classifier.ex` (14L trivial cond) |
| C-11 | Orbit analysis (residency/resilience/reachability) | PARTIAL/UNKNOWN | No | `discoveries/orbit_*.ex` — real math, data provenance unknown |
| C-12 | Stabilization OLEF | REAL | **No** | `stabilization/olef.ex` (+ harmonics) ~686L |
| C-13 | Stabilization OCM | REAL | **No** | `stabilization/ocm.ex` (+consensus) ~965L |
| C-14 | Stabilization HSV | REAL | **No** | `stabilization/hsv.ex` (+detector) ~766L |
| C-15 | Stabilization CTL | REAL | **No** | `stabilization/ctl.ex` 515L |
| C-16 | Evolution engine | REAL | Yes | `evolution/*` + 3 test files |
| C-17 | Long-horizon evolution validation | REAL | Yes | `evolution/long_horizon.ex`, `harness.ex` |
| C-18 | Intelligence tiers | **ABSENT** | — | 0 matches in `lib/**/*.ex`; "Tier" = certification/audit tiers |
| C-19 | Forecasting D1–D5 | REAL | **Yes (354 tests)** | `forecasting/*` (efdi, d5, decision, calibration ...) |
| C-20 | Forecasting planner (D6-ish) | SIMULATED | No | `forecasting/planner.ex` (hardcoded regret/effectiveness) |
| C-21 | Council authorization/control | REAL | — | `council/council.ex`, `authorization.ex` |
| C-22 | CIS cognitive immune / collapse predictor | REAL | — | `cis/supervisor.ex` (returns `:unknown/:insufficient_evidence`) |

## Scientific / empirical infrastructure

| ID | Area | Class | Tested? | Primary evidence (file) |
|----|------|-------|---------|-------------------------|
| I-01 | Reproducibility framework (`repro/`) | REAL | — | `repro/manifest.ex` (git+OTP+SHA-256), `verdict.ex` |
| I-02 | Observatory validation harness | REAL | — | `observatory/validation/checks.ex` (live `:erlang.*`) |
| I-03 | Telemetry runtime adapter | REAL | — | `telemetry/adapter.ex`, `metrics/export.ex` → ndjson |
| I-04 | Discovery pipeline telemetry | REAL (honest) | — | `discovery/pipeline_telemetry.ex` (`:uninstrumented`) |
| I-05 | Evidence schema / provenance | REAL (no persistence) | — | `evidence/provenance.ex` (refuses fabrication); **no ledger** |
| I-06 | Archaeology | SIMULATED | No | `archaeology.ex` (hardcoded recovery scores) |
| I-07 | Epistemic mirror | SIMULATED | No | `epistemic_mirror/*_auditor.ex` (hardcoded fidelity 0.98) |
| I-08 | Discovery engine (scenario) | SIMULATED | No | `discovery/engine.ex` (hardcoded metrics) |
| I-09 | Validation campaign | SIMULATED | No | `validation/campaign.ex` (`# Simulate execution`) |
| I-10 | Experiment planner | REAL | — | `discovery/experiment_planner.ex` (cost/controls/stopping) |
| I-11 | Research pipeline | REAL (exec disabled) | — | `research/director/evidence_driven.ex`; R0 `:fabrication_path_disabled` |
| I-12 | Metrics aggregator | REAL (drops sim pushes) | — | `metrics/aggregator.ex` (no-op casts for sim events) |
| I-13 | Stubs layer | STUBBED (genuine) | — | `stubs/*` (12 modules via `use Tiannara.Stub`) |
| I-14 | Independent verifier `verification_authority.ex` | REAL-non-functional (honest) | — | returns `method: :unavailable`, `:not_independently_assessed` |
| I-15 | "Independent audit" (Phase 14) | ARTIFACT-FINGERPRINT | — | SHA-256 of frozen JSON; trusts self-declared `status:"passed"` |
| I-16 | Experiment registry | PARTIAL / IN-MEMORY | — | `research/director.ex` ETS (not persisted); **no durable registry** |
| I-17 | Evidence ledger | ABSENT | — | no persistence in `evidence/`/`provenance/` |
| I-18 | Root `simulation_output/*.csv` | SIMULATED | — | 11-line scripted campaigns; flat/near-linear trend data |

## Cross-cutting risk assignments (mission language)

| Risk (master prompt) | Where it materially lives today |
|---|---|
| FALSE EMERGENCE (semantic recycling / metric gaming / hidden hardcoding) | `archaeology/`, `epistemic_mirror/`, `discovery/engine.ex`, `forecasting/planner.ex`, `ecology/regime_ladder.ex`, synthetic CSVs — all log hardcoded "success" |
| STABILIZER-INDUCED EQUILIBRIUM / evolutionary suppression | OLEF/OCM/HSV/CTL (real, untested) — claims about order vs. genuine ecology unvalidated |
| Selection effects / survivorship / regression-to-mean | D4 handles analytically (certified); no empirical campaigns yet to feed it |
| Evaluator noise / model noise / prompt sensitivity | D5 handles analytically (certified); no empirical campaigns yet to feed it |
| Metric gaming / Goodhart | present — aggregator discards sim pushes; but observation layer must close |
| Post-hoc interpretation / instrumentation artifacts | telemetry real but log-only; no durable ledger → risk open |

## Recommended next-step consequences (recorded, not executed)

1. **Harness of record:** D1–D5 forecasting chain (354 tests) is the trustworthy measurement-grade reference for running falsification controls (shuffle/random/metric-preserving/replay novelty).
2. **Highest-evidence-gap controls to build first** (in a later, Council-authorized phase): 
   - Random / shuffled-lineage / metric-preserving controls against `archaeology`+`epistemic_mirror`+`planner` simulated output.
   - Stabilizer on/off (no/normal/aggressive) over the evolution engine to test whether apparent order is stabilizer-produced (candidate FALSE-EMERGENCE + stabilizer-overcontrol test).
   - Novelty-recycling control (feed prior patterns back; does any system classify recycling as novelty?).
3. **Infrastructure gaps to be filled only with explicit authorization:** durable experiment registry + persisted evidence ledger + a genuine no-trust empirical auditor (mission Phase 19). The existing `:fabrication_path_disabled` and provenance-`kind` honesty are the right enabling seams.
4. **Claims that are currently UNKNOWN/ABSENT and must not be certified:** intelligence tiers (absent), orbit engineering/attractors (provenance unknown), archaeology/epistemic-mirror fidelity (simulated), stabilizer-supported emergence (untested).

## Non-goals honored

No code modified · D1–D5 frozen · no new subsystem invented · no experiment executed · no certification issued. This matrix is Phase-0 evidence only.
