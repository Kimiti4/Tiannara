# Phase 20.7 — Experiment Scheduler

## Role

The Experiment Scheduler determines the order and resource allocation for experiment execution. Scheduling is fully deterministic — same experiment queue always produces identical execution order.

## Inputs

- Approved ExperimentPlans with resource budgets
- Current resource availability
- Experiment dependency graph
- Constitutional priority rules

## Outputs

- ExperimentSchedule with ordered execution plan and resource assignments

## Scheduling Dimensions

### Priority Determination
Experiments are prioritized by:

| Priority Factor | Weight | Description |
|-----------------|--------|-------------|
| Constitutional priority | Highest | Experiments critical to constitutional goals |
| Dependency order | High | Experiments that unlock dependent experiments |
| Resource availability | Medium | Experiments that fit available resources |
| Experiment age | Medium | Older experiments gain priority |
| Domain balance | Low | Fair distribution across domains |

### Dependency Resolution
Experiments may depend on results of other experiments. The scheduler:

1. Constructs a dependency DAG from experiment proposals
2. Detects cycles (fail closed on any cycle)
3. Orders experiments in dependency order (dependencies before dependents)
4. Uses deterministic tie-breaking (priority + timestamp + content hash)

### Resource Allocation
Resources are allocated deterministically:

| Resource | Allocation Strategy |
|----------|---------------------|
| Compute | Proportional to experiment budget, within available capacity |
| Memory | Reserved per experiment budget, fail closed if insufficient |
| Storage | Allocated for observations and artifacts |
| Domain resources | Reserved per domain budget |

### Conflict Resolution
When experiments compete for the same resources:

1. Higher constitutional priority wins
2. Earlier proposal timestamp wins
3. Smaller resource budget wins
4. Lexicographically smaller experiment_id wins

## Scheduling Constraints

- Schedule must be fully deterministic
- Schedule must respect experiment dependencies
- Schedule must respect resource availability
- Schedule must be replayable (same queue → same order)
- No experiment may be starved indefinitely (fairness guarantee)
- Resource overallocation is prohibited (fail closed)

## Output Format

The ExperimentSchedule is an immutable, content-addressed object:

| Field | Description |
|-------|-------------|
| schedule_id | Content-addressed identifier |
| experiments | Ordered list of scheduled experiments |
| resource_assignments | Resource allocation per experiment |
| time_windows | Execution time window per experiment |
| dependency_order | Dependency verification |
| total_resource_usage | Aggregate resource consumption |
| fingerprint | SHA-256 of canonical form |
