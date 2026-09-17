# EFDI-FA-001 CALIBRATION BATCH AUTHORIZATION

**issued_for:** EFDI-FA-001 (Forecasting & Foresight Intelligence — Capability Assessment)
**recorded_at:** 2026-09-14T22:09:19.962Z
**status:** ISSUED — MEASUREMENT ONLY

## COUNCIL DECISION (course of record)

| Option | Disposition | Reason |
|--------|-------------|--------|
| A — Calibration batch | **SELECT** | Measurement-only; directly supplies validation evidence |
| B — Config revision | **REJECT for now** | Would alter the frozen forecasting configuration and contaminate the evidence/ledger |
| C — Stop | Valid fallback | Honest terminal state if A cannot be executed under the authorization/evidence constraints |

A measures predictive performance; `forecast.md` strengthens the evidentiary
machinery used to decide whether that performance deserves trust. This batch
does **not** authorizes any change to that machinery.

## AUTHORIZATION SCOPE

> **Authorization scope: measurement only. No configuration modification,
> model replacement, promotion, certification, or production deployment is
> authorized by this batch.**

Binding constraints (each violates the authorization if not honored):

1. Current configuration preserved exactly (`EFDI_FA_001_SERIES_CONFIG.yaml`,
   SHA-256 `95fddceb537dc0d964ccf097167855f4ea483fbb7f1a8d37760863cf5772367b`).
2. Existing forecast ledger (43-line hash-chained series, VERIFY PASS) and its
   cutoff discipline preserved; no historical granule is amended.
3. Batch is pre-authorized/pre-registered, then generated; forecasts are frozen
   to the ledger strictly before each window T0 (F-05 forecast-leak guard).
4. Forecasts resolved only after their defined horizons, via the pre-declared
   resolution sources.
5. Minimum computed metrics per domain and pooled:
   Brier score, log loss, calibration/reliability, baseline comparison,
   sample count, abstentions.
6. Uncertainty/limitations reported explicitly; no significance is
   manufactured from small N. N=20 series is context, not a calibration claim.
7. Every forecast and outcome preserved with provenance (ledger + evidence
   inventory + boundary snapshots).
8. **No model/configuration changes.**
9. **No promotion or certification decision.**
10. **No commits or pushes.**

Failure disposition: if the batch shows poor performance, that is an
observation for the next hypothesis/configuration cycle — **not** permission
to tune the configuration during the experiment. A must not silently become B.

## BASELINE REFERENCE

The frozen series scored B6 vs B0–B4. This batch continues the same baseline
definitions and dominance rules; B6 may be recalibrated for reporting only, as
a measurement, and must not imply config value revision.

## FRESH AUTHORIZATION

```text
authorization_id:  EFDI_FA_001_CAL_BATCH_2026-09-14_A01
status:            ISSUED — measurement only
scope:             calibration batch (>=100, per-domain 50), pre-authorized
config:            FROZEN (hash 95fddceb...67b, unmodified)
rollover:          PROHIBITED
commits/pushes:    0
signature:         EFDI_FA_001_CALIBRATION_AUTHORIZED
```

**Ratification required before execution:** the Council ratifies this issued
authorization_id with a one-line confirmation; only then is the batch
generated.