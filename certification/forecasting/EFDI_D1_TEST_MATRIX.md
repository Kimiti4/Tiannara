# EFDI D1 — Test Matrix

**Gate:** EFDI-D1

## 1. Test files

| File | Covers |
|------|--------|
| `signal_test.exs` | struct defaults, validate, version immutability, expired?, dedup_key |
| `signal_registry_test.exs` | register/get, dedup single-count, queries, supersede, stats, health |
| `signal_quality_test.exs` | 7-dimension scoring, aggregate, config weights |
| `signal_value_test.exs` | predictive value / info gain (`:unknown` pre-outcome) |
| `provenance_test.exs` | content-hash determinism, integrity |
| `correlation_test.exs` | shares_origin, correlation value, redundancy_index |
| `adversarial_signal_test.exs` | malformed input, expired, all-nil, no-crash honesty, no fabrication |
| `replay_test.exs` | determinism, idempotent re-registration, lineage immutability |
| `contracts_test.exs` | ForecastRequest/Forecast/BaseRate structs; adapter callbacks |
| `integration_test.exs` | reuse of Numerics/Constraints, provenance, full pipeline |

## 2. Invariants proven

| Invariant | Test |
|-----------|------|
| Epistemic separation (Signal has no probability/decision) | `integration_test.exs` |
| `UNKNOWN` != `0.0` | `signal_quality_test`, `adversarial_signal_test` |
| Deterministic dedup + single-count | `replay_test`, `signal_registry_test` |
| Historical immutability | `replay_test` ("no historical revisionism"), `signal_test` (version) |
| No fabrication pre-outcome | `signal_value_test`, `adversarial_signal_test` |
| Graceful degradation (health) | `signal_registry_test` |
| Adapter boundaries declare-only | `contracts_test` |

## 3. Execution record

Total: 10 files. Independent verifier V8 runs
`mix test test/tiannara/forecasting` and asserts 0 failures with exit code 0.
