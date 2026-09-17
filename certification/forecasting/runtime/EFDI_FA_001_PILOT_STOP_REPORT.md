# EFDI-FA-001 — STOP Report (Phase 2: Pilot #001)

**artifact:** `EFDI_FA_001_PILOT_STOP_REPORT.md`
**recorded_at:** 2026-09-13T02:10:00Z
**authorization:** `EFDI_FA_001_PILOT_AUTHORIZATION.yaml` (signed, AUTHORIZED)

---

## STATUS

**PASS — harness execution validated (Q1). Predictive-information claim: NONE
(Q2), by pre-registered minimum-sample rule.**

Forecast #001 was issued, resolved, scored, and ledger-verified end-to-end with
zero leakage, zero rehearse, zero retroactive edit, and zero external action.

---

## DUAL QUESTIONS (answered separately, per authorization)

| Question | Answer | Basis |
|----------|--------|-------|
| Q1: did the harness execute correctly? | **PASS** | window pre-registration, freeze-before-window, cutoff discipline, resolution after window end from pre-declared sources, append-only ledger, hash chain + immutable_hash_full verify, Brier/log-loss scoring, baselines scored on frozen evidence |
| Q2: predictive information beyond baselines? | **NOT ESTABLISHED** | N=2 resolved forecasts. Pilot minimum sample = 10 (BASELINE_DEFINITIONS). No inference permitted. Even a 100% pilot hit rate proves nothing (dominanceRule D2: directional accuracy alone is insufficient). |

---

## FORECASTS ISSUED (both frozen BEFORE window start)

### EFDI-001-001 — BTC/USD 5m (window [00:55Z → 01:00Z])

| Field | Value |
|-------|-------|
| issued_at / data_cutoff | 00:52:30Z / 00:51:48.989Z (T0-ε) |
| probabilities | UP 0.505 / DOWN 0.495 |
| predictability_estimate | 0.10 (low) |
| B1 base rate used | 0.50 |
| resolved | **UP** — CoinGecko 77,219 (open) → 77,253 (close), Δ +0.044% |
| Brier | 0.2450 |
| log_loss | 0.6832 |
| calibration bucket | P(realized)=0.505 ∈ [0.50, 0.60) |

Baselines (same frozen evidence): B0 coin 0.2500 / 0.6931 ● B1 base rate 0.2500 /
0.6931 ● B2 persistence (predicted DOWN) 1.0000 / INF ● B3 simple-stat 0.2500 /
0.6931 ● B4 Polymarket **NOT_CAPTURED** (never estimated retroactively) ● B5 single
model 0.2450 / 0.6832 ● B6 issued 0.2450 / 0.6832.

Pilot note: B6 − B1 Brier delta = −0.0050 on a single draw: within sampling band,
not evidence.

### EFDI-001-002 — Nairobi precipitation 60m (window [01:00Z → 02:00Z])

| Field | Value |
|-------|-------|
| issued_at / data_cutoff | 00:52:30Z / 00:51:48.989Z |
| probabilities | YES 0.10 / NO 0.90 |
| predictability_estimate | 0.55 (moderate) |
| B1 base rate used | 0.15 |
| resolved | **NO** — HKJK METAR present weather, no precip codes (BKN016, NOSIG) |
| Brier | 0.0100 |
| log_loss | 0.1054 |
| calibration bucket | P(realized)=0.90 ∈ [0.90, 1.00) |

Baselines: B0 coin 0.2500 / 0.6931 ● B1 climo→coin approx 0.2500 / 0.6931 ● B2
persistence (previous window 0.0 mm → NO, P=0.99) 0.0001 / 0.0101 ● B3 simple-stat
0.2500 / 0.6931 ● B4 weather service (P(YES)≈0.11 at cutoff) 0.0121 / 0.1165 ● B5
single model 0.0100 / 0.1054 ● B6 issued 0.0100 / 0.1054.

Pilot note: B6 scored near-domain-benchmark (B4) and was BEATEN by persistence
(B2: impossible to beat the dry default on a single dry day). Any claim of
weather skill from this leg is void by dominanceRule D1.

---

## HARNESS-VALIDATION CHECKS (Q1 evidence)

1. **Window pre-registration**: series config frozen before issuance; windows
   future-dated; resolution rules + sources + fallbacks declared in advance.
2. **Freeze-before-window**: both legs issued 00:52:30Z, windows began 00:55Z
   and 01:00Z. No outcome data touched before `issued_at`.
3. **Data cutoff**: data_cutoff identical across legs; evidence inventory
   written before probabilities; no post-cutoff input used (B4 Polymarket
   recorded NOT_CAPTURED rather than backfilled).
4. **Resolution discipline**: BTC resolved after 01:00Z from CoinGecko (pread
   source, fallback unused); Nairobi resolved after 02:00Z from HKJK METAR
   (pread source). No re-interpretation, no soft landing.
5. **Append-only ledger**: 6 granules: genesis, metadata (series config +
   evidence inventory hashes), 2× forecast_issued, 2× forecast_resolved.
   Nothing rewritten.
6. **VERIFY algorithm**: PASS — prev_hash chain recomputed on every line;
   both immutable_hash_full recomputed from `issued forecast ++ resolution
   block`; canonical reproducibility spot-checked for both forecasts
   (byte-identical reconstruction on resolve).
7. **Scoring**: Brier/log_loss/directional per METRIC_SCHEMA; baselines B0-B6
   per BASELINE_DEFINITIONS on the same frozen evidence set.
8. **No external action**: zero trades, zero orders, zero interventions; the
   ledger is a measurement record only.
9. **No premature conclusion**: this report does NOT characterize Tiannara as
   calibrated, accurate, or a superforecaster. It exercises the machinery.

---

## PENDING / DEFERRED

- **Nairobi outcome reconciliation** (RESOLUTION_PROTOCOL §6): independent
  operator re-read of the same HKJK METAR for the window — executable now by
  the Council (no further deposit needed).
- **Predictability meta-score**: 1/2 legs aligned (BTC low-predictability claim
  matched a near-coin result); requires series accumulation before evaluation.

---

## SOURCE CONTROL & SCOPE

```
commits:      0
pushes:       0
trades/orders:0
autonomous decisions: 0
live forecasts: 2 (both resolved; no unresolvable legs)
```

Runtime artifacts (all under `certification/forecasting/runtime/`):
`EFDI_FA_001_PILOT_SERIES_CONFIG.yaml`,
`EFDI_FA_001_EVIDENCE_INVENTORY_PILOT.json`,
`EFDI_FA_001_FORECAST_LEDGER.jsonl`. No changes outside
`certification/forecasting/`.

---

## COUNCIL DECISION HANDOFF

Per the authorization boundary: **completing #001 does NOT authorize #002 or a
larger series.** The Council must decide, from this STOP report, whether to:

- **A) approve Harness-Validation Series #002–#010** (10 forecasts, single
  batch, pre-registered as a new series), or
- **B) revise pilot configuration** before continuing, or
- **C) stop — audit the harness without further live windows.**

Suggested sequence for A (pre-registered at series level, nothing changing
mid-series):

```
#002-#010  HARNESS-VALIDATION SERIES (pilot-stage min sample 10)
         ↓
CALIBRATION BATCH (100+; per-domain 50)      → initial calibration claims only
         ↓
EMPIRICAL BENCHMARK (500+; per-domain 100)   → serious comparison vs B0-B4
         ↓
EFDI CERTIFICATION DECISION (closed set only)
```

Do not proceed without the Council's explicit series approval.

```
authorization_id:   EFDI_FA_001_PILOT
status:             PASS (harness, Q1) | NOT ESTABLISHED (Q2)
forecast_001_issued: true (resolved, scored, verified)
no_rollover:        true  // #002 and beyond require new authorization
signature:          EFDI_FA_001_PILOT_REPORTED