# Uncertainty Engine

## Purpose

The Uncertainty Engine explicitly represents, tracks, and propagates uncertainty throughout the discovery pipeline. Unknowns remain first-class objects. Every conclusion, hypothesis, and theory includes its uncertainty bounds.

## Uncertainty Types

| Type | Description | Source |
|------|-------------|--------|
| Epistemic | Uncertainty due to lack of knowledge | Missing observations, untested hypotheses |
| Aleatoric | Intrinsic randomness | Measurement noise, stochastic processes |
| Model | Uncertainty in model structure | Simplified assumptions, missing variables |
| Measurement | Error in measurement | Instrument precision, calibration |
| Prediction | Uncertainty in predicted outcomes | Propagation of all above |

## Uncertainty Representation

```
Uncertainty {
  source_id: content-addressed,
  source_type: :observation | :hypothesis | :prediction | :evidence | :theory,
  uncertainty_type: enum,
  distribution: :normal | :uniform | :custom | :unknown,
  parameters: {mean, variance, confidence_interval},
  contributing_factors: [{factor, contribution}],
  assumptions: [string],
  propagation: [child_uncertainty_id],
  timestamp: integer
}
```

## Uncertainty Propagation

Uncertainty propagates through the discovery pipeline:
- Observation uncertainty → Hypothesis uncertainty
- Hypothesis uncertainty → Prediction uncertainty
- Prediction uncertainty → Experiment design
- Experiment uncertainty → Evidence uncertainty
- Evidence uncertainty → Validation confidence
- Validation confidence → Theory certainty

## Unknown Registry

The Unknown Registry tracks all registered unknowns:
- What is unknown
- Why it is unknown
- What would resolve the unknown
- Priority of resolution
- Dependencies on other unknowns

## Constitutional Guarantees

- No uncertainty is hidden
- Unknowns are explicit first-class artifacts
- Uncertainty propagation is deterministic
- Uncertainty is replayable and verifiable
- Assumptions are always documented
