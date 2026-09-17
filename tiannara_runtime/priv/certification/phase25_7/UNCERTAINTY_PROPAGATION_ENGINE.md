# Uncertainty Propagation Engine

## Purpose
Propagates uncertainty through the scenario tree — from input uncertainties to probability distributions over future states.

## Uncertainty Sources

### Input Uncertainties
- Current state measurement errors
- Model parameter uncertainties
- Missing data

### Process Uncertainties
- Scenario generation approximations
- Branching simplifications
- Probability estimation errors

### Fundamental Uncertainties
- Truly random events
- Human free will
- Emergent phenomena
- Unknown unknowns

### Epistemic Uncertainties
- Things we could know but don't yet
- Things we cannot know in principle
- Limits of scientific knowledge

## Propagation Methodology

### Multi-Layer Uncertainty
- Each scenario dimension has its own uncertainty model
- Uncertainties propagate through causal dependencies
- Correlation between uncertainties is tracked

### Uncertainty Aggregation
- Combine uncertainties at each branching point
- Produce ensemble distributions over future states
- Distinguish aleatory (irreducible) from epistemic (reducible) uncertainty

### Uncertainty Visualization
- Probability density functions over future outcomes
- Confidence intervals over time
- Scenario fan charts
- Uncertainty waterfall (which uncertainties dominate)

## Output
For each scenario and time horizon: full probability distributions over outcomes, uncertainty decomposition (aleatory vs. epistemic), dominant uncertainty sources, sensitivity to uncertainty reduction.
