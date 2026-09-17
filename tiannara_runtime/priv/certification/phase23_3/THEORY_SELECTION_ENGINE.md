# Theory Selection Engine

## Purpose

Select theories for engineering transfer based on evaluation scores,
domain requirements, and constitutional constraints.

## Selection Criteria

- Predictive accuracy above domain threshold
- Explanatory power sufficient for engineering needs
- Uncertainty within acceptable bounds
- Reproducibility verified
- Contradictions documented and resolved
- Constitutional compliance confirmed

## Selection Process

1. Filter theories by domain requirements
2. Rank by weighted evaluation score vector
3. Verify constitutional compliance
4. Verify reproducibility
5. Select top-ranked qualifying theory
6. Record selection justification
7. Transfer to Engineering Knowledge base

## Multiple Selection

When multiple theories qualify:
- If they agree within uncertainty, select the one with highest score
- If they disagree, flag for Theory Conflict Resolution Engine
- If they cover complementary aspects, flag for Theory Unification Engine

## Constitutional Rules

- Selection must be deterministic given the same inputs
- Selection justification must be recorded
- Unselected theories remain available for future selection
