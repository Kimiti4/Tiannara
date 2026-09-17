# EFDI D2 — Forecast Model

## 1. Definition

A forecast is an **immutable, evidence-linked, explicitly uncertain probability
distribution over mutually exclusive outcomes**, produced at a point in time and
preserved so later evaluation can tell triumph from luck.

The `Contracts.Forecast` struct carries:

| Field | Meaning |
|-------|---------|
| `id` | immutable identity (new id per version) |
| `question`, `event`, `outcomes` | what is being forecast over |
| `horizon` | decision-relevant time window |
| `probabilities` | the distribution (normalized) or `:unknown` |
| `confidence` | separate, non-interchangeable quality-of-estimate |
| `base_rate_ref` | reference-class rate used as prior |
| `signal_refs`, `evidence_refs` | immutable evidence linkage |
| `model_ref` | which forecaster produced it (default: `:default`) |
| `assumptions`, `unknowns` | explicit conditionality |
| `context`, `regime` | regime the forecast is valid under |
| `provenance`, `lineage` | origin + ancestor history |
| `forecast_version` | monotonic version counter |
| `created_at` | forecast-time (hindsight baseline) |

## 2. Probability integrity

| Rule | Enforcement |
|------|-------------|
| Bounds | every value in `[0,1]`, finite (`Forecast.validate` → `:invalid_probabilities`) |
| Mutual exclusion | outcomes are a set; exactly one probability per outcome |
| Normalization | in-bounds inputs normalize to sum `1.0` at construction |
| Outcome-count match | `length(probabilities) == length(outcomes)` → else `:outcome_probability_mismatch` |
| UNKNOWN | `:unknown` is a value; never conflated with `0.0` or a fabricated uniform |

**Construction does not silently repair violations.** Out-of-bounds or non-finite
values are preserved through `new/1` and rejected by `validate/1` — the registered
forecast is provably clean.

## 3. Construction

`ForecastEngine.forecast/1`:

1. valid outcomes required (`:missing_outcomes` otherwise);
2. base rate resolved and validated (bounds check, `:unknown` when unavailable);
3. prior = base-rate frequency for binary sets, else honest `:unknown`;
4. prior source recorded (`:base_rate`, `:base_rate_unavailable`, `:no_base_rate`,
   `:base_rate_outcome_mismatch`);
5. `Forecast.new/1` normalizes and yields the immutable forecast.

## 4. Versioning

`Forecast.version/2` produces a new forecast:

- new `id`, `forecast_version + 1`, `created_at = now`;
- previous id prepended to `lineage`;
- history is never overwritten (`ForecastRegistry` re-registration is a no-op).

This yields the reconstruction: `version_1 ← version_2 ← version_3` via lineage.

## 5. UNKNOWN discipline

- A forecast with no base rate and no justifying evidence = `:unknown` distribution.
- Uniform is not the default; indifference must be *earned*, not assumed.
- The registry stores and validates such forecasts; calibration marks them
  unscorable (sample_size 0) rather than fabricating a score.