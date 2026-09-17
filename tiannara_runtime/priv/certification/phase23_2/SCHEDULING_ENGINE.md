# Scheduling Engine

## Purpose

The Scheduling Engine determines when experiments execute. It produces a deterministic schedule that respects priority ordering, dependency constraints, resource availability, and constitutional policies. Scheduling is fully replayable.

## Scheduling Policies

| Policy | Trigger | Description |
|--------|---------|-------------|
| Immediate | Experiment ready | Execute as soon as resources available |
| Deferred | Future timestamp | Execute at specified future time |
| Periodic | Recurring interval | Execute on a fixed cadence |
| Event-Triggered | System event | Execute when specific event occurs |
| Resource-Triggered | Resource availability | Execute when resources free |
| Discovery-Triggered | New discovery | Execute when discovery changes priority |
| Constitution-Triggered | Constitutional directive | Execute when constitution requires |

## Schedule Structure

```
ExperimentSchedule {
  schedule_id: content-addressed,
  epoch: integer,
  entries: [
    {
      experiment_id: reference,
      policy: enum,
      priority_score: float,
      scheduled_start: integer,
      scheduled_end: integer,
      allocated_resources: resource_allocation,
      dependencies_satisfied: boolean,
      status: :scheduled | :running | :completed | :failed,
      schedule_hash: string
    }
  ],
  schedule_hash: string,
  timestamp: integer
}
```

## Scheduling Algorithm

```
For each scheduling epoch:
  1. Collect all ready experiments (dependencies satisfied)
  2. Sort by priority score (descending)
  3. Filter by resource availability
  4. Assign time slots respecting:
     a. Resource capacity
     b. Dependency ordering
     c. Policy constraints
     d. Constitutional priorities
  5. Produce deterministic schedule
  6. Record schedule hash
```

## Schedule Stability

The scheduling engine minimizes schedule changes:
- Schedule is frozen for the current epoch
- Only emergency constitutional overrides can alter frozen schedules
- Schedule changes are recorded as deltas
- Original schedule is preserved for replay

## Schedule Metrics

| Metric | Description |
|--------|-------------|
| Schedule Utilization | Used / Available time slots |
| Queue Depth | Experiments waiting for scheduling |
| Average Wait Time | Time from ready to scheduled |
| Schedule Adherence | % of experiments starting on time |
| Reschedule Rate | % of experiments rescheduled |
| Schedule Horizon | How far into the future schedules extend |
