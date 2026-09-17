# Discovery Portfolio Architecture (Phase 21.0)

## Purpose

Define the discovery portfolio architecture for the research civilization. Portfolios categorize and manage discoveries as strategic assets rather than isolated events.

## Portfolio Categories

| Category | Description | Risk Profile | Allocation Strategy |
|----------|-------------|--------------|---------------------|
| Foundational Science | Fundamental knowledge generation | Low risk | Minimum 20% |
| Applied Science | Translational research | Low–Medium | 15–25% |
| Engineering | Practical system construction | Medium | 10–20% |
| High Risk | Speculative high-potential | High | 5–15% |
| High Reward | Transformative discoveries | High | 5–15% |
| Cross-Domain | Interdisciplinary synthesis | Medium | 10–20% |
| Long Horizon | Multi-generational objectives | Low–Medium | 10–20% |
| Civilizational | Civilization-scale challenges | Medium | 10–15% |

## Portfolio Allocation

Allocation is deterministic and constitutional:
1. Base allocation — Each category receives a minimum percentage
2. Performance adjustment — Categories with high discovery yield receive additional allocation
3. Strategic adjustment — Scientific Council can adjust for strategic objectives
4. Rebalancing — Portfolios are rebalanced at each generation boundary

## Discovery Tracking Per Portfolio

Each portfolio tracks:
- Total discoveries
- Active/pending/completed discoveries
- Capital invested vs discoveries produced
- Cross-portfolio discovery transfers
- Portfolio diversity score (domain distribution)

## Portfolio Rebalancing

Rebalancing is deterministic:
```
new_allocation[p] = base_allocation[p] + performance_factor[p] × discretionary_capital
```

Where performance_factor is computed from discovery yield, impact score, and cross-domain influence.
