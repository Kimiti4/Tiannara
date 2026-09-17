# Long-Horizon Metrics (Phase 20.97)

## Purpose

Define the metrics framework for long-horizon validation. Each generation checkpoint captures a complete metrics snapshot for continuity analysis.

## Metrics Collected Per Generation

| Metric | Target | Weight in CRI |
|--------|--------|--------------|
| Generations validated | N/A | N/A |
| Knowledge retained | 1.0 | 0.20 |
| Scientific productivity | ≥ previous | 0.15 |
| Engineering productivity | ≥ previous | 0.10 |
| Replay convergence | 1.0 | 0.15 |
| Generation stability | 1.0 | 0.10 |
| Mathematical consistency | 1.0 | 0.10 |
| Governance integrity | 1.0 | 0.10 |
| Optimization stability | 1.0 | 0.05 |
| Scientific capital growth | ≥ 0 | 0.05 |
| Archaeology completeness | 1.0 | 0.10 |

## Civilizational Resilience Index (CRI)

Composite score (0.0–1.0) calculated as weighted sum of all metrics:

```
CRI = 0.20 × knowledge_retained
    + 0.15 × scientific_productivity (normalized)
    + 0.10 × engineering_productivity (normalized)
    + 0.15 × replay_convergence
    + 0.10 × generation_stability
    + 0.10 × mathematical_consistency
    + 0.10 × governance_integrity
    + 0.05 × optimization_stability
    + 0.05 × scientific_capital_growth (normalized)
    + 0.10 × archaeology_completeness
```

## Metrics Integrity

- All metrics are deterministically computable from cold storage
- Metrics must be reproducible by independent auditor
- Metrics must not sacrifice constitutional integrity for scores
- Any metric anomaly triggers governance review
