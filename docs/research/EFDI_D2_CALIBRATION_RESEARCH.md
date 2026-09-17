# EFDI D2 — Calibration Research Integration

## 1. Connection to existing Tiannara evidence infrastructure

D2 calibration does not introduce a new probability or decision system. It
composes existing primitives:

| D2 component | Existing Tiannara composition |
|--------------|------------------------------|
| Shannon entropy → sharpness | `Tiannara.Foundations.InformationTheory.shannon_entropy/1` (raw float) |
| Bayes update → evidence-driven prior | `Tiannara.Math.Probability.bayes_update/3` (`{:ok, posterior}`) |
| Probability normalization | `Tiannara.Constraints.normalize_probabilities/1` (with documented edge: float `0.0` not integer `0`) |
| ID generation | `Tiannara.Executive.Types.new_id/0` |
| Event lineage | `Tiannara.Executive.EventStore` (best-effort) |

No parallel probability engine exists; the signal forecast path is purely
compositional.

## 2. Relationship to SignalValue and SignalQuality

`SignalQuality.assess/1` was documented as a placeholder in D1. D2 uses the
existing `SignalQuality.evaluate/1` (via `%SignalQuality{}` with
`aggregate_score`) for signal integrity, and `SignalValue.measure/1` for
information-gain-based prioritization. Neither contains forecasting logic;
they are upstream signal-preparation steps feeding `ForecastRequest.signal_ids`.

## 3. Relationship to Scientific Discovery / Research Director

`ResearchImpl` translates high-value signals into priority maps compatible
with `Tiannara.Research.ResearchDirector.ingest_priorities/1` — without
replacing the Research Director. The adapter consumes, does not own:
forecasting uncertainty and research goal-priority are kept orthogonal.

## 4. Constitutional relationship to CIS

`CISImpl.forecast_to_collapse_probability/1` produces an epistemic collapse
proxy (excess tail weight) from a forecast distribution. It records its
output as a transparent map, not as an authorization. The constitution is
preserved: CIS retains authority over safety/stability decisions; D2 provides
evidence only.

## 5. Forecast as falsifiable entity

A D2 forecast is falsifiable in the precise epistemic sense: it declares a
distribution over mutually exclusive outcomes with a explicit horizon, and
its calibration can be scored against observed outcomes. The Brier score and
log loss metrics quantify accuracy without altering the original distribution
(immutable versioned forecasts, no hidden recalibration).

## 6. Explicit base-rate accounting

`BaseRateEngine.compare/2` returns base rate and interim current evidence side
by side with quality metadata — neither privileged. This matches Kahneman &
Tversky's finding that base-rate neglect is a systematic error: D2 surfaces
both and leaves the judgment to the caller. An unjustified base-rate
(`:unknown`) does not silently become a uniform prior.