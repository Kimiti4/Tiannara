# EFDI D1 — Contract

**Gate:** EFDI-D1
**Phase:** Signal Intelligence

## 1. Contract definition

D1 delivers a foundational, honest signal layer that D2–D6 will build upon,
without itself implementing forecasting.

### Deliverables

| # | Deliverable | Evidence |
|---|-------------|----------|
| 1 | `Signal` struct + `new/validate/version/expired?/dedup_key` | `lib/tiannara/forecasting/signal.ex` |
| 2 | `SignalRegistry` GenServer + ETS (dedup, query, supersede, health) | `signal_registry.ex` |
| 3 | `SignalQuality` (7 dimensions + config-driven weights) | `signal_quality.ex` |
| 4 | `SignalValue` (predictive value / info gain; `:unknown` pre-outcome) | `signal_value.ex` |
| 5 | `Provenance` (content hash, integrity) | `provenance.ex` |
| 6 | `Correlation` (shared-origin, redundancy) | `correlation.ex` |
| 7 | `Contracts` (ForecastRequest, Forecast, BaseRate) | `contracts.ex` |
| 8 | `Adapters.*` behaviours (Evidence/Research/CIS/WorldModel) | `adapters/adapters.ex` |
| 9 | `Tiannara.Forecasting` facade (start_link, register, quality, value, stats, health) | `efdi.ex` |
| 10 | Config (`:efdi_quality_weights`, `efdi_persist_signals`) | `config/config.exs` |
| 11 | Test suite (10 files) | `test/tiannara/forecasting/*.exs` |
| 12 | Docs (10 files) | `docs/architecture`, `docs/research` |

### Mode
- **Scope:** CREATE_D1 (new namespace modules only)
- **Mutation:** none of existing forecasting stubs
- **Live execution:** none (D1 is a pure contract layer; no deployment/side-effects
  beyond in-process registry)

## 2. Pass criteria (independent)

1. All 7 D1 modules present and compiling without new warnings.
2. Deterministic `dedup_key`; re-registration idempotent; no double-count.
3. Historical immutability; corrections append (`supersede/2`).
4. `:unknown` distinct from `0.0`.
5. Adapter behaviours declared (not implemented).
6. Existing forecasting stubs untouched.
7. Targeted EFDI suite green (0 failures).
8. No hardcoded secrets in D1 source.

## 3. Verification

Independent no-trust verification:
`certification/forecasting/verifiers/EFDI_D1_independent_verification.py`
(V1–V9), writing
`EFDI_D1_independent_verification_output.json`. Verdict PASS requires all
mandatory checks pass and exit code 0.
