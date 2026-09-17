# Experiment Priority Engine

## Purpose

The Experiment Priority Engine determines the relative priority of every candidate and active experiment in the portfolio. Priority scores drive scheduling, resource allocation, and termination decisions. Every priority score is explainable, deterministic, and constitutionally governed.

## Priority Factors

| Factor | Weight | Description |
|--------|--------|-------------|
| Scientific Value | 0.25 | Expected contribution to knowledge |
| Novelty | 0.10 | How different from existing experiments |
| Expected Information Gain | 0.15 | Expected uncertainty reduction |
| Engineering Utility | 0.10 | Expected engineering improvement |
| Cross-Domain Impact | 0.10 | Relevance to other domains |
| Resource Cost | -0.10 | Computational resources required |
| Risk | -0.05 | Probability of failure |
| Urgency | 0.05 | Time sensitivity |
| Constitutional Priority | 0.15 | Alignment with constitutional goals |
| Unknown Resolution Potential | 0.05 | Potential to resolve open questions |

## Priority Score Calculation

```
Priority = Σ(weight_i × score_i)
```

Where each factor score is normalized to [0.0, 1.0] and weights sum to 1.0 for positive factors.

## Explainability

Every priority score includes:
- Per-factor scores
- Weighted contributions
- Rationale for each score
- Alternative score scenarios
- Historical priority changes

## Priority Tiers

| Tier | Score Range | Meaning |
|------|-------------|---------|
| Critical | ≥ 0.85 | Must execute immediately |
| High | [0.70, 0.85) | Execute at next available slot |
| Medium | [0.50, 0.70) | Execute within scheduling horizon |
| Low | [0.30, 0.50) | Execute when resources permit |
| Deferred | [0.15, 0.30) | Hold until priority increases |
| Background | < 0.15 | Execute only in surplus capacity |

## Determinism

Priority scores are fully deterministic given:
- The same portfolio state
- The same constitutional parameters
- The same random seed (if stochastic factors used)

## Replay

Every priority decision is replayable:
- Input state is captured
- Scoring parameters are captured
- Score computation is deterministic
- Output score is verifiable
