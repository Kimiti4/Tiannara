# Phase 17.7 — Simulation Execution Pipeline

## 1. Pipeline Stages

```
Stage 1: Twin Initialization
  Input:  ComposedWorldModel + initial conditions
  Output: DigitalTwin struct, SimulationClock=0

Stage 2: Event Scheduling
  Input:  SimulationScenario
  Output: Event timeline ordered by simulation time

Stage 3: Intervention Scheduling
  Input:  InterventionQueue
  Output: Dependency-ordered intervention list

Stage 4: Time Step Execution
  Input:  SimulationClock tick
  Output: Synchronized model state advance

Stage 5: Event Processing
  Input:  Due events at current tick
  Output: Modified twin state

Stage 6: Intervention Execution
  Input:  Due interventions
  Output: Applied interventions + state changes

Stage 7: Emergence Detection
  Input:  Current twin state + history
  Output: Detected emergent patterns

Stage 8: Metrics Computation
  Input:  Twin state
  Output: CivilizationMetrics

Stage 9: Archaeology Recording
  Input:  Tick history
  Output: Evidence ledger entry

Stage 10: Replay Checkpoint
  Input:  Tick state
  Output: Replay fingerprint
```

## 2. Pipeline Execution Flow

```elixir
def run_simulation(twin, scenario, opts) do
  with {:ok, initialized} <- DigitalTwinEngine.initialize(twin, scenario),
       {:ok, events} <- EventEngine.schedule(scenario.events),
       {:ok, interventions} <- InterventionScheduler.schedule(scenario.interventions),
       {:ok, result} <- SimulationExecutor.run(initialized, events, interventions) do
    certify_twin(result)
  end
end
```

## 3. Simulation Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| Fixed timestep | Δt = constant | Physics/engineering |
| Variable timestep | Δt adapts to dynamics | Economic/ecological |
| Event-driven | State changes only on events | Discrete systems |
| Hybrid | Mixed mode | Civilization-scale |

## 4. Failure Modes

| Stage | Failure | Action |
|-------|---------|--------|
| Initialize | Missing model | {:error, :missing_model} |
| Event | Cyclic event dependency | {:error, :cyclic_event} |
| Intervention | Invalid target | {:error, :invalid_intervention} |
| Time step | Numerical divergence | {:error, :divergence} |
| Metrics | Incomplete data | {:error, :incomplete_metrics} |
| Archaeology | Storage error | {:error, :storage_failure} |

## 5. Determinism Guarantee

A simulation is deterministic if:
- All input models are content-addressed and certified
- SimulationClock advances deterministically
- Events are ordered by (time, event_id)
- Interventions are ordered by (time, dependency, intervention_id)
- Random seeds are explicitly recorded
- Archaeology records every tick
- Replay fingerprints are computed at each checkpoint
