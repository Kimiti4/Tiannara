# EFDI D2 — Test Matrix

**Gate:** EFDI-D2

## 1. Test files (new in D2)

| File | Tests | Covers |
|------|-------|--------|
| `forecast_test.exs` | 13 | Forecast construction, validate (OOB, zeros, mismatch, :unknown), version/2 |
| `base_rate_engine_test.exs` | 9 | BaseRate validation, available?, compare, normalize_frequency |
| `forecast_engine_test.exs` | 10 | Engine forecast, base_rate_prior, update_with_bayes, ForecastRequest struct |
| `forecast_registry_test.exs` | 7 | Register, get, count, no-op re-register, health |
| `outcome_test.exs` | 8 | Outcome.new, hindsight_clean?, guard! boundary |
| `calibration_test.exs` | 14 | Brier/log-loss, mean_*, calibration_error, resolution, reliability, INSUFFICIENT_DATA, sharpness |
| `d2_integration_test.exs` | 9 | Full signal→forecast→outcome→score pipeline, adapters, versioning |
| `forecast_adversarial_test.exs` | 26 | Probability integrity, immutability, hindsight, calibration, base-rate, adapter boundaries |
| `forecast_replay_test.exs` | 8 | Reproducibility, lineage reconstruction, scoring determinism |

Total D2 tests: **104**.

## 2. D1 files (unmodified, all passing)

| File | Tests |
|------|-------|
| `signal_test.exs` | 15 |
| `signal_registry_test.exs` | 13 |
| `signal_quality_test.exs` | 10 |
| `signal_value_test.exs` | 8 |
| `provenance_test.exs` | 9 |
| `correlation_test.exs` | 10 |
| `adversarial_signal_test.exs` | 10 |
| `replay_test.exs` | 4 |
| `contracts_test.exs` | 7 |
| `integration_test.exs` | 6 |

Total D1 tests: **92**.

## 3. Combined total

**196 tests, 0 failures** (`mix test test/tiannara/forecasting`).