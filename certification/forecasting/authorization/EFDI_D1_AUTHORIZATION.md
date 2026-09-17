# EFDI D1 — Authorization Record

**Gate:** EFDI-D1
**Phase:** Signal Intelligence
**Namespace:** `Tiannara.Forecasting.*`

## 1. Authorization

- **Status:** GRANTED
- **Kind:** IMPLEMENT_D1
- **Operator:** maintainer
- **Scope:** Create the foundational D1 contract layer under `Tiannara.Forecasting.*`
- **Date:** 2026-09-01

## 2. Authorized actions

| Action | Permitted | Notes |
|--------|-----------|-------|
| Create `Signal`, `SignalRegistry`, `SignalQuality`, `SignalValue` | Yes | D1 modules |
| Create `Provenance`, `Correlation` | Yes | D1 helpers |
| Create `Contracts` (structs only) | Yes | Data model for D2–D6 |
| Create `Adapters.*` behaviours | Yes | Callback-only boundaries |
| Create `Tiannara.Forecasting` facade | Yes | Root API |
| Config keys (`:efdi_quality_weights`, `efdi_persist_signals`) | Yes | D1 config |
| Modify existing `Tiannara.Forecasting.{ForecastAuditor, FutureSimulator, StrategicPlanner, DecisionArchive}` stubs | **FORBIDDEN** | Used by `run_forecasting_gauntlet.exs` |

## 3. Forbidden actions

- Implementing forecasting, calibration, decision, counterfactual, noise, or
  forecast memory logic (D2–D6).
- Forking/duplicating existing evidence, provenance, research, CIS,
  world-model, or mathematics infrastructure.
- Rewriting historical signal records.
- Fabricating predictive value / information gain where no outcome exists.
- Committing secrets or credentials.

## 4. Honesty covenant

- `UNKNOWN` is valid and distinct from `0.0`.
- Forecasts (future phases) must be falsifiable.
- Historical records are never overwritten.
- Degradation is reported (`health/0`), never hidden.

## 5. Sign-off

Verification of this authorization's constraints is performed independently by
`EFDI_D1_independent_verification.py` (V1–V9), which reports its own findings
and exits non-zero on any violation.
