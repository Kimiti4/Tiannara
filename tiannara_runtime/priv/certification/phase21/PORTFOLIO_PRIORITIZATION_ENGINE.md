# Portfolio Prioritization Engine (Phase 21.1)

## Purpose

Define the deterministic prioritization engine that ranks all research programs using constitutional criteria. No stochastic ranking — every priority score is deterministically computed from evidence.

## Prioritization Dimensions

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Scientific impact | 0.15 | Expected contribution to knowledge |
| Knowledge-gap reduction | 0.15 | How much unknown becomes known |
| Engineering utility | 0.10 | Practical engineering value |
| Mathematical significance | 0.10 | Mathematical depth and novelty |
| Cross-domain influence | 0.10 | Applicability across domains |
| Long-term value | 0.10 | Enduring relevance beyond current generation |
| Scientific capital return | 0.10 | Expected capital yield |
| Civilizational benefit | 0.10 | Benefit to civilization-scale objectives |
| Reproducibility confidence | 0.05 | Likelihood of reproducible results |
| Constitutional alignment | 0.05 | Alignment with constitutional principles |

## Priority Formula

```
priority_score = Σ(weight[i] × normalized_score[i])

where normalized_score[i] = f(evidence[i], baseline[i])
```

All scores are normalized to 0.0–1.0. Priority is computed fresh at each generation boundary.

## Ranking Output

The engine produces:
- Ordered list of all programs by priority score
- Per-program dimension breakdown
- Priority justification (evidence chain)
- Capital allocation recommendation
- Scheduling recommendation
