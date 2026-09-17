# EFDI-FA-001 — Noise Protocol

**artifact:** `EFDI_FA_001_NOISE_PROTOCOL.md`
**status:** FROZEN 2026-09-13
**governing contract:** `EFDI_FA_001_AUDIT_CONTRACT`
**metrics:** `EFDI_FA_001_METRIC_SCHEMA.yaml` (model_disagreement, sharpness)

---

## 1. Purpose

Quantify Tiannara's **forecast noise profile** — the irreducible variability of
its own predictions — and separate BIAS (systematic offset) from NOISE
(random scatter) so that apparent skill is not a scheduling/order/presentation
artifact.

---

## 2. Forecast Noise Profile (efdi.md §26)

Run, on the SAME frozen evidence:

| Experiment | Procedure | Output |
|------------|-----------|--------|
| Agent variance | 5 independent forecast paths (A..E), identical information | std/range of predicted probabilities across agents |
| Temporal instability | Repeat the identical experiment later | change in probabilities |
| Evidence-order sensitivity | Same evidence, shuffled order | max |delta P| |
| Presentation sensitivity | Same evidence, minimal wording changes | max |delta P| |

Severity thresholds (pre-registered, per forecast):

- `noise_band = max(agent_std, temporal_delta, order_delta, wording_delta)`
- If `noise_band > 0.15` on binary probabilities, the forecast's claimed
  precision above that band is NOT credible and is flagged in scoring.

Result: a series-level distribution of noise_band (mean, p90).

---

## 3. Bias vs Noise separation (efdi.md §27)

Two identical synthetic environments (known ground truth):

- **Environment A (bias):** every model consistently 10% too optimistic.
  Expect persistent systematic residual with LOW error variance.
- **Environment B (noise):** models vary randomly around the correct value.
  Expect HIGH variance, near-zero mean residual.

Tiannara must classify each environment as bias vs noise using its own output
residuals (mean vs spread), and the classification is scored. Misclassification
is an audit failure signal for that behavior class.

---

## 4. Noise in the live series

- Per-forecast, always record `model_disagreement` (METRIC_SCHEMA). A series
  whose forecasts are low-noise but systematically miscalibrated is a BIAS
  story; one that is high-noise is a NOISE story; both are REQUIRED reporting.
- The NOISE_PROTOCOL never inflates the signal: a "confident" mode that
  compresses probability spread without calibration evidence is scored as
  sharpness WITHOUT calibration (penalized per METRIC_SCHEMA §sharpness).

---

## 5. Determinism vs noise

- With `random_seed` fixed, a forecast MUST reproduce exactly (FORECAST_LEDGER
  §verify). Non-determinism above the seed is an F-16 defect.
- The noise profile measured in §2 uses DIFFERENT seeds/orders/wording — that
  variability is legitimate and is exactly what the profile quantifies.

---

## 6. Outputs

- `EFDI_FA_001_NOISE_REPORT.md`: full profile (agent/temporal/order/presentation
  tables), noise_band distribution, bias-vs-noise classification for the
  synthetic environments, live-series model_disagreement series and stats.