# Hypothesis Generation Engine

## Purpose

The Hypothesis Generation Engine proposes testable hypotheses in response to scientific questions. It supports multiple competing hypotheses per question, each with confidence estimates, assumptions, expected evidence, and falsifiers.

## Hypothesis Structure

```
Hypothesis {
  hypothesis_id: content-addressed,
  question_id: reference,
  proposition: string,
  domain: string,
  confidence: float,
  assumptions: [string],
  expected_evidence: [{type, description}],
  expected_falsifiers: [{condition, description}],
  required_experiments: [experiment_design],
  unknown_dependencies: [string],
  competing_hypotheses: [hypothesis_id],
  status: :proposed | :active | :supported | :contradicted | :rejected | :retired,
  evidence_for: [evidence_id],
  evidence_against: [evidence_id],
  created_at: integer,
  hypothesis_hash: string
}
```

## Hypothesis Generation Strategies

| Strategy | Description |
|----------|-------------|
| Deductive | Derive from existing theories |
| Inductive | Generalize from observations |
| Abductive | Infer best explanation |
| Analogical | Transfer from known domain |
| Combinatorial | Combine existing concepts |
| Generative | Novel proposal from first principles |

## Hypothesis Lifecycle

```
Proposal → Evaluation → Selection → Testing → Assessment → Resolution
```

### Proposal
One or more hypotheses generated per question using available strategies.

### Evaluation
Hypotheses scored on: explanatory power, testability, consistency with existing evidence, novelty, simplicity, domain relevance.

### Selection
Best hypotheses selected for further investigation based on score and available resources.

### Testing
Experiments designed and executed to test selected hypotheses.

### Assessment
Evidence evaluated against hypotheses. Hypotheses may be supported, contradicted, or found inconclusive.

### Resolution
Hypotheses are resolved when: sufficiently supported to become theory, contradicted and rejected, or retired after insufficient progress.

## Competition

Multiple competing hypotheses are maintained for each question until evidence distinguishes between them. The runtime never prematurely eliminates competing hypotheses.
