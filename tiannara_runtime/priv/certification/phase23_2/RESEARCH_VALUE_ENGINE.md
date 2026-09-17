# Research Value Engine

## Purpose

The Research Value Engine estimates the expected value of research activities — including experiments, programs, and entire domains. Value estimates inform priority decisions, resource allocation, and portfolio balancing. Scientific value remains measurable and comparable across domains.

## Value Dimensions

| Dimension | Description | Measurement |
|-----------|-------------|-------------|
| Expected Knowledge Gain | New information about the world | Bits of uncertainty reduction |
| Expected Engineering Gain | Applicable engineering improvements | Capability improvement score |
| Expected Uncertainty Reduction | Reduction in predictive uncertainty | Variance reduction |
| Expected Theory Impact | Contribution to theory refinement | Theory revision potential |
| Expected Constitutional Benefit | Advancement of constitutional goals | Constitutional alignment score |
| Expected Reproducibility | Likelihood of reproducible results | Methodological rigor score |
| Expected Cross-Domain Impact | Relevance to other domains | Domain connectivity score |

## Value Estimation Model

```
ResearchValue {
  value_id: content-addressed,
  experiment_id: reference (optional),
  program_id: reference (optional),
  dimensions: {
    knowledge_gain: {expected, variance, confidence},
    engineering_gain: {expected, variance, confidence},
    uncertainty_reduction: {expected, variance, confidence},
    theory_impact: {expected, variance, confidence},
    constitutional_benefit: {expected, variance, confidence},
    reproducibility: {expected, variance, confidence},
    cross_domain_impact: {expected, variance, confidence}
  },
  composite_score: float,
  value_hash: string,
  timestamp: integer
}
```

## Value Estimation Methods

| Method | Used For | Description |
|--------|----------|-------------|
| Information-Theoretic | Knowledge Gain | Expected reduction in Shannon entropy |
| Bayesian | Uncertainty Reduction | Expected reduction in posterior variance |
| Historical Analogy | Engineering Gain | Match to past high-value experiments |
| Theory Network Analysis | Theory Impact | Centrality in theory dependency graph |
| Constitutional Alignment | Constitutional Benefit | Measure of constitutional goal advancement |
| Methodological Score | Reproducibility | Assessment of experimental design rigor |
| Domain Graph Analysis | Cross-Domain Impact | Connectivity to other research domains |

## Value Comparison

Research value is comparable across:
- Different experiments within a program
- Different programs within a domain
- Different domains within the portfolio
- Different time horizons (short-term vs. long-term value)

## Value Uncertainty

Every value estimate includes:
- Expected value
- Variance (uncertainty in the estimate)
- Confidence level
- Factors contributing to uncertainty

## Value Recording

All value estimates are recorded immutably, enabling:
- Post-hoc validation of estimates
- Calibration of estimation methods
- Improvement of estimation accuracy over time
- Archaeological reconstruction of value-based decisions
