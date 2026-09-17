# Phase 20.7 — Experiment Execution Model

## Role

The Experiment Execution Model defines how experiments are executed deterministically, how observations are captured, and how execution artifacts are preserved. Execution is fully deterministic — same experiment, same environment, same inputs always produces identical outputs.

## Execution Phases

### Phase 1 — Environment Initialization
Prepare the deterministic execution environment.

| Step | Description |
|------|-------------|
| Load environment snapshot | Restore environment to initialized state |
| Verify environment hash | Confirm environment matches stored fingerprint |
| Configure parameters | Set experiment parameters from ExperimentPlan |
| Initialize controls | Set up control conditions |
| Record pre-execution state | Capture state hash before execution begins |

### Phase 2 — Treatment Application
Apply experimental treatments in deterministic order.

| Step | Description |
|------|-------------|
| Apply independent variable | Set independent variable to specified level |
| Verify treatment integrity | Confirm treatment applied correctly |
| Record treatment state | Capture state hash after treatment |
| Allow response period | Wait for dependent variable response (deterministic duration) |

### Phase 3 — Observation Collection
Capture all observations during execution.

| Observation Type | Description | Collection Method |
|------------------|-------------|-------------------|
| Dependent variable | Primary measurements | Record at specified intervals |
| Control variable | Control measurements | Record simultaneously |
| Environmental | Context measurements | Record continuously |
| Timing | Timing data | Record per operation |
| Resource | Resource consumption | Record per phase |

All observations are timestamped with deterministic timestamps and recorded as immutable artifacts.

### Phase 4 — Execution Recording
Record complete execution trace.

| Artifact | Description |
|----------|-------------|
| Execution trace | Ordered sequence of all operations |
| State transitions | State hash before and after each operation |
| Observation log | All observations in structured format |
| Timing log | Timing data for all operations |
| Resource log | Resource consumption data |
| Error log | Any errors, warnings, or anomalies |

### Phase 5 — Post-Execution State Capture
Capture final state after experiment completion.

| Step | Description |
|------|-------------|
| Capture final state | State hash after all observations collected |
| Verify against environment | Confirm environment in expected final state |
| Collect artifacts | Package all execution artifacts |
| Generate execution_hash | SHA-256 of complete execution record |

## Execution Determinism

- Execution environment is initialized from a deterministic snapshot
- All random-like operations use deterministic seeds (from unique integers, not entropy)
- Execution order within the experiment is fully specified
- All timing is deterministic (simulated steps, not wall clock)
- Resource allocation is fixed before execution begins
- Same experiment plan always produces identical execution trace

## Safety During Execution

| Condition | Response |
|-----------|----------|
| Resource exhaustion | Pause execution, capture partial results, terminate |
| Safety limit reached | Immediately terminate, capture all state |
| Invalid state detected | Abort, flag for failure analysis |
| Determinism violation detected | Abort, flag for investigation |

## Output Format

The ExperimentRun is an immutable, content-addressed object:

| Field | Description |
|-------|-------------|
| run_id | Content-addressed identifier |
| plan | Reference to ExperimentPlan |
| environment | Environment snapshot hash |
| execution_trace | Ordered execution trace |
| observations | Structured observation set |
| timing_data | Deterministic timing log |
| resource_data | Resource consumption log |
| error_log | Any errors or anomalies |
| execution_hash | SHA-256 of complete execution record |
| status | Completed/Failed/Aborted |
| fingerprint | SHA-256 of canonical form |
