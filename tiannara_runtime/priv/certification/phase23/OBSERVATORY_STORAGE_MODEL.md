# Observatory Storage Model

## Purpose

The Observatory Storage Model defines how all observatory data is stored, indexed, and retrieved. This includes metrics, events, replay sessions, archaeology records, snapshots, certifications, and timelines. All data is immutable and content-addressed.

## Storage Architecture

### Storage Tiers

#### In-Memory Storage (Hot)
- Recent metrics (last 24 hours)
- Recent events (last 24 hours)
- Active replay sessions
- Current state
- Fast access (< 1ms)

#### Disk Storage (Warm)
- Recent metrics (last 30 days)
- Recent events (last 30 days)
- Recent replay sessions
- Recent archaeology records
- Moderate access (< 10ms)

#### Archive Storage (Cold)
- All historical metrics
- All historical events
- All replay sessions
- All archaeology records
- All certifications
- Slow access (< 1s)

### Storage Structure

#### Metric Storage
```
metric_storage: {
  metric_id: string,
  metric_name: string,
  data_points: [data_point],
  index: time_index,
  storage_tier: :hot | :warm | :cold
}
```

#### Event Storage
```
event_storage: {
  event_id: string,
  event_type: atom,
  event_data: map,
  timestamp: integer,
  hash: string,
  storage_tier: :hot | :warm | :cold
}
```

#### Replay Session Storage
```
replay_session_storage: {
  session_id: string,
  start_timestamp: integer,
  end_timestamp: integer,
  events: [event],
  metrics: [metric_series],
  states: [state_snapshot],
  storage_tier: :warm | :cold
}
```

#### Archaeology Storage
```
archaeology_storage: {
  record_id: string,
  record_type: :event | :metric | :state | :config,
  timestamp: integer,
  data: map,
  hash: string,
  storage_tier: :warm | :cold
}
```

#### Snapshot Storage
```
snapshot_storage: {
  snapshot_id: string,
  timestamp: integer,
  observatory_state: map,
  hash: string,
  storage_tier: :warm | :cold
}
```

#### Certification Storage
```
certification_storage: {
  certificate_id: string,
  timestamp: integer,
  certificate_data: map,
  signature: string,
  storage_tier: :cold
}
```

#### Timeline Storage
```
timeline_storage: {
  event_id: string,
  event_type: atom,
  timestamp: integer,
  event_data: map,
  storage_tier: :warm | :cold
}
```

## Storage Operations

### Write Operations

#### Write Metric
```
write_metric(metric_name, data_point) -> :ok | {:error, reason}
```

#### Write Event
```
write_event(event_type, event_data) -> {:ok, event_id} | {:error, reason}
```

#### Write Replay Session
```
write_replay_session(session_data) -> {:ok, session_id} | {:error, reason}
```

#### Write Archaeology Record
```
write_archaeology_record(record_data) -> {:ok, record_id} | {:error, reason}
```

#### Write Snapshot
```
write_snapshot(snapshot_data) -> {:ok, snapshot_id} | {:error, reason}
```

#### Write Certification
```
write_certification(certification_data) -> {:ok, certificate_id} | {:error, reason}
```

#### Write Timeline Event
```
write_timeline_event(event_data) -> {:ok, event_id} | {:error, reason}
```

### Read Operations

#### Read Metric
```
read_metric(metric_id, since, until) -> {:ok, [data_point]} | {:error, reason}
```

#### Read Event
```
read_event(event_id) -> {:ok, event} | {:error, reason}
```

#### Read Replay Session
```
read_replay_session(session_id) -> {:ok, replay_session} | {:error, reason}
```

#### Read Archaeology Record
```
read_archaeology_record(record_id) -> {:ok, archaeology_record} | {:error, reason}
```

#### Read Snapshot
```
read_snapshot(snapshot_id) -> {:ok, snapshot} | {:error, reason}
```

#### Read Certification
```
read_certification(certificate_id) -> {:ok, certification} | {:error, reason}
```

#### Read Timeline Event
```
read_timeline_event(event_id) -> {:ok, timeline_event} | {:error, reason}
```

### Query Operations

#### Query Metrics
```
query_metrics(metric_name, since, until) -> {:ok, [data_point]} | {:error, reason}
```

#### Query Events
```
query_events(event_type, since, until) -> {:ok, [event]} | {:error, reason}
```

#### Query Replay Sessions
```
query_replay_sessions(since, until) -> {:ok, [replay_session]} | {:error, reason}
```

#### Query Archaeology Records
```
query_archaeology_records(record_type, since, until) -> {:ok, [archaeology_record]} | {:error, reason}
```

#### Query Snapshots
```
query_snapshots(since, until) -> {:ok, [snapshot]} | {:error, reason}
```

#### Query Certifications
```
query_certifications(since, until) -> {:ok, [certification]} | {:error, reason}
```

#### Query Timeline Events
```
query_timeline_events(event_type, since, until) -> {:ok, [timeline_event]} | {:error, reason}
```

### Delete Operations

#### Delete Metric
```
delete_metric(metric_id) -> :ok | {:error, reason}
```

#### Delete Event
```
delete_event(event_id) -> :ok | {:error, reason}
```

#### Delete Replay Session
```
delete_replay_session(session_id) -> :ok | {:error, reason}
```

#### Delete Archaeology Record
```
delete_archaeology_record(record_id) -> :ok | {:error, reason}
```

#### Delete Snapshot
```
delete_snapshot(snapshot_id) -> :ok | {:error, reason}
```

#### Delete Certification
```
delete_certification(certificate_id) -> :ok | {:error, reason}
```

#### Delete Timeline Event
```
delete_timeline_event(event_id) -> :ok | {:error, reason}
```

## Storage Metrics

### Storage Usage

#### Total Storage
```
total_storage = sum(storage_tier_usage)
```
- Unit: bytes
- Aggregation: Real-time

#### Storage by Tier
```
hot_storage = hot_tier_usage
warm_storage = warm_tier_usage
cold_storage = cold_tier_usage
```
- Unit: bytes
- Aggregation: Real-time

#### Storage Growth Rate
```
storage_growth_rate = storage_change / time_period
```
- Unit: bytes per hour
- Aggregation: Per-hour

### Storage Performance

#### Read Latency
```
read_latency = average(read_operation_time)
```
- Unit: milliseconds
- Aggregation: Per-hour

#### Write Latency
```
write_latency = average(write_operation_time)
```
- Unit: milliseconds
- Aggregation: Per-hour

#### Query Latency
```
query_latency = average(query_operation_time)
```
- Unit: milliseconds
- Aggregation: Per-hour

## Storage Configuration

### Storage Configuration
```
storage_config: {
  hot_storage_path: string,
  warm_storage_path: string,
  cold_storage_path: string,
  hot_retention: integer,
  warm_retention: integer,
  cold_retention: integer,
  compression: boolean,
  encryption: boolean
}
```

### Retention Configuration
```
retention_config: {
  hot_retention_days: integer,
  warm_retention_days: integer,
  cold_retention_days: integer,
  auto_archive: boolean,
  auto_delete: boolean
}
```

## Integration

The Observatory Storage Model integrates with:
- Time Series Engine (metric storage)
- Event Collection Engine (event storage)
- Streaming Engine (replay session storage)
- Observatory Platform (all storage)

## Acceptance Criteria

✓ Three storage tiers
✓ Seven data types stored
✓ Write operations
✓ Read operations
✓ Query operations
✓ Delete operations
✓ Storage metrics
✓ Storage configuration
✓ Integration with observatory
