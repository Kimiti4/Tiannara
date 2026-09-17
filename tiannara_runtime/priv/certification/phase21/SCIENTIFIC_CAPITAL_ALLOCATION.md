# Scientific Capital Allocation (Phase 21.1)

## Purpose

Define the constitutional capital allocation engine. Allocate scientific capital according to constitutional priorities, research maturity, expected information gain, cross-domain leverage, and long-term sustainability. Capital allocation decisions become replayable artifacts.

## Allocation Principles

1. **Constitutional priority** — Higher-priority programs receive proportionally more capital
2. **Research maturity** — Early-stage programs receive baseline funding; mature programs receive performance-based funding
3. **Information gain** — Programs with higher expected information gain per capital unit are prioritized
4. **Cross-domain leverage** — Programs that enable research in multiple domains receive a leverage multiplier
5. **Long-term sustainability** — No single program may consume more than 25% of total capital

## Allocation Formula

```
allocation[p] = base_allocation + performance_adjustment[p] + strategic_adjustment[p]

where:
  base_allocation = total_capital × program_weight[p]
  performance_adjustment[p] = discretionary_pool × (priority_score[p] / Σ(priority_score))
  strategic_adjustment[p] = strategic_pool × council_factor[p]
```

## Allocation Pools

| Pool | Percentage | Purpose |
|------|------------|---------|
| Base allocation | 60% | Guaranteed minimum per program |
| Discretionary | 25% | Performance and priority based |
| Strategic reserve | 10% | Council-directed strategic allocation |
| Emergency reserve | 5% | Unforeseen opportunities |

## Replayability

Every allocation decision is recorded in `CAPITAL_ALLOCATION_SCHEMA.json`:
- Input evidence hashes
- Priority scores used
- Formula applied
- Resulting allocations
- Allocation hash for integrity
