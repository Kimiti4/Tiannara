# Streaming Engine

## Purpose

The Streaming Engine provides real-time streaming of telemetry events and metrics to connected clients. It enables live observatory displays, real-time alerts, and continuous monitoring.

## Streaming Architecture

```
Telemetry Pipeline
  ↓
Streaming Engine
  ├─→ Client Connections (WebSocket)
  ├─→ Stream Subscriptions (event filters)
  ├─→ Stream Delivery (real-time)
  └─→ Stream Management (lifecycle)
```

## Streaming Modes

### Event Streaming
Stream individual events as they occur:
- Scientific discoveries
- Engineering designs
- Evolution events
- Runtime events
- Alerts

### Metric Streaming
Stream metric updates in real-time:
- Gauge values
- Counter increments
- Histogram updates
- Summary statistics

### Aggregated Streaming
Stream pre-aggregated metrics:
- Per-second aggregations
- Per-minute aggregations
- Per-hour aggregations
- Custom aggregations

### Replay Streaming
Stream historical events:
- Historical event replay
- Historical metric replay
- Time-travel queries
- Replay sessions

## Client Connections

### WebSocket Connections
- Persistent connections
- Bi-directional communication
- Low latency
- Automatic reconnection

### Connection Lifecycle

1. **Connection**: Client connects via WebSocket
2. **Authentication**: Client authenticates (read-only token)
3. **Subscription**: Client subscribes to streams
4. **Streaming**: Events delivered in real-time
5. **Unsubscription**: Client unsubscribes from streams
6. **Disconnection**: Client disconnects

## Stream Subscriptions

### Event Subscriptions
```
subscribe_events(event_types, filters) -> stream_id
```

Subscribe to specific event types with optional filters:
- Event type filter
- Subsystem filter
- Tag filter
- Priority filter

### Metric Subscriptions
```
subscribe_metrics(metric_names, aggregation) -> stream_id
```

Subscribe to specific metrics with aggregation:
- Metric name filter
- Aggregation type (raw, per-second, per-minute)
- Tag filter

### Combined Subscriptions
```
subscribe_combined(event_types, metric_names, filters) -> stream_id
```

Subscribe to both events and metrics with filters.

## Stream Delivery

### Event Delivery
Events delivered as JSON:
```
{
  "type": "event",
  "event": {
    "event_id": "...",
    "timestamp": 1234567890,
    "event_type": "discovery_validated",
    "subsystem": "scientific_discovery",
    "event_data": {...},
    "metadata": {...}
  }
}
```

### Metric Delivery
Metrics delivered as JSON:
```
{
  "type": "metric",
  "metric": {
    "metric_id": "...",
    "metric_name": "discovery_rate",
    "timestamp": 1234567890,
    "value": 42.0,
    "metadata": {...}
  }
}
```

### Aggregated Metric Delivery
Aggregated metrics delivered as JSON:
```
{
  "type": "aggregated_metric",
  "metric": {
    "metric_id": "...",
    "metric_name": "discovery_rate",
    "aggregation": "per_minute",
    "timestamp": 1234567890,
    "value": 2520.0,
    "metadata": {...}
  }
}
```

## Stream Management

### Stream Lifecycle

1. **Created**: Stream created for client
2. **Active**: Stream actively delivering data
3. **Paused**: Stream temporarily paused
4. **Resumed**: Stream resumed after pause
5. **Closed**: Stream closed

### Stream Controls

#### Pause Stream
```
pause_stream(stream_id) -> :ok | {:error, reason}
```

#### Resume Stream
```
resume_stream(stream_id) -> :ok | {:error, reason}
```

#### Close Stream
```
close_stream(stream_id) -> :ok | {:error, reason}
```

### Stream Throttling

#### Backpressure Detection
- Detect slow clients
- Detect network congestion
- Detect resource exhaustion

#### Throttling Strategies
- Reduce delivery rate
- Drop low-priority events
- Buffer events
- Disconnect slow clients

## Stream Configuration

### Client Configuration
```
stream_config: {
  client_id: string,
  event_types: [atom],
  metric_names: [string],
  filters: map,
  aggregation: atom,
  batch_size: integer,
  batch_timeout: integer
}
```

### Server Configuration
```
server_config: {
  max_connections: integer,
  max_streams_per_connection: integer,
  max_events_per_second: integer,
  max_metrics_per_second: integer,
  batch_size: integer,
  batch_timeout: integer,
  compression: boolean
}
```

## Stream Metrics

Track:
- Active connections
- Active streams
- Events delivered per second
- Metrics delivered per second
- Delivery latency
- Client errors
- Stream errors

## Integration

The Streaming Engine integrates with:
- Telemetry Pipeline (event/metric reception)
- Time Series Engine (metric queries)
- Client applications (WebSocket connections)
- Observatory Platform (live displays)

## Security

Streaming Engine shall:
- Never modify data
- Only deliver read-only data
- Authenticate all clients
- Enforce read-only access
- Maintain stream lineage

## Acceptance Criteria

✓ Real-time event streaming
✓ Real-time metric streaming
✓ Aggregated metric streaming
✓ Replay streaming
✓ WebSocket connections
✓ Stream subscriptions
✓ Stream delivery
✓ Stream management
✓ Stream throttling
✓ Stream metrics observable
