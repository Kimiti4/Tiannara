# Uncertainty Propagation Engine

## Purpose

Propagate all forms of uncertainty through the impact prediction pipeline. Unknowns are never hidden — they are recorded and tracked.

## Uncertainty Types

| Type | Description |
|------|-------------|
| Measurement Uncertainty | Uncertainty from measurement limitations |
| Model Uncertainty | Uncertainty from model approximations |
| Knowledge Uncertainty | Uncertainty from incomplete knowledge |
| Epistemic Uncertainty | Reducible uncertainty from lack of knowledge |
| Aleatoric Uncertainty | Irreducible uncertainty from inherent randomness |

## Propagation Rules

- Each prediction records its uncertainty
- Uncertainty propagates through the pipeline
- Uncertainty is never averaged away
- Total uncertainty is decomposed by type
- Dominant uncertainty sources are identified
