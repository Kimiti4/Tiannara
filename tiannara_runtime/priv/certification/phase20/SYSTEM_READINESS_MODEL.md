# System Readiness Model (Phase 20.98)

## Purpose

Compute the system-level readiness assessment by aggregating all dimension and domain scores into the overall CRI. The system readiness model evaluates the Constitutional OS as a whole.

## Aggregation

```
System Readiness = Σ(dimension_weight[i] × dimension_score[i])

Where:
  dimension_score[i] = Σ(sub_weight[j] × sub_metric_score[j])

Domain aggregation (per-system):
  domain_readiness_total = Σ(domain_weight[d] × domain_score[d])
```

## System-Level Metrics

| Metric | Computation | Target | Weight |
|--------|------------|--------|--------|
| Validation completeness | % of campaigns/gates passed | 1.0 | 0.15 |
| Audit completeness | % of subsystems audited with intact verdict | 1.0 | 0.15 |
| Replay completeness | % of replay chains verified | 1.0 | 0.15 |
| Archaeology completeness | % of generations fully preserved | 1.0 | 0.15 |
| Knowledge maturity | Weighted average of knowledge dimensions | ≥0.90 | 0.10 |
| Engineering maturity | Weighted average of engineering dimensions | ≥0.90 | 0.10 |
| Scientific maturity | Weighted average of scientific dimensions | ≥0.90 | 0.10 |
| Civilizational maturity | Weighted average of civilizational dimensions | ≥0.85 | 0.10 |

## Deficiency Detection

A deficiency is any sub-metric that scores below 0.80. Deficiencies are categorized:
- **Critical deficiency**: sub-metric < 0.50
- **Major deficiency**: sub-metric 0.50–0.70
- **Minor deficiency**: sub-metric 0.70–0.80

## Improvement Priorities

For each deficiency, generate:
1. Affected dimension/domain
2. Current score
3. Target score (≥ 0.80)
4. Recommended remediation
5. Evidence references
