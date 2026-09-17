# Impact Replay Model

## Purpose

Enable deterministic replay of the complete forecasting process. Every prediction must be reconstructable from stored state.

## Replayable Events

| Event | Recorded Data |
|-------|---------------|
| Impact Identification | Discovery, knowledge graph state, identified systems |
| Causal Propagation | Impact graph, causal graph state, propagation parameters |
| Scenario Generation | Impact graph, scenario parameters, generated scenarios |
| Risk/Opportunity Assessment | Scenarios, assessment results, uncertainty |
| Domain Forecasting | All prior results, domain forecast models |
| Priority Computation | Impact assessments, priority factors, computed priorities |

## Replay Properties

- Replaying the same event log produces identical forecasts
- Replay can be paused, stepped, and inspected at any point
- Partial replay from any checkpoint is supported
- Forecast evolution can be replayed step by step
