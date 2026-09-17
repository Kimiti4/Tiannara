# Phase 18.4 — Constitutional Attention System: Report

## Architecture Overview

The Constitutional Attention System comprises 8 interdependent components that together form a deterministic, replayable attention allocation pipeline. Each component has a single responsibility and communicates through immutable data structures.

| # | Component | Module | Responsibility |
|---|-----------|--------|----------------|
| 1 | AttentionManager | `TiannaraRuntime.Cognitive.Engines.AttentionManager` | Orchestrates the full attention cycle; maintains allocation history |
| 2 | AttentionPolicy | `TiannaraRuntime.Cognitive.Engines.AttentionPolicy` | Defines deterministic scoring criteria and evaluation logic |
| 3 | AttentionQueue | `TiannaraRuntime.Cognitive.Engines.AttentionQueue` | Priority queue ordering tasks by computed score |
| 4 | AttentionBudget | `TiannaraRuntime.Cognitive.Engines.AttentionBudget` | Immutable per-cycle budget model for 6 resource types |
| 5 | PriorityEvaluator | `TiannaraRuntime.Cognitive.Engines.PriorityEvaluator` | Wraps policy evaluation with sorting utilities |
| 6 | ResourceAllocator | `TiannaraRuntime.Cognitive.Engines.ResourceAllocator` | Maps tasks to budgets; deducts and releases resources |
| 7 | FocusState | `TiannaraRuntime.Cognitive.Engines.FocusState` | Tracks the currently active task set and allocation context |
| 8 | AttentionReplay | `TiannaraRuntime.Cognitive.Engines.AttentionReplay` | Records attention snapshots and verifies ordering determinism |

## Attention Cycle

The attention system operates in a closed loop of 8 stages:

```
  +-----------+     +-------------------+     +---------+
  |  Mission  +---->+ Priority          +---->+ Queue   |
  |  Input    |     | Evaluation        |     |         |
  +-----------+     +-------------------+     +----+----+
                                                   |
                                                   v
  +-----------+     +-------------------+     +----+----+
  | Evidence  |<----+ Dispatch          |<----+ Budget  |
  | Capture   |     |                   |     | Alloc.  |
  +-----------+     +-------------------+     +---------+
        |
        v
  +-----------+     +-------------------+     +---------+
  |  Replay   |     | Next Cycle        |     |         |
  | Generate  |     | (loop)            |     |         |
  +-----------+     +-------------------+     +---------+
```

### Stage Details

1. **Mission** — Tasks arrive from the Executive Kernel (Phase 18.2) with associated priority, dependency depth, and deadline metadata.
2. **Priority Evaluation** — `AttentionPolicy.evaluate/2` computes a score for each task using deterministic weighted criteria.
3. **Queue** — `AttentionQueue.enqueue/3` inserts tasks sorted by descending score. Ties are broken by stable hash fingerprint.
4. **Budget Allocation** — `AttentionBudget.consume/3` deducts resource units from the per-cycle budgets. `ResourceAllocator.allocate/2` maps tasks to their consumed resources.
5. **Dispatch** — The ordered queue is dispatched to the Executive Kernel for execution via the TaskDispatcher.
6. **Evidence** — Every allocation and state transition emits typed evidence records: `AttentionAllocated`, `AttentionReleased`, `BudgetConsumed`, `BudgetRemaining`, `PriorityComputed`, `QueueUpdated`, `ReplayGenerated`.
7. **Replay** — `AttentionReplay.record/1` captures a content-addressed fingerprint of the full attention state. `AttentionReplay.verify_ordering/2` confirms that task ordering is deterministic.
8. **Next Cycle** — The system loops. Budgets are reset per-cycle — they are immutable within a cycle but fully reset between cycles.

## Policies

Scoring is purely deterministic. No random numbers, no learned weights, no external state.

### Deterministic Scoring Formula

```
score = (priority × 0.4) + (1/dependency_depth × 0.3) + (deadline_urgency × 0.3)
```

| Component | Weight | Source |
|-----------|--------|--------|
| Priority weight | 0.4 | Task's `.priority` field (0.0–1.0) |
| Dependency depth weight | 0.3 | Inverse of `.dependency_depth` (1/depth) |
| Deadline urgency weight | 0.3 | Decays with distance to deadline |

### Tie-Breaking

When two tasks produce identical scores, the system uses a stable hash of the task's content fingerprint as the final sort key. This ensures that identical inputs always produce identical queue orderings.

### Default Criteria

```elixir
%{
  priority_weight: 0.4,
  dependency_depth_weight: 0.3,
  deadline_urgency_weight: 0.3
}
```

## Replay

Replay is the mechanism by which any past attention cycle can be reconstructed identically.

### Process

1. `AttentionReplay.record/1` serializes the full attention state (queue, budgets, allocations, scores) and produces a SHA-256 fingerprint.
2. On replay, the system reconstructs the queue order, budgets, allocations, priorities, and dispatch sequence from the recorded state.
3. The replayed fingerprint must match the original fingerprint exactly — any mismatch indicates non-determinism.

### Replay Guarantees

| Artifact | Reconstructed | Verification |
|----------|--------------|--------------|
| Queue ordering | Yes — sorted by score, hash tie-break | Fingerprint match |
| Budgets | Yes — immutable per-cycle | Total/available equality |
| Allocations | Yes — derived from queue + budgets | Task-to-resource map |
| Priorities | Yes — deterministic formula | Score equality |
| Dispatch sequence | Yes — queue order preserves dispatch order | Sequence match |

## Evidence Types

Every operation within the attention system emits typed evidence records. These are collected and stored alongside the mission evidence chain (Phase 18.2).

| Evidence Type | Emitted By | Fields |
|---------------|-----------|--------|
| `AttentionAllocated` | AttentionManager.allocate | allocation map, task count, timestamp |
| `AttentionReleased` | ResourceAllocator.release | resource type, amount restored, new available |
| `BudgetConsumed` | AttentionBudget.consume | resource type, amount consumed, remaining |
| `BudgetRemaining` | AttentionBudget state query | resource type, available amount |
| `PriorityComputed` | AttentionPolicy.evaluate | task fingerprint, criteria, computed score |
| `QueueUpdated` | AttentionQueue.enqueue/dequeue | queue size, top score, operation type |
| `ReplayGenerated` | AttentionReplay.record | replay fingerprint, timestamp |

## Archaeology

The archaeology subsystem answers the question: "Why did this task receive attention, and why did that task wait?"

For any given allocation cycle, the archaeology trace records:

- **Which task received attention** — pulled from the front of the priority queue
- **Why it was chosen** — its computed score (priority × weight + depth × weight + deadline × weight)
- **Why another task waited** — its lower score, or identical score but higher hash fingerprint
- **Which policy applied** — the criteria map (priority_weight, dependency_depth_weight, deadline_urgency_weight)
- **Which budget was used** — the per-cycle budget snapshot
- **Which evidence was generated** — the typed evidence records emitted
- **Which replay fingerprint was produced** — the SHA-256 hash of the full attention state

## Budget Model

The budget system tracks 6 immutable resource types per attention cycle.

| Resource | Default Total | Purpose |
|----------|--------------|---------|
| CPU | 100 | Computational units for task execution |
| Memory | 100 | Working memory capacity units |
| Simulation | 50 | Simulation engine allocation |
| Mathematics | 50 | Mathematics substrate allocation |
| Research | 50 | Research engine allocation |
| World Model | 50 | World model inference allocation |

### Rules

- Budgets are **immutable per cycle** — once a cycle begins, total budgets cannot change.
- Budgets are **fully reset** at the start of each new cycle via `AttentionBudget.rebalance/1`.
- `consume` deducts from available; returns `{:error, :insufficient_budget}` if the requested amount exceeds available.
- `release` adds back to available (capped at total).
- The budget module tracks both `total` and `available` for each resource.

## Metrics Tracked

The attention system collects the following metrics for observability and tuning:

| Metric | Description |
|--------|-------------|
| Average queue size | Mean number of tasks in the priority queue per cycle |
| Attention latency | Time from mission input to allocation decision |
| Allocation fairness | Variance in resource distribution across tasks |
| Budget utilization | Percentage of each budget consumed per cycle |
| Replay latency | Time to record and verify replay fingerprints |
| Priority stability | Variance of task scores across consecutive cycles |
| Focus switches | Number of active task set changes between cycles |
| Allocation churn | Tasks added/removed from allocation between cycles |

## Integration

### Phase 18.2 — Executive Kernel

The attention system receives tasks from the Executive Kernel's task pipeline. After allocation, the ordered queue is returned to the kernel via the AttentionCoordinator interface. The Executive Kernel then dispatches tasks through the TaskDispatcher.

**Data flow:**

```
ExecutiveKernel → AttentionManager.allocate(tasks, budgets, working_memory)
  → AttentionPolicy.evaluate(task, criteria) per task
  → AttentionQueue.enqueue(queue, task, score)
  → ResourceAllocator.allocate(tasks, budgets)
  → {:ok, %{queue, allocation, budget, scored_tasks}}
  → ExecutiveKernel receives ordered allocation → TaskDispatcher.dispatch
```

### Phase 18.3 — Working Memory

The attention system reads the current Working Memory state as an input to allocation. The `working_memory` parameter passed to `AttentionManager.allocate/3` represents the contextual state from Working Memory. Budgets for CPU and Memory directly correspond to Working Memory capacity constraints.

## No Learned Behavior

The Constitutional Attention System contains **zero learned behavior**. There is no:

- Machine learning model
- Weight adaptation based on feedback
- Reinforcement learning signal
- Gradient descent or optimization
- Probabilistic sampling
- Random seed or stochastic process

Every decision is the result of a deterministic function of the input task properties and the configured policy criteria. The system is 100% interpretable, auditable, and replayable.

## Future Extensions

### Dynamic Budget Rebalancing

A planned extension will allow budgets to be rebalanced dynamically across cycles based on utilization metrics:

- If CPU utilization is consistently low, surplus CPU can be reallocated to Memory or Simulation budgets.
- If a specific resource (e.g., Mathematics) is repeatedly exhausted, its budget can be increased at the expense of underutilized resources.
- The rebalancing algorithm will itself be deterministic and subject to the same replay guarantees.
- Rebalancing parameters (min/max per resource, rebalance interval, utilization thresholds) will be configurable but immutable per-cycle.
