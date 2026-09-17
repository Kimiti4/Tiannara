# EFDI D2 — Calibration Model

## 1. Purpose

Calibration measures whether the distribution a forecast declares matches the
outcome frequencies reality delivers. It is the **only** source of earned
confidence — D2 never claims accuracy before sufficient outcome data exists.

## 2. Metrics

| Metric | Definition | D2 function |
|--------|-----------|-------------|
| Brier score | `(p − observed)²` | `Calibration.brier/2` |
| Log loss | `−ln(p)` at observed outcome | `Calibration.log_loss/2` |
| Mean Brier | mean over `{forecast, observed}` pairs | `Calibration.mean_brier/1` |
| Mean log loss | mean over pairs | `Calibration.mean_log_loss/1` |
| Calibration error | mean `\|p − observed_freq\|` over bins | `Calibration.calibration_error/1` |
| Reliability | bin-conditional observed frequency | `Calibration.reliability/1` |
| Resolution | variance of observed frequencies | `Calibration.resolution/1` |
| Sharpness | − Shannon entropy (via `InformationTheory`) | `Calibration.sharpness/1` |

All numeric work composes existing Tiannara math — no parallel probability system.

## 3. INSUFFICIENT_DATA vs POOR_CALIBRATION

```
reliability_level(0..4)  → :insufficient   (cannot judge — do not conclude poor)
reliability_level(≥5)    → :adequate       (only then may poor/adequate be claimed)
```

`Calibration.reliability/1` never returns a "poor" verdict off a single-point
sample. The two conditions are distinct by construction; a 5-sample threshold
(`@min_sample`) marks the boundary.

## 4. Scoring integrity (no hidden recalibration)

- A score records `method` + `value` + `sample_size`; attribution is exact.
- Extreme probabilities (0/1) yield `:unknown` log loss (undefined −ln) instead
  of an invented number.
- `:unknown` forecasts score as `sample_size: 0`, `value: :unknown` — never
  penalized as if they had a manufactured distribution.
- Vertions cannot be re-derived: a stored forecast is immutable, so the score
  computed today equals the score computed at evaluation time (attribution-safe).

## 5. Example

A 0.6 base-rate organism over a true 60/40 world converges to mean Brier ≈
`0.6·0.16 + 0.4·0.36 = 0.24` — strictly under a coin flip (0.25) and measured,
not presumed.