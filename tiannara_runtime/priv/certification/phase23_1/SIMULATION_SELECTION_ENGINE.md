# Simulation Selection Engine

## Purpose

The Simulation Selection Engine determines which simulations should be executed to test predictions before physical or in-system experimentation. It selects simulations based on expected information gain, resource cost, and relevance to active hypotheses.

## Simulation Selection Criteria

| Criterion | Description |
|-----------|-------------|
| Prediction Testability | How well the simulation tests the prediction |
| Fidelity | How accurately the simulation models reality |
| Resource Cost | Computational resources required |
| Execution Time | Expected duration |
| Information Gain | Expected uncertainty reduction |
| Reusability | Can simulation be reused for other hypotheses |
| Risk | Risk of misleading results |

## Simulation Selection Process

```
Active Hypotheses
       ↓
Required Predictions
       ↓
Available Simulations
       ↓
Selection Scoring
       ↓
Priority Ranking
       ↓
Simulation Queue
       ↓
Execution
       ↓
Result Collection
```

## Simulation Types

| Type | Description |
|------|-------------|
| Analytical | Mathematical/computational model |
| Agent-Based | Emergent behavior simulation |
| Monte Carlo | Statistical sampling |
| Physics-Based | Physical law simulation |
| Hybrid | Combined simulation approaches |

## Selection Record

```
SimulationSelection {
  selection_id: content-addressed,
  hypothesis_id: reference,
  prediction_id: reference,
  simulation_type: enum,
  parameters: map,
  expected_cost: {cpu, gpu, memory, time},
  expected_information_gain: float,
  priority_score: float,
  selection_rationale: string,
  selection_hash: string
}
```
