# Portfolio Balance Engine (Phase 21.1)

## Purpose

Define the portfolio balance engine that monitors and maintains constitutional balance across all research categories. Prevents monoculture, resource starvation, over-specialization, and scientific stagnation.

## Balance Dimensions

| Dimension | Measurement | Unhealthy State |
|-----------|-------------|-----------------|
| Domain diversity | Shannon entropy over domain distribution | Concentration > 30% in one domain |
| Risk levels | Ratio of low/medium/high risk programs | No high-risk or no low-risk programs |
| Time horizons | Distribution across short/medium/long horizon | All programs same horizon |
| Scientific depth | Depth of foundational vs applied research | All foundational or all applied |
| Engineering applicability | Engineering utility distribution | No engineering-relevant programs |
| Knowledge diversity | Breadth of knowledge domains covered | Knowledge concentrated in 3 or fewer domains |

## Balance Rules

| Rule | Condition | Action |
|------|-----------|--------|
| Monoculture prevention | Any domain > 30% of portfolio | Reduce allocation to that domain |
| Risk floor | High-risk programs < 10% of portfolio | Reserve 10% for high-risk |
| Horizon balance | All programs same horizon | Rebalance across horizons |
| Depth balance | Foundational < 20% or > 60% | Adjust foundational allocation |
| Stagnation detection | Knowledge growth < 5% for 10 generations | Investigate and rebalance |

## Rebalancing

When imbalance is detected:
1. Generate rebalancing proposal
2. Adjust capital allocation toward under-represented categories
3. Incentivize new programs in under-represented domains
4. Record rebalancing decision in portfolio archaeology
5. Verify balance restored within 3 generations
