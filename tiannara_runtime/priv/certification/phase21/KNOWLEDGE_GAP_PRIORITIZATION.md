# Knowledge Gap Prioritization

## Purpose

Rank scientific opportunities by expected knowledge value using deterministic prioritization, ensuring the most valuable frontier gaps are addressed first.

## Prioritization Dimensions

### Scientific Impact (Weight: 0.20)
- Potential to advance fundamental understanding
- Breadth of theories affected
- Depth of explanatory power gained
- Paradigm shift potential

### Knowledge Gap Reduction (Weight: 0.15)
- Size of knowledge gap to be closed
- Number of unresolved questions addressable
- Completeness improvement to frontier layer
- Dependency cascade benefit

### Cross-Domain Influence (Weight: 0.15)
- Number of domains that would benefit
- Cross-domain integration potential
- Unifying framework potential
- Interdisciplinary discovery enablement

### Engineering Utility (Weight: 0.12)
- Engineering capabilities enabled
- Instrumentation advancement potential
- Infrastructure improvement potential
- Technological application breadth

### Mathematical Significance (Weight: 0.12)
- Mathematical structure discovery potential
- Proof framework advancement
- Formal foundation strengthening
- Computational method improvement

### Long-Term Value (Weight: 0.10)
- Knowledge half-life estimate
- Foundation for future discoveries
- Generational relevance
- Civilizational capability building

### Civilizational Benefit (Weight: 0.08)
- Direct civilization impact potential
- Existential risk reduction
- Quality of life improvement
- Sustainability contribution

### Expected Information Gain (Weight: 0.05)
- Bits of uncertainty reduction
- Hypothesis space contraction
- Predictive precision improvement
- Model refinement potential

### Reproducibility Confidence (Weight: 0.02)
- Likelihood of reproducible results
- Experimental feasibility
- Methodological maturity
- Verification tractability

### Constitutional Alignment (Weight: 0.01)
- Alignment with constitutional principles
- Ethical soundness
- Governance compatibility
- Long-term constitutional coherence

## Composite Priority Score

```
Priority = Σ(weight_i × score_i) for all dimensions
```

## Priority Classification

| Score Range | Priority Level | Action |
|---|---|---|
| 0.80–1.00 | Critical | Immediate investigation |
| 0.60–0.79 | High | Expedited investigation |
| 0.40–0.59 | Medium | Standard investigation |
| 0.20–0.39 | Low | Deferred investigation |
| 0.00–0.19 | Background | Monitor only |

## Determinism

Priority scores must be identical given identical opportunity characterization. All dimension scores computed from frontier evidence deterministically.

## Constraints

- Weight sums must equal 1.0
- All dimension scores must be 0.0–1.0
- Priority scores must be fully replayable
- Prioritization records become constitutional artifacts
