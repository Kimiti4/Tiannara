# API Model

## Purpose

The API Model defines all read-only APIs for the Constitutional Observatory Platform. These APIs provide access to metrics, telemetry, replay, archaeology, timeline, certification, snapshots, streaming, historical queries, and research export. All APIs are read-only and never modify runtime state.

## API Architecture

### API Categories

#### Metrics API
- Query metrics
- Query metric series
- Query metric aggregations
- Query metric trends

#### Telemetry API
- Query telemetry events
- Stream telemetry events
- Query telemetry by type
- Query telemetry by subsystem

#### Replay API
- Query replay sessions
- Start replay
- Control replay
- Export replay

#### Archaeology API
- Query archaeology records
- Reconstruct state
- Query archaeology lineage
- Export archaeology

#### Timeline API
- Query timeline events
- Query timeline by type
- Query timeline by date range
- Export timeline

#### Certification API
- Query certifications
- Query certification by level
- Query certification status
- Export certification

#### Snapshot API
- Query snapshots
- Query snapshot by timestamp
- Restore snapshot
- Export snapshot

#### Streaming API
- Subscribe to events
- Subscribe to metrics
- Control streaming
- Manage subscriptions

#### Historical Query API
- Query historical data
- Query across time horizons
- Compare time periods
- Export historical data

#### Research Export API
- Export research data
- Export in multiple formats
- Export with metadata
- Export with citations

## API Structure

### Metrics API

#### Query Metrics
```
GET /api/v1/metrics/{metric_name}
Query params: since, until, aggregation
Response: [data_point]
```

#### Query Metric Series
```
GET /api/v1/metrics/{metric_name}/series
Query params: since, until
Response: metric_series
```

#### Query Metric Aggregations
```
GET /api/v1/metrics/{metric_name}/aggregations
Query params: since, until, aggregation_type
Response: aggregation_result
```

#### Query Metric Trends
```
GET /api/v1/metrics/{metric_name}/trends
Query params: since, until, window
Response: trend_result
```

### Telemetry API

#### Query Telemetry Events
```
GET /api/v1/telemetry/events
Query params: event_type, subsystem, since, until
Response: [telemetry_event]
```

#### Stream Telemetry Events
```
WebSocket /api/v1/telemetry/stream
Params: event_types, subsystems
Response: Stream of telemetry_event
```

#### Query Telemetry by Type
```
GET /api/v1/telemetry/types/{event_type}
Query params: since, until
Response: [telemetry_event]
```

#### Query Telemetry by Subsystem
```
GET /api/v1/telemetry/subsystems/{subsystem}
Query params: since, until
Response: [telemetry_event]
```

### Replay API

#### Query Replay Sessions
```
GET /api/v1/replay/sessions
Query params: since, until
Response: [replay_session]
```

#### Start Replay
```
POST /api/v1/replay/start
Body: {session_id, start_timestamp}
Response: {replay_id, status}
```

#### Control Replay
```
POST /api/v1/replay/{replay_id}/control
Body: {action: "pause" | "resume" | "stop" | "seek", timestamp}
Response: {status}
```

#### Export Replay
```
GET /api/v1/replay/{replay_id}/export
Query params: format
Response: File download
```

### Archaeology API

#### Query Archaeology Records
```
GET /api/v1/archaeology/records
Query params: record_type, since, until
Response: [archaeology_record]
```

#### Reconstruct State
```
GET /api/v1/archaeology/reconstruct/{timestamp}
Response: observatory_state
```

#### Query Archaeology Lineage
```
GET /api/v1/archaeology/lineage/{record_id}
Response: [archaeology_record]
```

#### Export Archaeology
```
GET /api/v1/archaeology/export
Query params: since, until, format
Response: File download
```

### Timeline API

#### Query Timeline Events
```
GET /api/v1/timeline/events
Query params: event_type, since, until
Response: [timeline_event]
```

#### Query Timeline by Type
```
GET /api/v1/timeline/types/{event_type}
Query params: since, until
Response: [timeline_event]
```

#### Query Timeline by Date Range
```
GET /api/v1/timeline/range
Query params: since, until
Response: [timeline_event]
```

#### Export Timeline
```
GET /api/v1/timeline/export
Query params: since, until, format
Response: File download
```

### Certification API

#### Query Certifications
```
GET /api/v1/certifications
Query params: since, until
Response: [certification]
```

#### Query Certification by Level
```
GET /api/v1/certifications/level/{level}
Query params: since, until
Response: [certification]
```

#### Query Certification Status
```
GET /api/v1/certifications/status/{certificate_id}
Response: certification_status
```

#### Export Certification
```
GET /api/v1/certifications/export/{certificate_id}
Query params: format
Response: File download
```

### Snapshot API

#### Query Snapshots
```
GET /api/v1/snapshots
Query params: since, until
Response: [snapshot]
```

#### Query Snapshot by Timestamp
```
GET /api/v1/snapshots/{timestamp}
Response: snapshot
```

#### Restore Snapshot
```
POST /api/v1/snapshots/{snapshot_id}/restore
Response: {status}
```

#### Export Snapshot
```
GET /api/v1/snapshots/{snapshot_id}/export
Query params: format
Response: File download
```

### Streaming API

#### Subscribe to Events
```
WebSocket /api/v1/streaming/events
Params: event_types, subsystems
Response: Stream of events
```

#### Subscribe to Metrics
```
WebSocket /api/v1/streaming/metrics
Params: metric_names, aggregation
Response: Stream of metrics
```

#### Control Streaming
```
POST /api/v1/streaming/control
Body: {action: "pause" | "resume" | "stop", subscription_id}
Response: {status}
```

#### Manage Subscriptions
```
GET /api/v1/streaming/subscriptions
Response: [subscription]

DELETE /api/v1/streaming/subscriptions/{subscription_id}
Response: {status}
```

### Historical Query API

#### Query Historical Data
```
GET /api/v1/historical/data
Query params: data_type, since, until
Response: [data_point]
```

#### Query Across Time Horizons
```
GET /api/v1/historical/horizons
Query params: data_type, horizons
Response: {horizon: [data_point]}
```

#### Compare Time Periods
```
GET /api/v1/historical/compare
Query params: data_type, period1, period2
Response: comparison_result
```

#### Export Historical Data
```
GET /api/v1/historical/export
Query params: data_type, since, until, format
Response: File download
```

### Research Export API

#### Export Research Data
```
GET /api/v1/research/export
Query params: data_type, since, until
Response: File download
```

#### Export in Multiple Formats
```
GET /api/v1/research/export/{format}
Query params: data_type, since, until
Response: File download
```

#### Export with Metadata
```
GET /api/v1/research/export/with-metadata
Query params: data_type, since, until, format
Response: File download
```

#### Export with Citations
```
GET /api/v1/research/export/with-citations
Query params: data_type, since, until, format
Response: File download
```

## API Security

### Authentication
- Read-only token required
- Token scoped to specific APIs
- Token expiration enforced

### Authorization
- Read-only access only
- No write access
- No runtime modification

### Rate Limiting
- Requests per minute limit
- Requests per hour limit
- Requests per day limit

## API Metrics

### API Usage

#### Request Count
```
request_count = total_requests
```
- Unit: count
- Aggregation: Per-hour

#### Request Rate
```
request_rate = requests / time_period
```
- Unit: requests per minute
- Aggregation: Per-minute

#### Error Rate
```
error_rate = error_requests / total_requests
```
- Unit: ratio (0-1)
- Aggregation: Per-hour

### API Performance

#### Response Latency
```
response_latency = average(response_time)
```
- Unit: milliseconds
- Aggregation: Per-hour

#### Throughput
```
throughput = requests / time_period
```
- Unit: requests per second
- Aggregation: Per-second

## Integration

The API Model integrates with:
- Observatory Platform (API rendering)
- Metric Engine (metric queries)
- Time Series Engine (time series queries)
- Storage Model (data storage)

## Acceptance Criteria

✓ 10 API categories
✓ Read-only APIs
✓ All data types accessible
✓ API security
✓ API metrics
✓ Integration with observatory
