# EFDI D2 — Invariants

Mechanical rules that D2 must never violate. Each maps to a test.

| # | Invariant | Enforcement | Test |
|---|-----------|-------------|------|
| I1 | Forecast is immutable | registry re-register = no-op; versioning == new id | `forecast_registry_test`, `forecast_replay_test` |
| I2 | `UNKNOWN` ≠ `0.0` | `probabilities: :unknown` distinct from `[0.0,…]`; unscorable → `sample_size 0` | `forecast_test`, `calibration_test`, adversarial |
| I3 | Bounds & finiteness | out-of-bounds / non-finite preserved and rejected | adversarial probability-integrity |
| I4 | Normalization | in-bounds lists normalize to sum `1.0`; all-zeros rejected | `forecast_test` |
| I5 | Probability↔outcome cardinality | mismatch → `:outcome_probability_mismatch` | `forecast_test`, adversarial |
| I6 | No silent repair | construction preserves violations, does not clamp | adversarial ("no silent clamp") |
| I7 | No fabrication of prior | no base rate → `:unknown`, never uniform | engine + adversarial |
| I8 | Base-rate bounds | frequency in `[0,1]`, else rejected | `base_rate_engine_test`, adversarial |
| I9 | Hindsight isolation | outcome before `created_at` rejected | adversarial, `outcome_test` |
| I10 | Scoring attribution | method/value/sample_size recorded; `:unknown` honored | `calibration_test` |
| I11 | INSUFFICIENT_DATA distinct | `n<5 → :insufficient`; never "poor" off tiny sample | `calibration_test` |
| I12 | Reproducibility | same inputs ⇒ same distribution; versioned lineage reconstructible | `forecast_replay_test` |
| I13 | Adapter boundaries | consume existing infra; no parallel ontology | `d2_integration_test` |

## No hidden state

- No local posterior cache; Bayes update delegates to `Math.Probability`.
- No silent probability engine; projects through `Constraints`.
- No fabricated world-conflict; `WorldModelImpl` errors when snapshot is absent.