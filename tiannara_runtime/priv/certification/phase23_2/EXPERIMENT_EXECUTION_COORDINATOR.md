# Experiment Execution Coordinator

## Purpose

The Experiment Execution Coordinator manages the execution lifecycle of experiments — from handoff from the scheduler through completion or termination. It coordinates parallel, sequential, multi-stage, and cross-domain experiments.

## Execution Modes

| Mode | Description |
|------|-------------|
| Parallel | Multiple experiments execute simultaneously |
| Sequential | Experiments execute one after another |
| Multi-Stage | Experiment has phases executed in order |
| Cross-Domain | Experiment spans multiple research domains |
| Planetary Simulation | Experiment runs in planetary simulation context |
| Engineering Verification | Experiment validates engineering implementation |

## Execution Lifecycle

```
Scheduled → Initializing → Running → Validating → Completing → Completed
                                         ↓ (failure)
                                      Failing → Failed
```

### States

| State | Description |
|-------|-------------|
| Scheduled | Experiment has a time slot, waiting for execution |
| Initializing | Resources being acquired, environment prepared |
| Running | Experiment actively executing |
| Validating | Results being verified |
| Completing | Cleanup and result recording |
| Completed | Experiment successfully finished |
| Failing | Experiment encountered unrecoverable error |
| Failed | Experiment terminated with failure |

## Execution Handoff

The coordinator receives experiments from the scheduler and:
1. Acquires allocated resources
2. Prepares execution environment
3. Initializes experiment parameters
4. Starts execution
5. Monitors progress
6. Collects results
7. Releases resources

## Parallel Execution

The coordinator manages concurrent experiments:
- Maximum concurrency limited by resource capacity
- Resource contention resolved by priority
- Cross-experiment interference monitored
- Safety constraints enforced at runtime

## Multi-Stage Execution

Multi-stage experiments progress through phases:
```
Phase 1 → Gate → Phase 2 → Gate → Phase 3 → Complete
```
Each gate checks preconditions before allowing the next phase to start. Gates may require human or constitutional approval.

## Execution Record

```
ExperimentExecution {
  execution_id: content-addressed,
  experiment_id: reference,
  schedule_entry_id: reference,
  state: enum,
  state_transitions: [{from, to, timestamp}],
  resource_usage: resource_allocation,
  results: experiment_results,
  errors: [string],
  execution_hash: string,
  timestamp: integer
}
```
