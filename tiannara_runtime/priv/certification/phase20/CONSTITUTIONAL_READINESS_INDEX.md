# Constitutional Readiness Index (Phase 20.98)

## Definition

The Constitutional Readiness Index (CRI) is a quantitative measure (0.0–1.0) that evaluates how close the Tiannara Constitutional Operating System is to constitutional certification. It aggregates evidence from all prior validation phases into a single reproducible score.

## Formula

```
CRI = Σ(dimension_weight[i] × dimension_score[i]) for i = 1..10
```

Where:
- Σ(weights) = 1.0
- Each dimension_score[i] = Σ(sub_metric_weight[j] × sub_metric_score[j])
- All scores normalized to 0.0–1.0
- All calculations deterministic

## Score Interpretation

| Score Range | Meaning |
|-------------|---------|
| 0.00–0.25 | Preliminary — significant deficiencies remain |
| 0.25–0.50 | Developing — some dimensions mature |
| 0.50–0.75 | Advancing — most dimensions approaching readiness |
| 0.75–0.90 | Mature — strong readiness evidence |
| 0.90–0.95 | Near-certification — minor deficiencies only |
| 0.95–1.00 | Certification candidate — eligible for Phase 20.999 |

## CRI Computation Steps

1. Collect evidence from all prior phases (20.95, 20.96, 20.97)
2. Compute sub-metric scores for each dimension
3. Aggregate sub-metrics into dimension scores
4. Apply weights to dimension scores
5. Sum weighted scores for overall CRI
6. Determine CRI level (0–6)
7. Analyze deficiencies
8. Generate certification recommendation

## Output

The CRI produces:
- Overall score (0.0–1.0)
- CRI level (0–6)
- Per-dimension breakdown
- Per-domain breakdown (20 research domains)
- Deficiency analysis
- Improvement priorities
- Certification recommendation (not certification)
