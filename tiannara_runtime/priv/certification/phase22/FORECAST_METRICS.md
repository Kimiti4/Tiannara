# Forecast Metrics

## Purpose

Define quantitative metrics for measuring forecast quality, calibration accuracy, scenario diversity, decision point coverage, and overall forecasting system readiness.

## Metrics

| Metric | Description | Target |
|---|---|---|
| Forecast Accuracy | Mean absolute percentage error of predictions | <10% (near-term), <30% (long-term) |
| Calibration Error | Difference between predicted and realized confidence coverage | <5% |
| Prediction Stability | Variance of predictions across recalibrations | <15% |
| Scenario Diversity | Coverage of outcome space across scenarios | >0.70 |
| Decision Point Coverage | Fraction of relevant decision points identified | >0.85 |
| Uncertainty Quality | Sharpness of uncertainty estimates given calibration | >0.80 |
| Recalibration Frequency | Number of recalibrations per unit time | ≥1/year |
| Replay Stability | Fraction of replays producing identical hashes | 99.9% |
| Archaeology Completeness | Fraction of forecast evolution reconstructible | 99% |
| Forecast Readiness Index | Overall forecasting system maturity index | 0.85+ |

## Target Thresholds

| Metric | Minimum | Target | Excellence |
|---|---|---|---|
| Forecast Accuracy (near-term) | 0.80 | 0.90 | 0.95 |
| Forecast Accuracy (long-term) | 0.50 | 0.70 | 0.85 |
| Calibration Error | <0.10 | <0.05 | <0.02 |
| Scenario Diversity | 0.50 | 0.70 | 0.90 |
| Decision Point Coverage | 0.70 | 0.85 | 0.95 |
| Uncertainty Quality | 0.60 | 0.80 | 0.95 |
| Replay Stability | 99% | 99.9% | 99.99% |
| Archaeology Completeness | 95% | 99% | 100% |

## Measurement Methodology

- **Forecast Accuracy**: Measured after forecast horizon is reached
- **Calibration Error**: Measured via Brier score decomposition
- **Scenario Diversity**: Measured via coverage of outcome space volume
- **Decision Point Coverage**: Measured against post-hoc identified decision points
- **Uncertainty Quality**: Measured via continuous ranked probability score

## Constraints

- Metrics must be deterministically computable
- Metric records become constitutional artifacts
- Metrics are measured against realized outcomes where possible
