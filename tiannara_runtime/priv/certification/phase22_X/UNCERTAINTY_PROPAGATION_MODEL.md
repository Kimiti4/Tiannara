# Uncertainty Propagation Model

## Purpose

Represent uncertainty propagation across constitutional layers — from observation error through model error, inference error, prediction error, decision error, to system error — with mathematically explicit representation at every stage.

## Uncertainty Hierarchy

```
Observation Error (Layer-specific measurement uncertainty)
  ↓
Model Error (Layer-specific model approximation uncertainty)
  ↓
Inference Error (Cross-layer inference uncertainty)
  ↓
Prediction Error (Forward prediction uncertainty)
  ↓
Decision Error (Intervention outcome uncertainty)
  ↓
System Error (Aggregate system behavior uncertainty)
```

## Uncertainty Sources

### Layer-Specific Observation Error
- Measurement instrument limitations per layer
- Sampling uncertainty
- Data quality and completeness
- Calibration accuracy

### Layer-Specific Model Error
- Structural simplification in layer models
- Parameter estimation uncertainty
- Boundary condition sensitivity
- Known unknown dynamics

### Cross-Layer Inference Error
- Emergence uncertainty (how much is irreducible)
- Constraint uncertainty (how strong is the constraint)
- Mapping uncertainty between layer ontologies
- Lost information in cross-layer abstraction

### Prediction Error
- Horizon-dependent uncertainty growth
- Cascade uncertainty through causal chains
- Nonlinear amplification
- Regime change uncertainty

### Intervention Uncertainty
- Implementation fidelity uncertainty
- Side effect uncertainty
- Reaction uncertainty (other agents respond unpredictably)
- Long-term consequence uncertainty

## Uncertainty Propagation Mathematics

Uncertainty propagates through the causal graph according to:

```
U_total = Σ(U_i) + Σ(U_ij) + U_emergence

Where:
U_i = Uncertainty at node i
U_ij = Uncertainty of edge i→j
U_emergence = Irreducible emergence uncertainty
```

Cross-layer transitions add systematic uncertainty that cannot be eliminated.

## Uncertainty Representation

- **Probability Distributions**: Parametric and non-parametric
- **Confidence Intervals**: At multiple confidence levels
- **Uncertainty Intervals**: Ranges with lower/upper bounds
- **Scenario Envelopes**: Bounded possibility spaces
- **Qualitative Uncertainty**: Known unknowns and unknown unknowns

## Uncertainty Quality

- **Calibration**: Do X% confidence intervals contain X% of outcomes?
- **Sharpness**: How precise are uncertainty estimates?
- **Resolution**: Can uncertainty distinguish different scenarios?
- **Honesty**: Is uncertainty ever understated?

## Constraints

- Uncertainty must be mathematically explicit at every stage
- Uncertainty must never be hidden or averaged away
- Uncertainty records become constitutional artifacts
- Cross-layer transitions explicitly quantify added uncertainty
