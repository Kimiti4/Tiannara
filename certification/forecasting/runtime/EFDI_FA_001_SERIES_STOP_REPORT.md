# EFDI-FA-001 — STOP Report (Phase 3: Harness-Validation Series #002–#010)

**artifact:** `EFDI_FA_001_SERIES_STOP_REPORT.md`
**recorded_at:** 2026-09-13T18:28:00Z
**authorization:** `EFDI_FA_001_SERIES_002_010_AUTHORIZATION.yaml` (measurement-only)

---

## STATUS

**PASS — harness executed end-to-end at series scale (Q1, N=18 legs + 2 pilot
legs). Predictive-information claim: NONE (Q2), per pre-registered
minimum-sample rule (BASELINE_DEFINITIONS `minimum_sample`: pilot 10 = harness
verification only; calibration claims require >= 100).**

Series #002–#010: 18 forecasts (9× BTC 5m + 9× Nairobi 60m), all issued frozen
before window start, all resolved from pre-declared sources, all scored vs
B0–B6, all hash-chained, ledger VERIFY PASS (43 lines). Zero trades, zero
pushes, zero commits.

---

## DUAL QUESTIONS (answered separately)

| Question | Answer | Basis |
|----------|--------|-------|
| Q1: did the harness execute correctly at series scale? | **PASS** | 18 legs issued via the frozen model rule from one cutoff snapshot; F-05 leak guard held (final issuance 06:46:51Z, earliest T0 06:50Z); per-leg resolution strictly after window close using the pre-declared reader; 18 resolution granules appended and hash-chained; VERIFY PASS on the full 43-line ledger |
| Q2: predictive information beyond baselines? | **NOT ESTABLISHED** | N=20 resolved legs total (2 pilot + 18 series). Below the 100-forecast calibration-batch minimum; no inference permitted. Even the NBO all-NO deck is a single weather regime (region-wide dry day); dominance rule D4 caps any NBO statement as regime-limited, and D1 is not met. |

---

## SERIES CONFIG **must | confirmed | FROZEN_BEFORE_ISSUE**

| Element | Frozen value |
|---------|--------------|
| series config hash (in ledger META-0002) | `95fddceb537dc0d964ccf097167855f4ea483fbb7f1a8d37760863cf5772367b` |
| data_cutoff (single, all 18 legs) | `2026-09-13T06:08:00.000Z` |
| model rule BTC | P(UP)=0.505 / P(DOWN)=0.495 (frozen neutral tilt, same as pilot) |
| model rule NBO | P(YES)=0.15+0.5*(ppb-0.15), clamp [0.02,0.98]; B1_NBO=0.15 |
| B4 BTC | Polymarket — recorded **NOT_CAPTURED**, never estimated retroactively |
| B4 NBO | open-meteo hourly precip probability for the window at cutoff (7–16Z probs 5..78%) |
| issue discipline | each leg written to ledger strictly BEFORE its T0; hard-fail if any window open (F-05) |

---

## ISSUED → RESOLVED (18 series legs)

### BTC 5m (windows 06:50→06:55 … 07:30→07:35Z)

| Leg | Outcome | delta% | Brier | log_loss | Cal bucket |
|-----|---------|--------|-------|----------|------------|
| 002 | DOWN | -0.058 | 0.2550 | 0.7032 | P=0.495 |
| 003 | DOWN | -0.185 | 0.2550 | 0.7032 | P=0.495 |
| 004 | UP | +0.078 | 0.2450 | 0.6832 | P=0.505 |
| 005 | UP | +0.036 | 0.2450 | 0.6832 | P=0.505 |
| 006 | UP | +0.008 | 0.2450 | 0.6832 | P=0.505 |
| 007 | UP | 0 (>= rule) | 0.2450 | 0.6832 | P=0.505 |
| 008 | DOWN | -0.003 | 0.2550 | 0.7032 | P=0.495 |
| 009 | DOWN | -0.031 | 0.2550 | 0.7032 | P=0.495 |
| 010 | DOWN | -0.022 | 0.2550 | 0.7032 | P=0.495 |

Resolution source: CoinGecko simple price via 10 captured boundary snapshots
(B0650–B0735), one pre-declared reader per boundary.

### Nairobi 60m (windows 07:00→08:00 … 15:00→16:00Z) — ALL NO

| Leg | P(YES) | Outcome | Brier | log_loss | Cal bucket |
|-----|--------|---------|-------|----------|------------|
| 002 | 0.100 | NO | 0.0100 | 0.1054 | P(realized)=0.90 |
| 003 | 0.135 | NO | 0.0182 | 0.1450 | P=0.865 |
| 004 | 0.165 | NO | 0.0272 | 0.1803 | P=0.835 |
| 005 | 0.185 | NO | 0.0342 | 0.2046 | P=0.815 |
| 006 | 0.205 | NO | 0.0420 | 0.2294 | P=0.795 |
| 007 | 0.240 | NO | 0.0576 | 0.2744 | P=0.760 |
| 008 | 0.315 | NO | 0.0992 | 0.3783 | P=0.685 |
| 009 | 0.410 | NO | 0.1681 | 0.5276 | P=0.590 |
| 010 | 0.465 | NO | 0.2162 | 0.6255 | P=0.535 |

Resolution source: HKJK METAR present-weather scan over `[T0-30m, T0+90m]`,
N>=4 in-window observations per leg, all `BKN/SCT NOSIG`, no precip codes;
METAR counts 4–5 per leg.

---

## SERIES SCOREBOARD — all resolved legs, out of sample

### All 20 resolved legs (2 pilot + 18 series)

| Baseline | scored N | mean Brier | mean log_loss | dir hits | dir acc |
|----------|----------|------------|---------------|----------|---------|
| B0 coin | 20 | 0.25000 | 0.69315 | 0 | 0.00 |
| B1 base rate | 20 | 0.14762 | 0.45436 | 9 | 0.45 |
| B2 persistence | 20 | 0.16255 | **INF(3)** (p=1.0 hard, 3 misses) | 16 | 0.80 |
| B3 simple-stat | 20 | 0.38200 | 1.08781 | 3 | 0.15 |
| B4 domain bench | 10 (NBO only; BTC NOT_CAPTURED) | 0.15740 | 0.47209 | 8 | 0.80 |
| **B5 single model** | 20 | 0.15916 | 0.48540 | 15 | 0.75 |
| **B6 issued (audit subject)** | 20 | 0.15916 | 0.48540 | 15 | 0.75 |

### BTC domain (10 legs: pilot 001 + 9 series)

| Baseline | mean Brier | mean log_loss | dir acc |
|----------|------------|---------------|---------|
| B0/B1/B3 | 0.2500 | 0.6932 | 0.00 |
| B2 persistence | 0.3250 | INF(3) | 0.60 |
| B5/B6 | 0.2500 | 0.6932 | 0.50 |

BTC B6 ≈ coin, as designed for the 0.10-predictability regime; does NOT beat B2
persistence's directional 0.60 (rule D2: directional alone insufficient; B6
does not dominate joint Brier+log_loss+ECE).

### Nairobi domain (10 legs: pilot 002 + 9 series)

| Baseline | mean Brier | mean log_loss | dir acc |
|----------|------------|---------------|---------|
| B0 coin | 0.2500 | 0.6932 | 0.00 |
| B1 climo P(YES)=0.15 | 0.0453 | 0.2156 | 0.90 |
| B2 persistence (dry) | 0.0001 | 0.0101 | 1.00 |
| B3 simple-stat (mm≥0.1 threshold) | 0.5140 | 1.4825 | 0.30 |
| B4 open-meteo prob | 0.1574 | 0.4721 | 0.80 |
| B5/B6 issued | 0.0683 | 0.2776 | 1.00 |

NBO: B6 (0.0683) BEATEN by B2 persistence (0.0001) and B1 climatology (0.0453)
on Brier, and by B2 on log_loss. So B6 does not dominate B0–B4; rule D1 fails.
On a region-wide dry day, persistence and climatology are near-perfect and the
issued forecast (a shrink toward B1) correctly leans NO but lands further from
certainty than the dry baselines — the honest outcome for a measurement-only
day with no edge.

## CALIBRATION / PREDICTABILITY META

- BTC: predictability pre-set 0.10; realized B6 mean Brier 0.250 ≈ coin —
  consistent with a no-edge regime, not evidence of calibration failure.
- NBO: predictability pre-set 0.50; realized B6 mean Brier 0.068 on an all-NO
  single-regime deck is a lucky-regime draw; ECE/calibration via buckets is
  deferred (n<20 per bucket — flagged "insufficient" per BASELINE_DEFINITIONS).
- No B4 for BTC; no ECE across <20 legs; no significance test run (rule:
  0.05 two-sided, sample < minimum).

---

## HARNESS-VALIDATION CHECKS (Q1 evidence)

1. **Pre-registration executed**: sampling plan + model rule + B-locks frozen
   in `EFDI_FA_001_SERIES_CONFIG.yaml` before first issuance; config hash
   anchored into the ledger metadata granule.
2. **Freeze-before-window enforced**: two earlier issuance attempts pierced
   their T0 (F-05) and were detected by the script's hard guard; ledger was
   truncated to the last clean anchor (pilot block) and windows re-dated
   strictly forward. Final issuance 06:46:51.962Z, earliest T0 06:50Z.
3. **Single cutoff, single evidence set**: `data_cutoff` 06:08:00Z used for all
   18 legs; evidence inventory written before probabilities; B4 NOT_CAPTURED
   recorded, never backfilled.
4. **Resolution discipline**: BTC via pre-declared CoinGecko boundary
   snapshots, only after each window closed; NBO via HKJK METAR only after
   window + scan horizon, only the pre-declared reader. No re-resolution to
   "fix" an unfavorable outcome.
5. **Append-only ledger**: final state 43 lines (6 pilot + 1 metadata + 18
   issued + 18 resolved [9 BTC + 9 NBO]). Loop-internal governance: all
   truncations in this session occurred BEFORE the final chain settled, were
   recorded in-process, and the settled chain re-verified from genesis to tail.
6. **VERIFY**: PASS — `prev_hash` recomputed per line; `immutable_hash_full`
   recomputed from canonical issued-forecast ++ resolution-block for all 18
   resolved grains.
7. **Scoring**: Brier/log_loss/directional per METRIC_SCHEMA; B0–B6 per
   BASELINE_DEFINITIONS from the same frozen evidence base.
8. **No external action**: 0 trades, 0 orders, 0 interventions.
9. **No premature conclusion**: none of the above asserts calibration, skill,
   or superiority. It exercises the machinery.

---

## PENDING / DEFERRED

- **Calibration batch** (>= 100 forecasts) with per-bucket ECE, Wilson CIs, and
  Diebold-Mariano pairwise comparisons vs B0–B4.
- **BTC B4**: fetch/record Polymarket implied probability at cutoff for at
  least 50 legs before B4 appears on the BTC scoreboard.
- **NBO multi-regime accumulation**: the 10-leg all-NO deck is one dry regime;
  a mixed-regime sample is required before any NBO calibration statement.

---

## SOURCE CONTROL & SCOPE

```
commits:       0
pushes:        0
trades/orders: 0
autonomous decisions: 0
live forecasts: 18 issued, 18 resolved, 0 unresolvable
```

Runtime artifacts (all under `certification/forecasting/runtime/`):
`EFDI_FA_001_SERIES_CONFIG.yaml`, `EFDI_FA_001_EVIDENCE_INVENTORY_SERIES.json`,
`EFDI_FA_001_SERIES_BOUNDARY_SNAPSHOTS.jsonl`, `EFDI_FA_001_FORECAST_LEDGER.jsonl`
plus pilot artifacts. No changes outside `certification/forecasting/`.

---

## COUNCIL DECISION HANDOFF

| Option | Meaning |
|--------|---------|
| A) approve CALIBRATION BATCH (>=100, per-domain 50) | initial calibration claims only |
| B) revise config (nodes, baselines, window structure) | new pre-registered series required |
| C) stop measurement | audit the harness without further live windows |

Do not proceed to EMPIRICAL BENCHMARK (500) or any certified claim without a
Council decision and a new authorization.

```
authorization_id:  EFDI_FA_001_SERIES_002_010
status:            PASS (harness, Q1) | NOT ESTABLISHED (Q2)
series_002_010:    issued 18, resolved 18, verified 43-line chain
no_rollover:       true  // calibration batch requires new authorization
signature:         EFDI_FA_001_SERIES_REPORTED
```

---

## COUNCIL ACCEPTANCE ADDENDUM

**accepted_at:** 2026-09-13T18:57:22Z
**decision:** Council accepts the STOP report as closed. The configuration is
NOT revised on the basis of measured outcomes; the frozen evidence base is
retained un-contaminated for any future calibration batch.

**Certified state on acceptance (course of record):**

```text
EFDI-FA-001 Phase 0            PASS / FROZEN
Pilot #001                     PASS / RESOLVED
Series #002–#010               PASS / RESOLVED
Q1 Harness integrity           ESTABLISHED
Q2 Predictive information      NOT ESTABLISHED
Calibration batch              NOT AUTHORIZED
Empirical benchmark (N≥500)    NOT AUTHORIZED
Configuration revision         NOT AUTHORIZED
Rollover                       PROHIBITED
```

**Governance boundary reaffirmed:** 18 live forecasts issued, 18 resolved,
0 unresolvable; zero trades/orders, zero autonomous decisions, zero commits,
zero pushes. Nothing executes pending next authorization.

**Next legitimate action:** one new Council decision + fresh
`authorization_id` choosing exactly one of:
- **A)** authorize the ≥100 calibration batch (per-domain 50), or
- **B)** revise the experimental configuration and preregister a new series, or
- **C)** stop live measurement and retain the current evidence.

**acceptance_signature:** EFDI_FA_001_SERIES_ACCEPTED