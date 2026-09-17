# EFDI: Lessons from the Calibration & Forecasting Literature

**Phase:** D1 — Signal Intelligence
**Source:** research synthesis informing the D1 signal model and the D2–D6
contract surfaces.

## 1. Citation & calibration honesty

The forecasting literature (e.g., Tetlock's *Superforecasting* and the
Good Judgment Project) emphasizes (a) decomposability of forecasts into base
rates and information, and (b) calibration — a forecaster who quotes 70% should
be right ~70% of the time.

- D1 encodes the **base-rate/evidence separation** in `Contracts.BaseRate`
  (distinguishing `nil`/unknown from `0.0`).
- Forecast *calibration* is out of scope for D1 (D2 owns it), but D1's quality
  dimensions (reliability, independence) are the raw inputs calibration needs.

## 2. Signal vs. noise

Uncertain signals should be down-weighted, not discarded, and never treated as
certain. D1 models uncertainty explicitly (`measurement_uncertainty`,
`:unknown`) rather than collapsing to point values — the pre-condition for D5
(Noise) handling.

## 3. Information gain

The value of acquiring a signal is its expected reduction in uncertainty
(information gain / expected information gain). D1 exposes
`Correlation.redundancy_index/1` and `SignalValue.information_gain` (D1 returns
`:unknown` pre-outcome) and integrates with `ActiveLearner.compute_eig/2`
through `Adapters.Research`.

## 4. Independence and the base rate fallacy

Overlapping evidence is often double-counted, inflating confidence. D1's dedup
mechanism (`Signal.dedup_key`) and `Correlation` prevent the same observation
from being counted as independent evidence — a direct application of this lesson.

## 5. Epistemic humility

Never fabricate precision where none exists. D1's `:unknown`-vs-`0.0` rule and
immutable history are the concrete embodiment; they prevent overfitting to
noise and revisionist rewriting of the record.

## 6. Implication for D2–D6

The contracts declared in D1 (`ForecastRequest`, `Forecast`, `BaseRate`) and the
adapter behaviours are the seams where these literature-derived norms become
implemented logic:
- D2 — calibration + falsifiable forecasts.
- D3 — decision under uncertainty (base rates inform choices).
- D4 — counterfactual comparison.
- D5 — noise separation.
- D6 — forecast memory / calibration tracking over time.
