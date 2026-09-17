# Theory Evolution Engine

## Purpose

The Theory Evolution Engine manages the lifecycle of scientific theories — from birth through growth, competition, merge, split, replacement, and retirement. Theory ecology remains observable at all times.

## Theory Lifecycle

```
Birth → Growth → Competition → Maturity → (Merge | Split | Replacement | Retirement)
```

### Birth
A new theory is born when a hypothesis accumulates sufficient supporting evidence and no contradictions.

### Growth
The theory expands as new evidence supports it and it successfully predicts outcomes.

### Competition
Multiple theories compete to explain the same phenomena. Competition is recorded and observable.

### Maturity
A mature theory has extensive supporting evidence, high predictive accuracy, and wide explanatory scope.

### Merge
Two or more theories merge when they are found to be compatible special cases of a more general theory.

### Split
A theory splits when internal contradictions force it to divide into separate theories for different domains.

### Replacement
A theory is replaced when a superior theory explains the same phenomena more accurately or comprehensively.

### Retirement
A theory is retired when it is fully superseded or when its domain of applicability is exhausted.

## Theory Structure

```
ScientificTheory {
  theory_id: content-addressed,
  name: string,
  domain: string,
  propositions: [proposition],
  supporting_hypotheses: [hypothesis_id],
  supporting_evidence: [evidence_id],
  contradictory_evidence: [evidence_id],
  predictions: [prediction_id],
  scope: {domains, applicability_conditions},
  uncertainty_bounds: {epistemic, aleatoric},
  status: :embryonic | :growing | :competing | :mature | :merging | :splitting | :replacing | :retired,
  lineage: {parent_theories, child_theories},
  created_at: integer,
  theory_hash: string
}
```

## Theory Ecology Metrics

| Metric | Description |
|--------|-------------|
| Theory Count | Total active theories |
| Competition Density | Theories per domain |
| Merge Rate | Mergers per epoch |
| Split Rate | Splits per epoch |
| Replacement Rate | Replacements per epoch |
| Theory Age | Average theory lifetime |
| Domain Coverage | Domains with active theories |
