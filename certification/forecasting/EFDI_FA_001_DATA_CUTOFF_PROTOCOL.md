# EFDI-FA-001 — Data-Cutoff Protocol

**artifact:** `EFDI_FA_001_DATA_CUTOFF_PROTOCOL.md`
**status:** FROZEN 2026-09-13
**governing contract:** `EFDI_FA_001_AUDIT_CONTRACT`
**schema:** `EFDI_FA_001_FORECAST_SCHEMA.yaml` (data_cutoff, issued_at, evidence_inventory)

---

## 1. Purpose

Guarantee that no forecast uses information dated after its `data_cutoff`.
Violations are **severe epistemic contamination** and invalidate the affected
forecast (and, if systematic, the batch).

---

## 2. Definitions (frozen)

```
data_cutoff  : the ISO-8601 UTC instant after which NO information may be used
issued_at    : the instant the forecast record is frozen (issued_at > data_cutoff)
resolution_time : planned conclusion instant of the outcome window
```

- For live synced forecasts (BTC, weather), `data_cutoff = T0 - epsilon`,
  `issued_at = T0 - epsilon'` with epsilon/epsilon' small, fixed, and recorded.
- The frozen dataset = everything with observation time `<= data_cutoff`.
- The "freeze" is **material**: the full evidence set that touched the forecast
  is listed in `evidence_inventory` and stored with the record.

---

## 3. Freeze procedure (mandatory, in order)

1. Pre-register the window `[T0, T0+horizon]` and the resolution rule (see
   `REAL_WORLD_RESOLUTION_PROTOCOL`).
2. At `data_cutoff`, snapshot all inputs:
   - crypto: price, bid/ask if available, volume, recent returns,
     5m/15m/1h/4h/1d realized volatility, order-book imbalance if available,
     BTC dominance if available, market-wide crypto movement, major correlated
     assets, recent news (timestamps), funding/open-interest if available.
   - weather: current conditions, recent satellite/radar, temperature,
     humidity, pressure, wind, cloud cover, time, season, location.
3. Freeze the dataset: write `evidence_inventory` (identifiers/hashes) into the
   record BEFORE the probabilities are produced.
4. Generate the forecast FROM THE FROZEN SET ONLY.
5. Freeze the record (`issued_at`), hash it, append to the ledger.

Any input whose observation time cannot be verified `<= data_cutoff` is
EXCLUDED and flagged in `unknowns`.

---

## 4. Prohibitions (non-exhaustive)

- No peeking at the outcome window (chart/stream/forecast-service for the
  SAME window) at any point before `issued_at`.
- No model/signal refit on data after `data_cutoff`.
- No imputation from future values.
- No "as of" claims that quietly use a later timestamp.
- No aggregation windows straddling `data_cutoff` unless the straddle is
  declared and the value cannot otherwise be obtained (rare; recorded as an
  assumption).

---

## 5. Leakage guards (beyond live settings)

| Guard | Rule |
|-------|------|
| Temporal partitioning | Synthetic test data is split train/validate/test WITH temporal ordering; test set is access-locked until prediction is frozen (TEST_MATRIX). |
| Feature future lookup ban | No feature may be defined using values from after `data_cutoff`. |
| Train-on-all safe lists | Where history is legitimately used (B1 base rate), the reference window is FIXED before the series begins (BASELINE_DEFINITIONS §B1). |
| Reproducibility spot check | Ledger VERIFY recomputes a 10% sample of forecasts from frozen inputs byte-for-byte (FORECAST_LEDGER §verify). |
| Hindsight check | A subset of synthetic problems uses a two-stage design: forecasts at T0 (only T0 info) and at T1 (T0+T1 info); the T0 forecast must be untouched by T1 (efdi.md §33). |

---

## 6. Failure handling

A data-cutoff violation is classified:

- forecast-level: `F-07` (data leakage) — quarantine the forecast from scoring;
  record the leak; do NOT delete the record (audit).
- systemic: if any violation is found in a batch, the batch cannot claim any
  out-of-sample result until the cause is fixed and the batch re-run from the
  last clean anchor.

---

## 7. Dual-domain pilot note (Forecast #001)

The pilot runs one BTC 5-minute window and one Nairobi 60-minute window.

- BTC: only information observable at `T0 - epsilon`; the Polymarket implied
  probability at cutoff is a legitimate B4 input (it is a frozen market price,
  itself a realtime occurrence at cutoff).
- Nairobi: only information observable before the 60-min window starts; the
  weather-service forecast for the SAME window is B4, never Tiannara's answer.