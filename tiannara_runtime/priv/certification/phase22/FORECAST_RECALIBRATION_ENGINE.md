# Forecast Recalibration Engine

## Purpose

When new evidence arrives, compare forecast predictions to observed reality, measure prediction error, update confidence, preserve the previous forecast, and generate a revised forecast with complete recalibration lineage.

## Recalibration Trigger Events

- New empirical evidence arrives
- Forecast horizon reached or passed
- Significant civilization state change detected
- New decision point becomes relevant
- Scheduled recalibration interval reached
- Human-initiated recalibration request

## Recalibration Process

1. **Capture Previous Forecast**: Archive current forecast with full provenance
2. **Gather Reality Data**: Collect observed outcomes for the forecast period
3. **Compare Prediction to Reality**: Measure deviation across all dimensions
4. **Calculate Prediction Error**: Quantitative error metrics per dimension
5. **Analyze Error Sources**: Attribute error to evidence, model, assumption, or uncertainty
6. **Update Confidence Models**: Adjust uncertainty estimates based on error patterns
7. **Identify Assumption Failures**: Document which assumptions proved incorrect
8. **Generate Revised Forecast**: Create new forecast incorporating new evidence and lessons
9. **Link Lineage**: Connect revised forecast to previous forecast via recalibration chain
10. **Record**: Generate complete recalibration artifact

## Prediction Error Metrics

- **Absolute Error**: |predicted - observed|
- **Relative Error**: |predicted - observed| / |observed|
- **Direction Accuracy**: Was the direction of change correct?
- **Confidence Calibration**: Did x% confidence intervals contain x% of outcomes?
- **Signpost Accuracy**: Were signpost events correctly predicted?

## Recalibration Lineage

Each recalibration creates:

```
Forecast_v1 → [new evidence] → Recalibration_1 → Forecast_v2
Forecast_v2 → [new evidence] → Recalibration_2 → Forecast_v3
...
```

Complete recalibration chain is preserved. Historical forecasts are never overwritten.

## Recalibration Artifact Structure

Each recalibration contains:

- **Recalibration ID**: Content-addressed identifier
- **Previous Forecast ID**: The forecast being recalibrated
- **Revised Forecast ID**: The new forecast
- **New Evidence**: Evidence that triggered recalibration
- **Prediction Error Summary**: Quantitative error analysis
- **Assumption Failures**: Assumptions that proved incorrect
- **Confidence Updates**: Revised uncertainty estimates
- **Recalibration Fingerprint**: Deterministic content hash

## Constraints

- Historical forecasts are never overwritten
- Recalibration lineage is fully preserved
- Recalibration records become constitutional artifacts
