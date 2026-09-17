# Experiment Selection Engine

## Purpose

The Experiment Selection Engine determines which experiments should be executed to test hypotheses. It selects experiments based on expected scientific value, resource cost, risk, and constitutional alignment.

## Experiment Selection Criteria

| Criterion | Description |
|-----------|-------------|
| Scientific Value | Expected contribution to knowledge |
| Hypothesis Discrimination | Ability to distinguish between competing hypotheses |
| Resource Cost | Computational and storage resources required |
| Risk | Probability of failure or inconclusive results |
| Urgency | Time sensitivity of the question |
| Reusability | Can results be reused for other questions |
| Constitutional Alignment | Alignment with constitutional priorities |
| Cross-Domain Relevance | Relevance to other research domains |

## Experiment Selection Process

```
Active Hypotheses
       ↓
Candidate Experiments
       ↓
Design Evaluation
       ↓
Selection Scoring
       ↓
Priority Ranking
       ↓
Orchestrator Handoff
```

## Experiment Design

```
ExperimentDesign {
  experiment_id: content-addressed,
  hypothesis_id: reference,
  design_parameters: map,
  independent_variables: [variable],
  dependent_variables: [variable],
  controlled_variables: [variable],
  expected_outcomes: [{outcome, probability}],
  success_criteria: [criterion],
  failure_criteria: [criterion],
  validation_method: enum,
  design_hash: string
}
```

## Selection Governance

Every experiment selection is justified and recorded:
- Why this experiment was chosen over alternatives
- What expected value drove the selection
- What resource constraints influenced the decision
- What constitutional principles were considered
- What risk assessment was performed
