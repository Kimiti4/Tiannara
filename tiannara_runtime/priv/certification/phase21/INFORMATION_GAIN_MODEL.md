# Information Gain Model

## Purpose

Estimate the expected information gain from pursuing each scientific opportunity, providing a quantitative measure of knowledge value that informs prioritization and resource allocation.

## Gain Dimensions

### Novelty (0.0–1.0)
- How different is the expected knowledge from existing knowledge
- Degree of paradigm extension vs revolution
- Uniqueness of the knowledge gap being addressed
- Surprise potential

### Scientific Impact (0.0–1.0)
- Breadth of scientific fields affected
- Depth of theoretical revision required
- Explanatory scope of expected results
- Theory refinement potential

### Cross-Domain Influence (0.0–1.0)
- Number of domains likely to benefit
- Cross-domain integration potential
- Unifying principle discovery potential
- Interdisciplinary methodology export

### Engineering Utility (0.0–1.0)
- New engineering capabilities enabled
- Instrumentation improvements expected
- Infrastructure advancement potential
- Technological applications

### Mathematical Depth (0.0–1.0)
- Formal structure discovery potential
- Proof framework advancement
- Mathematical tool development
- Computational method improvement

### Knowledge Compression (0.0–1.0)
- Reduction in descriptive complexity
- Unification of separate knowledge areas
- Simplification of theoretical frameworks
- Elimination of redundant explanations

### Civilizational Importance (0.0–1.0)
- Direct societal benefit
- Existential risk reduction
- Quality of life improvement
- Sustainability contribution

### Expected Uncertainty Reduction (0.0–1.0)
- Quantitative reduction in hypothesis space
- Confidence interval narrowing
- Predictive precision improvement
- Model parameter constraint

## Composite Gain

```
Information Gain = (Novelty × 0.15) + (ScientificImpact × 0.20) + (CrossDomain × 0.15) +
                   (Engineering × 0.10) + (MathDepth × 0.10) + (Compression × 0.10) +
                   (Civilizational × 0.10) + (UncertaintyReduction × 0.10)
```

## Uncertainty Range

Each dimension estimate includes a lower and upper bound:
- **Lower Bound**: Conservative estimate based on minimum expected gain
- **Upper Bound**: Optimistic estimate based on maximum possible gain
- **Range Width**: Indicates estimate confidence (smaller = more confident)

## Determinism

All gain estimates must be identical given identical opportunity and frontier state. No learning, no adjustment, no optimization.

## Constraints

- All dimension scores must be 0.0–1.0
- Composite must be weighted average of dimensions
- Uncertainty range must contain true value
- Gain estimates become constitutional artifacts
- All estimates must be replayable
