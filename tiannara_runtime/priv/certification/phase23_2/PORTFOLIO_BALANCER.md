# Portfolio Balancer

## Purpose

The Portfolio Balancer maintains a healthy balance of experiment types, risk levels, and research domains within the experiment portfolio. It prevents research monoculture and ensures Tiannara explores diverse scientific avenues.

## Balance Dimensions

| Dimension | Description | Target Distribution |
|-----------|-------------|---------------------|
| Risk Level | Expected probability of success | 20% high-risk, 50% medium-risk, 30% low-risk |
| Research Type | Category of research | 25% exploratory, 30% incremental, 15% validation, 10% replication, 20% engineering |
| Domain Coverage | Scientific domains represented | At least 3 active domains |
| Time Horizon | Expected time to completion | 30% short-term, 40% medium-term, 30% long-term |
| Methodology | Experimental approach | 40% simulation, 30% analytical, 20% hybrid, 10% physical |
| Impact Scope | Breadth of expected impact | 20% narrow, 50% moderate, 30% broad |

## Balance Model

```
PortfolioBalance {
  balance_id: content-addressed,
  timestamp: integer,
  dimensions: {
    risk: {high_pct, medium_pct, low_pct, score},
    type: {exploratory_pct, incremental_pct, validation_pct, replication_pct, engineering_pct, score},
    domain: {domains: [domain_pct], diversity_index},
    horizon: {short_pct, medium_pct, long_pct, score},
    methodology: {simulation_pct, analytical_pct, hybrid_pct, physical_pct, score},
    impact: {narrow_pct, moderate_pct, broad_pct, score}
  },
  composite_balance_score: float,
  imbalance_warnings: [string],
  rebalancing_suggestions: [string],
  balance_hash: string
}
```

## Diversity Index

The portfolio diversity index measures how evenly experiments are distributed across categories within each dimension:

```
DiversityIndex = Σ(p_i × log(p_i)) / log(n)
```

Where:
- p_i = proportion of experiments in category i
- n = number of categories
- Result normalized to [0, 1] where 1 is perfectly diverse

## Rebalancing Triggers

The balancer triggers rebalancing when:
- Dimension score falls below threshold (0.7)
- A domain has no active experiments
- More than 50% of experiments are same risk level
- Portfolio diversity index < 0.6
- Constitutional directive requires domain emphasis

## Rebalancing Actions

| Action | Effect |
|--------|--------|
| Promote Domain | Increase priority of underrepresented domain |
| Seed Exploratory | Create new exploratory experiments |
| Add Validation | Add validation experiments for existing results |
| Schedule Replication | Add replication experiments |
| Retire Obsolete | Archive experiments in overrepresented category |
| Cross-Pollinate | Create cross-domain experiments |

## Monoculture Prevention

The portfolio balancer actively prevents:
- Single-domain dominance (> 60% of portfolio)
- Single-risk concentration (> 50% same risk level)
- Single-type dominance (> 40% same research type)
- Methodology lock-in (> 60% same methodology)
