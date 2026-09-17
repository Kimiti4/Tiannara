# Planetary Runtime Metrics

## Purpose

Define the metrics used to measure planetary runtime health and performance.

## Availability Metrics

| Metric | Description |
|---|---|
| Runtime Availability | Percentage of time runtime is operational |
| Subsystem Availability | Percentage of time each subsystem is operational |
| Checkpoint Success Rate | Percentage of successful checkpoints |
| Recovery Success Rate | Percentage of successful recoveries |
| Replay Success Rate | Percentage of successful replays |

## Performance Metrics

| Metric | Description |
|---|---|
| Event Throughput | Events processed per second |
| Pipeline Latency | Time to complete one pipeline cycle |
| Synchronization Latency | Time to complete domain synchronization |
| Checkpoint Duration | Time to create a checkpoint |
| Recovery Time | Time to complete recovery |
| Event Log Growth Rate | Event log size increase per day |
| Query Latency | Time to respond to queries |

## Integrity Metrics

| Metric | Description |
|---|---|
| Checkpoint Integrity | Checkpoint hash verification pass rate |
| Replay Accuracy | Percentage of replay outputs matching originals |
| Event Log Integrity | Event log verification pass rate |
| Constitutional Compliance Rate | Percentage of actions passing constitutional checks |

## Coordination Metrics

| Metric | Description |
|---|---|
| Domain Sync Status | Percentage of domains synchronized |
| Subsystem Coordination Latency | Time to coordinate across subsystems |
| Message Delivery Rate | Percentage of messages delivered successfully |

## Metric Collection

- All metrics derived from event log data.
- No separate telemetry pipeline required.
- Metrics are themselves replayable.
- Historical metrics available for trend analysis.
- Metrics displayed on observatory.
