# Uncertainty Model

## Purpose

Define how uncertainty is represented and propagated across all planetary state domains.

## Uncertainty Types

| Type | Description | Example |
|---|---|---|
| Measurement Uncertainty | Inherent in the observation process | Sensor noise |
| Sampling Uncertainty | From limited samples | Survey margin of error |
| Model Uncertainty | From imperfect models | Climate model spread |
| Structural Uncertainty | From model structure choices | Alternative model specifications |
| Parameter Uncertainty | From unknown parameters | Unknown model parameters |
| Scenario Uncertainty | From unknown future conditions | Unknown policy choices |
| Completeness Uncertainty | From missing data | Gaps in observation coverage |
| Contradiction Uncertainty | From conflicting evidence | Different sources disagree |

## Uncertainty Representation

Every state value includes:
- **Point Estimate** — Best estimate value.
- **Confidence Interval** — Range at specified confidence level.
- **Distribution** — Full probability distribution (when available).
- **Confidence Score** — 0–1 confidence in the estimate.
- **Source Uncertainty** — Breakdown by uncertainty type.
- **Provenance** — Sources of uncertainty information.

## Uncertainty Propagation

- Uncertainty propagated through all state computations.
- Derived state values include propagated uncertainty.
- Aggregation across regions includes spatial uncertainty.
- Temporal aggregation includes temporal uncertainty.
- Cross-domain propagation preserves correlation structure.

## Uncertainty Reporting

- Uncertainty displayed alongside all state values.
- Uncertainty trends tracked over time.
- Major uncertainty sources identified and reported.
- Uncertainty reduction recommendations generated.
- Uncertainty representation certified for correctness.
