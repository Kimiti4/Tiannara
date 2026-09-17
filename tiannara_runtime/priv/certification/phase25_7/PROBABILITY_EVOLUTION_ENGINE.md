# Probability Evolution Engine

## Purpose
Continuously updates scenario probabilities as new evidence arrives — a core function for a foresight engine that never predicts certainty.

## Evidence Processing

### New Evidence Types
- Observations from CGON (confirming or contradicting scenario assumptions)
- Risk assessments from CPRIE-25.4
- Intervention outcomes from CPISE
- Resource availability changes from CPRIE-25.6
- External events and news

### Bayesian Updating
- Each scenario has prior probability
- New evidence has likelihood under each scenario
- Apply Bayes' rule to compute posterior probabilities
- Propagate updates through branching tree

### Evidence Strength
- Evidence sources assigned reliability scores
- Conflicting evidence noted
- Evidence gaps identified

### Probability Convergence and Divergence
- Convergence: scenarios that become more probable as evidence accumulates
- Divergence: scenarios where new evidence sharply separates probabilities
- Critical uncertainties: evidence that would most change probability distribution

### Non-Probabilistic Futures
- Truly unknown futures (no basis for probability)
- Tracked separately with uncertainty flags
- Not assigned spurious probabilities

## Output
Updated probability distribution across all scenarios, probability evolution over time, key evidence that drove changes, critical uncertainty identification.
