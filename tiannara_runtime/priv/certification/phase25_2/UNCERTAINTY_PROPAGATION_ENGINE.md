# Uncertainty Propagation Engine

## Purpose

Define the engine that propagates uncertainty through the observation pipeline.

## Uncertainty Sources

| Source | Description |
|---|---|
| Measurement Uncertainty | Inherent in the observation process |
| Sampling Uncertainty | From limited spatial/temporal samples |
| Instrument Uncertainty | From instrument calibration limits |
| Environmental Uncertainty | From environmental conditions affecting measurement |
| Processing Uncertainty | From data processing and transformation |
| Model Uncertainty | From models used to derive observations |
| Fusion Uncertainty | From combining multiple sources |
| Completeness Uncertainty | From gaps in observation coverage |

## Propagation Model

Uncertainty is represented as a probability distribution:
- **Normal** — For well-characterized measurement uncertainty.
- **LogNormal** — For multiplicative uncertainty (concentrations, ratios).
- **Uniform** — For bounded uncertainty with unknown distribution.
- **Triangular** — For expert-elicited uncertainty.
- **Beta** — For probabilities and proportions.
- **Empirical** — For empirically derived distributions.

## Propagation Rules

- Uncertainty propagates through all pipeline stages.
- Linear operations: uncertainty preserved analytically.
- Non-linear operations: uncertainty propagated via Monte Carlo or analytical approximation.
- Fusion operations: uncertainty combined using Bayesian or ensemble methods.
- Derived quantities: uncertainty propagated from source variables.

## Uncertainty Reporting

- Every evidence record includes full uncertainty metadata.
- Uncertainty visualized alongside evidence in observatory.
- Uncertainty trends tracked over time.
- Major uncertainty sources identified and reported.
- Uncertainty reduction recommendations generated.
