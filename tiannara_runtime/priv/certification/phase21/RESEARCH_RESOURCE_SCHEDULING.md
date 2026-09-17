# Research Resource Scheduling (Phase 21.1)

## Purpose

Define constitutional scheduling for research resources. Scheduling must preserve fairness and determinism — no program may be starved or privileged outside constitutional process.

## Resources Scheduled

| Resource | Description | Allocation Unit |
|----------|-------------|-----------------|
| Compute | Processing cycles for simulations, analysis | Cycle-seconds per generation |
| Simulation | World model simulation time | Simulated years per generation |
| Proof systems | Automated theorem proving | Proof steps per generation |
| World models | Model training and refinement | Model iterations per generation |
| Engineering environments | Design, build, test environments | Environment-hours per generation |
| Experiment pipelines | Automated experiment execution | Experiment slots per generation |
| Knowledge graph resources | Knowledge integration and query | Graph operations per generation |

## Scheduling Algorithm

```
1. Collect resource requests from all programs
2. Normalize requests by program priority score
3. Apply fairness floor (minimum 10% of requested)
4. Allocate remaining capacity proportionally by priority
5. Record allocation in scheduling record
6. Verify total allocation ≤ total available capacity
```

## Fairness Guarantees

- Every program receives at least 10% of requested resources
- No program may receive more than 30% of total resources
- Unused resources are redistributed in the next scheduling cycle
- Resource hoarding is constitutionally prohibited
- All scheduling decisions are replayable

## Scheduling Record

Each scheduling cycle produces:
- Resource requests (per program)
- Priority scores used
- Allocation decisions (per program per resource)
- Fairness verification
- Allocation hash
