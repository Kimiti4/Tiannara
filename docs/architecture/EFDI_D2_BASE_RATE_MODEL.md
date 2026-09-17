# EFDI D2 — Base-Rate Model

## 1. Purpose

A base rate gives the historical frequency of an outcome within a **reference
class**. D2 uses base rates to form priors — and records them explicitly so they
can be compared against current evidence without either being privileged.

## 2. Contract (`Contracts.BaseRate`)

| Field | Meaning |
|-------|---------|
| `reference_class` | the comparison class (required) |
| `historical_frequency` | `number \| :unknown` (absent = `:unknown`, **never** `0.0`) |
| `sample_size` | size of the reference sample |
| `selection_conditions` | how the class was selected |
| `regime_conditions` | regime under which the rate holds |
| `confidence` | rate confidence |
| `source` | provenance |
| `data_quality` | D2: quality of the reference data |
| `base_rate_uncertainty` | D2: explicit uncertainty of the rate |

## 3. Integrity rules (`BaseRateEngine.validate/1`)

- missing `reference_class` → `:missing_reference_class`
- non-numeric, non-`:unknown` frequency → `:invalid_historical_frequency`
- frequency outside `[0,1]` → `:frequency_out_of_bounds`
- `:unknown` passed through as valid (honest absence of data)

## 4. Prior construction

`ForecastEngine.base_rate_prior/2`:

- binary outcome set + numeric frequency → `{[f, 1−f], :base_rate}`
- ternary+ set + binary base rate → `{:unknown, :base_rate_outcome_mismatch}`
- `:unknown`/absent frequency → `{:unknown, :base_rate_unavailable}`

A binary base rate is **never force-mapped** onto a non-binary outcome set — that
would be fabrication.

## 5. Compare (no privileging)

`BaseRateEngine.compare/2` returns base rate and current-interim evidence side by
side with quality and uncertainty — the caller decides. D2 does not auto-boost
either the prior or fresh evidence.