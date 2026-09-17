# Prediction Engine

## Purpose

The Prediction Engine generates testable predictions from hypotheses. Predictions specify expected outcomes with confidence intervals, full lineage tracking, and replay support.

## Prediction Structure

```
Prediction {
  prediction_id: content-addressed,
  hypothesis_id: reference,
  description: string,
  expected_outcome: map,
  confidence_interval: {lower, upper, confidence_level},
  conditions: [condition],
  assumptions: [string],
  lineage: {hypothesis_id, theory_refs},
  status: :pending | :confirmed | :contradicted | :inconclusive,
  evidence: [evidence_id],
  created_at: integer,
  prediction_hash: string
}
```

## Prediction Types

| Type | Description | Example |
|------|-------------|---------|
| Quantitative | Numerical outcome | "Value will be between X and Y" |
| Qualitative | Categorical outcome | "System will exhibit behavior B" |
| Comparative | Relative outcome | "A will be greater than B" |
| Existential | Existence outcome | "Phenomenon P will be observed" |
| Conditional | If-then outcome | "If X then Y" |
| Temporal | Time-based outcome | "Event will occur within T" |

## Prediction Lifecycle

```
Generation → Registration → Tracking → Verification → Resolution
```

### Generation
Predictions are derived from hypotheses using available reasoning methods.

### Registration
Predictions are registered immutably before any testing occurs. This prevents post-hoc modification.

### Tracking
As experiments produce evidence, predictions are tracked for confirmation or contradiction.

### Verification
Evidence is compared against predictions. Confidence intervals are evaluated.

### Resolution
Predictions are confirmed, contradicted, or marked inconclusive based on evidence.

## Determinism

Predictions are fully deterministic given the same hypothesis and context. Prediction replay enables verification of prediction correctness.
