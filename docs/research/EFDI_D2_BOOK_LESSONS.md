# EFDI D2 — Book Lessons

Design decisions informed by concrete prior failures and established practice.

## 1. Honest abstention over manufactured confidence

**Lesson from D1 ETS bug:** logical identity must be explicit at the point of
enforcement (the key), not carried as implicit metadata.

Applied: when a base rate is absent, D2 produces `probabilities: :unknown` with
honest uncertainty source. Uniform distributions are never *defaulted* to when no
evidence supports them — that would be fabrication. This matches calibration's
distinction between INSUFFICIENT_DATA and POOR_CALIBRATION: you cannot judge a
forecast that was never quantified.

## 2. Normalization is a *construction* concern, not a validity patch

**Lesson from Erlang `Constraints.normalize_to` behaviour:** the `else` clause
matches integer `0` exactly, not float `0.0`; all-zeros crash that clause.

Applied: `Forecast.new` pre-checks `sum > 0` before calling `normalize_to`. The
all-zero case is preserved through construction and rejected by `validate` as
`:distribution_not_normalized`. The system never patches an invalid input silently;
it reports the violation at the gate.

## 3. Float precision is a first-class integration concern

**Observation during base-rate prior tests:** `1.0 − 0.7` evaluates to
`0.30000000000000004` in IEEE-754; `0.7 + 0.3` evaluates to `1.0`.

Applied: assertions on float distributions use `assert_in_delta` or precision
truncation. Lineage reconstruction similarly rounds before comparison. This is
documented, not concealed.

## 4. No artificial model zoo

**Risk from forecasting practice:** multiplicative model ensembles can hide
residual dependencies and overstate confidence.

Applied: a single `ForecastEngine` composes one prior and one base rate.
`model_ref` is a label, not a selection over competing internal forecasters. Model
diversity is externalized to the Research Director and asserted at the adapter
boundary.

## 5. Inability must be signalled, not patched

**Lesson from D1 adapters (declare-only stubs):** adapters that do nothing but
consume infrastructure prevent accidental authority leakage.

Applied: `WorldModelImpl.conflicts_with_world?/1` returns
`{:error, :world_snapshot_unavailable}` — the system cannot see world-state
conflict, so it says so, rather than fabricating "no conflict". Similarly,
`ResearchImpl.information_gain_estimate/2` returns
`{:error, :insufficient_data}` when no existing observations are present.

## 6. Scoring attribution safety

**Principle from forensic post-mortems:** decisions must be attributable to the
inputs available at the time, not recalibrated after outcomes are known.

Applied: `Calibration.score/3` records `method`, `value`, `sample_size`; a
forecast is immutable, so the same distribution scored today scores identically
next week. Version history is preserved in `lineage`; corrections create new
versions, never overwrite history.