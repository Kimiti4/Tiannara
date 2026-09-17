# Evidence Engine

## Purpose

The Evidence Engine collects, classifies, and preserves all evidence produced by experiments and observations. Evidence remains immutable regardless of outcome — positive, negative, contradictory, null, and unexpected evidence are all preserved with full provenance.

## Evidence Types

| Type | Description | Example |
|------|-------------|---------|
| Positive | Supports the hypothesis | Predicted outcome observed |
| Negative | Contradicts the hypothesis | Predicted outcome not observed |
| Contradictory | Contradicts existing evidence | Different result from previous experiment |
| Null | No measurable effect | No significant difference detected |
| Unexpected | Outcome not predicted | Novel phenomenon observed |

## Evidence Structure

```
Evidence {
  evidence_id: content-addressed,
  experiment_id: reference,
  hypothesis_id: reference,
  type: enum,
  data: map,
  uncertainty: {type, value, confidence},
  reproducibility: {attempts, successes, consistency},
  collection_method: string,
  validation_status: :unvalidated | :verified | :questionable | :invalid,
  timestamp: integer,
  evidence_hash: string,
  previous_evidence_id: string | nil
}
```

## Evidence Lifecycle

```
Collection → Classification → Recording → Validation → Integration
```

### Collection
Evidence is collected from experiment execution and observation systems.

### Classification
Evidence is classified by type (positive, negative, contradictory, null, unexpected).

### Recording
Evidence is recorded immutably in CPL. No evidence is ever deleted or modified.

### Validation
Evidence is validated for reproducibility and collection integrity.

### Integration
Validated evidence is integrated into hypothesis assessment and theory evolution.

## Constitutional Guarantees

- No evidence is ever deleted
- Contradictory evidence is preserved alongside supporting evidence
- Failed experiments produce evidence equal in status to successful ones
- Evidence provenance is fully traceable
- Evidence is replayable and verifiable
