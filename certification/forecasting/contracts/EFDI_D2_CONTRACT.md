# EFDI D2 — Contract

**Gate:** EFDI-D2

## Scope

D2 delivers: Forecast, Probability Integrity, Base-Rate Engine, Pluggable
Forecaster, Evidence Update, Calibration, Forecast Evaluation, Forecast Score
Security, Outcome Linking, Hindsight Isolation, Research Director / CIS /
WorldModel adapter implementations.

## Required invariants

| Gate | Verifier test | Behaviour |
|------|---------------|-----------|
| V1   | Forecast Contract | `Contracts.Forecast` has all required fields; `validate/1` returns `{:ok, _}` for valid |
| V2   | Probability Integrity | bounds, normalization, count-match, UNKNOWN not `0.0` |
| V3   | Evidence Lineage | `signal_refs`, `evidence_refs` present in registry record |
| V4   | Base-Rate Integrity | bounds, unknown→honest, no binary→ternary mapping |
| V5   | Forecast Immutability | re-registration is no-op; registered record unchanged |
| V6   | Version Lineage | `version/2` → new id, `forecast_version + 1`, lineage prepend |
| V7   | Outcome Integrity | before `created_at` → `{:error, :hindsight_contamination}` |
| V8   | Calibration Correctness | Brier/log-loss at known values; INSUFFICIENT ≠ POOR |
| V9   | Replay/Reproducibility | same inputs ⇒ same probs (within float precision); scoring identical |
| V10  | Adversarial Robustness | huge/OOB/neg/all-zero/outcome-mismatch rejected |
| V11  | Hindsight Isolation | `guard!/2` rejects contaminated; clean passes |
| V12  | Insufficient-Data | `reliability_level(n<5) == :insufficient`; scores unscorable forecasts as `:unknown` |

## Not modified

D1 signals, quality, provenance, correlation, registry, value; ForecastAuditor,
FutureSimulator, StrategicPlanner, DecisionArchive stubs — untouched.