# EFDI Signal Quality

**Phase:** D1 — Signal Intelligence
**Module:** `Tiannara.Forecasting.SignalQuality`

## 1. Purpose

`SignalQuality.evaluate/2` scores how trustworthy and usable a signal is, across
seven orthogonal dimensions, returning a per-dimension score in `[0,1]` or
`:unknown`, plus a weighted aggregate.

## 2. Dimensions

| dimension | what it measures |
|-----------|------------------|
| `reliability` | source trust / stated reliability |
| `recency` | how fresh relative to a half-life decay |
| `completeness` | how many observation fields are populated |
| `measurement` | quality from the measurement-uncertainty error mode |
| `independence` | how independent from other signals (D1: from `independence` field) |
| `persistence` | whether the signal is expected to persist / stability |
| `validity` | temporal validity (0 if expired) |

## 3. Aggregate

The aggregate is a **weighted mean over assessed dimensions**:

```
aggregate = Σ(score_i × weight_i) / Σ(weight_i for assessed dimensions)
```

- Unknown dimensions are excluded from the numerator AND denominator.
- If no dimension is assessed, aggregate is `:unknown` (never `0.0`).
- Result is clamped to `[0,1]`.

## 4. Weights (config-driven)

Defaults (`config :tiannara, :efdi_quality_weights`):

| dimension | weight |
|-----------|--------|
| reliability | 0.30 |
| recency | 0.15 |
| completeness | 0.10 |
| measurement | 0.10 |
| independence | 0.15 |
| persistence | 0.10 |
| validity | 0.10 |

`recency_half_life_hours` (default 24) controls recency decay. Weights are
recalibrated by D5 (Noise) in later phases; D1 ships the canonical defaults.

## 5. Honesty rules

- Unmeasured → `:unknown`, distinct from measured-low `0.0`.
- A missing provenance field is not reported as low integrity; it is `:unknown`
  and `integrity?/1` returns `false` rather than asserting falsely.
- Expired signals are flagged invalid (validity `0`), not silently dropped.

## 6. Result struct

`%SignalQuality{}`:
`signal_id, reliability, recency, completeness, measurement, independence,
persistence, validity, aggregate_score, dimensions_assessed,
dimensions_unknown, assessed_at`
