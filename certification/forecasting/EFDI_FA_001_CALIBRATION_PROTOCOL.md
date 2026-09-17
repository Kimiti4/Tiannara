# EFDI-FA-001 — Calibration Protocol

**artifact:** `EFDI_FA_001_CALIBRATION_PROTOCOL.md`
**status:** FROZEN 2026-09-13
**governing contract:** `EFDI_FA_001_AUDIT_CONTRACT`
**metrics:** `EFDI_FA_001_METRIC_SCHEMA.yaml` (ec_e, mce, resolution)

---

## 1. Purpose

Verify that predicted probabilities match empirical outcome frequencies within
statistical uncertainty (reliability), and separate calibration quality from
sharpness and resolution. A forecast series is calibrated when, over many
resolved forecasts, events assigned probability ~p occur with frequency ~p.

---

## 2. Reliability construction

1. Take all resolved binary forecasts `(p_i, o_i)` from the evaluated batch.
2. Bucket by `p_i` in 0.10-width confidence bins:
   `[0.00,0.10), [0.10,0.20), ..., [0.90,1.00]`.
3. Per bucket: `n_b`, `conf_b = mean(p_i in bucket)`, `acc_b = mean(o_i in bucket)`.
4. Produce the **reliability diagram**: scatter `conf_b` vs `acc_b` with the
   identity line and 95% per-bucket Wilson intervals.
5. Report `ECE` and `MCE` per METRIC_SCHEMA.

Rules:

- A bucket with `n_b < 20` is reported but flagged `INSUFFICIENT` and excluded
  from any PASS claim.
- A system whose `ECE` is statistically indistinguishable from 0 (within
  bucket CIs) is **calibrated**; that is necessary but NOT sufficient for PASS
  (it must also add value over baselines, `BASELINE_DEFINITIONS §rule_D1`).
- The **overconfidence test** (efdi.md §36): given ambiguous evidence, expected
  output near the uncertainty center, NOT artificial certainty. Track
  confidence vs empirical correctness.

---

## 3. Statistical uncertainty

- Per-bucket interval: two-sided Wilson interval at 95% on `acc_b`.
- Whole-series ECE: compute ECE's sampling distribution via 10,000 block
  bootstrap resamples of the series; report 95% CI; PASS requires the CI to
  exclude a pre-registered unacceptable ECE (default 0.10) rather than the
  point estimate alone.
- Log-loss and Brier significance vs baselines: see BASELINE_DEFINITIONS
  §significance (paired DM-style test).

---

## 4. Calibration test battery (efdi.md §35)

If the series allows, construct 100 forecasts per probability level
(10%..90%) and verify actual frequencies lie within statistical uncertainty
of the declared level. Cost-limited series use a stratified subset of the
calibration batch instead; the stratification plan is pre-registered.

---

## 5. Recalibration policy (append-only)

Calibration failures NEVER modify a forecast.

- Correction is a NEW model version appended to the series
  (supersede/version idiom from EFDI D2), producing `calib_p` values
  derived from a FIXED historical subset (training calibration). 
- The audit reports BOTH the raw probabilities AND the recalibrated
  probabilities, scored separately. Only the RAW probabilities are the
  subject's claim; recalibration is a diagnosis tool, not retroactive fixing.
- Recalibration NEVER runs on the current out-of-sample batch; it is developed
  and frozen on earlier batches only (leakage guard).

---

## 6. Relationship to predictability estimate

Each forecast carries `predictability_estimate` (schema). After resolution,
the calibration protocol also checks when predictability was claimed HIGH vs
LOW and whether realized edge/calibration matched the claim. A system that
claims "nearly unpredictable" on genuinely noisy windows AND demonstrates it
out-of-sample is displaying signal intelligence; the PROTOCOL must reward the
claim/outcome agreement, not punish the abstention.

---

## 7. Outputs

- `EFDI_FA_001_CALIBRATION_REPORT.md` (runtime artifact): reliability diagram
  data, ECE/MCE + CI, per-bucket tables, overconfidence trace, recalibration
  diagnosis, predictability-claim agreement table.