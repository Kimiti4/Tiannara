# Uncertainty Quantifier

## Purpose
Propagates uncertainty through intervention models so decision-makers understand not just the expected outcome but the range of possible outcomes.

## Uncertainty Sources
- **Input uncertainty** — inaccurate planetary state data
- **Model uncertainty** — incomplete or incorrect domain models
- **Parameter uncertainty** — unknown model parameters
- **Structural uncertainty** — wrong model structure
- **Implementation uncertainty** — intervention may not execute as designed
- **Human uncertainty** — unpredictable human responses
- **Environmental uncertainty** — external events

## Methodology

### Probabilistic Modeling
- Represent each uncertain parameter as a distribution
- Propagate through intervention models via Monte Carlo
- Produce outcome distributions, not point estimates

### Sensitivity Analysis
- Identify which uncertainties drive outcome variance
- Rank uncertainties by impact on decisions
- Suggest where to reduce uncertainty

### Scenario Envelopes
- Best case, expected case, worst case
- Multiple plausible trajectories
- Black swan detection

## Output
For each intervention outcome: full probability distribution, confidence intervals, key uncertainty drivers, sensitivity ranking, scenario envelopes, and recommended uncertainty reduction actions.
