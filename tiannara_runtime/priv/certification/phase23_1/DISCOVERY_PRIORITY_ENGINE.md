# Discovery Priority Engine

## Purpose

The Discovery Priority Engine determines the priority of every discovery activity — observations, questions, hypotheses, experiments, and theory work. Priority scores drive resource allocation and scheduling across the discovery pipeline.

## Priority Factors

| Factor | Weight | Description |
|--------|--------|-------------|
| Expected Knowledge Gain | 0.20 | Expected reduction in uncertainty |
| Novelty | 0.15 | How different from existing knowledge |
| Hypothesis Discrimination | 0.15 | Ability to distinguish competing hypotheses |
| Cross-Domain Impact | 0.10 | Relevance to other domains |
| Engineering Utility | 0.10 | Engineering applicability |
| Urgency | 0.10 | Time sensitivity |
| Resource Cost | -0.10 | Required resources |
| Risk | -0.05 | Probability of failure |
| Constitutional Priority | 0.15 | Alignment with constitutional goals |

## Priority Score Calculation

```
Priority = Σ(weight_i × score_i)
```

Each factor score is normalized to [0.0, 1.0].

## Priority Tiers

| Tier | Score Range | Meaning |
|------|-------------|---------|
| Critical | >= 0.85 | Immediate investigation |
| High | [0.70, 0.85) | Next available slot |
| Medium | [0.50, 0.70) | Standard priority |
| Low | [0.30, 0.50) | Resource-permitting |
| Deferred | [0.15, 0.30) | Hold until priority increases |
| Background | < 0.15 | Curiosity-only investigation |

## Explainability

Every priority score includes:
- Per-factor scores and weights
- Rationale for each score
- Alternative priority scenarios
- Historical priority changes
- Constitutional justification
