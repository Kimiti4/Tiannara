# EFDI D3 — Decision Quality

## 1. Ex-ante quality

`DecisionQuality.evaluate(decision, snapshot \\ nil)` and `evaluate_snapshot/1` compute
decision quality **from decision-time information only**. The composite score is the mean
of six components, each in `[0,1]`:

| Component | Measures |
|-----------|----------|
| `alternative_coverage` | mutually-exclusive alternatives + the no-action option |
| `probability_integrity` | probabilities valid and normalized (sum 1) |
| `utility_integrity` | utilities present and matching outcomes |
| `information_sufficiency` | distributions determinate (not `:unknown`) |
| `risk_registered` | reversibility documented |
| `self_consistency` | expected value follows from the utilities |

Every evaluation returns `hindsight_independent: true` and `basis: :decision_time`.
The **outcome is never an input** — this is the "resulting" lesson made structural.

## 2. The triple distinction

FORECAST QUALITY ≠ DECISION QUALITY ≠ OUTCOME QUALITY. `classify/2` keeps the axes independent:

```
classify(score, outcome_success) → %{decision: :good | :poor, outcome: :good | :poor}
```

All four combinations are representable; the forbidden implications
(BAD OUTCOME → BAD DECISION, GOOD OUTCOME → GOOD DECISION) are simply not expressible.

## 3. Hindsight guards

- `consistent_with_snapshot?/2` proves the decision still matches its decision-time snapshot.
- `evaluate_snapshot/1` provides a snapshot-only path that cannot be contaminated by outcome.
- Adversarial tests assert that quality scored before and after an observed outcome is identical.