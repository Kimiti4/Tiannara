# Multi-World Decision Comparison Engine

## Purpose

Compare decisions across multiple future worlds, evaluating how each decision performs under different possible trajectories.

## Comparison Methodology

### Per-World Evaluation
- For each decision alternative, simulate in all future worlds
- Record expected outcome per world per alternative
- Document which worlds favor which decisions
- Identify decision robustness across scenarios

### Cross-World Metrics
- **Robustness**: Fraction of futures where decision performs well
- **Regret**: Performance loss from suboptimal decision in each future
- **Sensitivity**: How much outcome varies across futures
- **Convergence**: Degree of agreement across futures
- **Divergence Risk**: Futures where decision fails catastrophically

### Decision Types

#### Robust Decisions
- Perform well across most futures
- Low sensitivity to scenario variation
- Preferred when uncertainty is high

#### Contingent Decisions
- Perform well only in specific futures
- Require monitoring for scenario confirmation
- Include pre-commitment to reassess

#### Hedging Decisions
- Good performance across diverse futures
- May not be optimal in any single future
- Reduce worst-case regret

#### Transformative Decisions
- Excellent performance in some futures
- Poor performance in others
- High reward but high scenario dependence

## Output

- Decision comparison matrix across futures
- Robustness, regret, sensitivity scores
- Decision type classification
- Recommended decision with supporting evidence

## Constraints

- All comparisons must be evidence-derived
- Outcome uncertainty must be documented
- Multiple futures must be included
- Comparison records become constitutional artifacts
