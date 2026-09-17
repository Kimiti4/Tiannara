# Experiment Dependency Engine

## Purpose

The Experiment Dependency Engine manages dependencies between experiments as a directed acyclic graph (DAG). The orchestrator never violates dependency ordering, ensuring that experiments execute only when their prerequisites are satisfied.

## Dependency Types

| Type | Description | Violation Consequence |
|------|-------------|----------------------|
| Hard | B must wait for A to complete | B cannot execute until A completes |
| Soft | B should wait for A if possible | B may execute but with degraded value |
| Optional | A improves B's value | B executes regardless, A adds context |
| Cross-Domain | A in domain X required for B in domain Y | Cross-domain coordination required |
| Simulation-First | Simulation must precede physical validation | Physical experiment blocked until simulation completes |
| Validation | A validates B's results | B must replicate before A is accepted |

## Dependency Graph Model

```
Experiment A (Physics)
    ├─ Hard ──────────────► Experiment B (Engineering)
    ├─ Soft ──────────────► Experiment C (Biology)
    └─ Simulation-First ──► Experiment D (Physical Validation)

Experiment E (Mathematics)
    └─ Optional ──────────► Experiment B (Engineering)

Experiment F (Chemistry)
    └─ Hard ──────────────► Experiment G (Materials)
                              └─ Validation ──► Experiment H (Replication)
```

## Graph Properties

- **Directed**: Dependencies have direction (prerequisite → dependent)
- **Acyclic**: Cycles are detected and prevented
- **Content-Addressed**: Each node is identified by its content hash
- **Immutable**: Edges cannot be modified, only superseded
- **Traceable**: Every edge has a creation timestamp and rationale

## Cycle Detection

Cycles are detected using topological sort. When a cycle is found:
1. The cycle is reported with all participating experiments
2. A constitutional review is triggered
3. The dependency is broken by removing the weakest edge

## Dependency Satisfaction

An experiment is ready to schedule when:
- All hard dependencies are completed
- Soft dependencies are evaluated (may proceed with penalty)
- Optional dependencies are noted
- Cross-domain dependencies are coordinated
- Simulation-first dependencies are satisfied

## Dependency Metrics

| Metric | Description |
|--------|-------------|
| Graph Depth | Longest path in dependency DAG |
| Average Dependencies | Mean dependencies per experiment |
| Critical Path | Experiments on the longest chain |
| Dependency Density | Edges / Nodes |
| Blocked Count | Experiments blocked by unsatisfied deps |
| Cycle Count | Number of cycles detected (should be 0) |
