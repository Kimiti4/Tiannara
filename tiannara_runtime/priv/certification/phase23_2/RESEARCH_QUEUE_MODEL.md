# Research Queue Model

## Purpose

The Research Queue Model defines how candidate experiments are queued for evaluation, prioritization, scheduling, and execution. The queue operates as a deterministic, content-addressed data structure that preserves ordering decisions immutably.

## Queue Structure

```
ResearchQueue {
  queue_id: content-addressed,
  epoch: integer,
  entries: [
    {
      experiment_id: reference,
      queue_position: integer,
      enqueue_timestamp: integer,
      priority_score: float,
      priority_tier: enum,
      status: :waiting | :evaluating | :ready | :scheduled | :executing | :completed | :failed | :cancelled,
      status_history: [{status, timestamp, rationale}],
      dequeue_timestamp: integer (optional),
      dequeue_reason: string (optional),
      entry_hash: string
    }
  ],
  queue_hash: string,
  timestamp: integer
}
```

## Queue Operations

### Enqueue
Experiments enter the queue when:
- Proposed by research program
- Spawned by discovery feedback
- Required by constitutional mandate
- Re-scheduled from adaptation

### Reorder
Queue order is determined by:
- Primary: Priority score (descending)
- Secondary: Enqueue timestamp (ascending)
- Tertiary: Dependency satisfaction
- Quaternary: Constitutional override

### Dequeue
Experiments leave the queue when:
- Scheduled for execution
- Cancelled
- Superseded
- Program terminated

## Queue Views

| View | Description |
|------|-------------|
| By Priority | Sorted by priority score |
| By Program | Grouped by research program |
| By Domain | Grouped by research domain |
| By Status | Filtered by queue status |
| By Wait Time | Sorted by enqueue duration |

## Queue Metrics

| Metric | Description |
|--------|-------------|
| Queue Depth | Total entries in queue |
| Wait Time | Time from enqueue to dequeue |
| Throughput | Experiments processed per epoch |
| Stale Count | Experiments waiting beyond threshold |
| Churn Rate | Entry/exit rate |
| Priority Distribution | Distribution across priority tiers |
| Domain Distribution | Distribution across research domains |

## Determinism

Queue state is fully deterministic:
- Ordering is reproducible from same inputs
- All mutations are content-addressed
- Queue history is replayable
- Queue archaeology reconstructs ordering decisions
