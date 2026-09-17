# Time Series Engine

## Purpose

The Time Series Engine stores, indexes, and queries time-series metric data collected from the Telemetry Pipeline. It provides efficient storage and fast querying of metric data across all time horizons.

## Time Series Architecture

```
Telemetry Pipeline
  ↓
Time Series Engine
  ├─→ Metric Storage (in-memory)
  ├─→ Metric Index (time-based)
  ├─→ Metric Aggregation (pre-computed)
  └─→ Metric Queries (read-only)
```

## Metric Storage

### Storage Structure

Each metric is stored as:
```
metric_series: {
  metric_id: string,
  metric_name: string,
  metric_type: atom,
  subsystem: atom,
  tags: map,
  data_points: [data_point],
  created_at: integer,
  last_updated: integer
}
```

Each data point contains:
```
data_point: {
  timestamp: integer,
  value: float | integer,
  metadata: map
}
```

### Storage Tiers

#### In-Memory Storage (Hot)
- Last 24 hours of data
- Fast queries (< 1ms)
- High write throughput
- Limited capacity

#### Disk Storage (Warm)
- Last 30 days of data
- Moderate queries (< 10ms)
- Moderate write throughput
- Large capacity

#### Archive Storage (Cold)
- All historical data
- Slow queries (< 1s)
- Read-only
- Infinite capacity

## Metric Types

### Gauge Metrics
- Point-in-time values
- Example: CPU utilization, memory usage
- Storage: Latest value + history

### Counter Metrics
- Monotonically increasing values
- Example: Event count, discovery count
- Storage: Counter value + rate

### Histogram Metrics
- Distribution of values
- Example: Event size, latency
- Storage: Histogram buckets + statistics

### Summary Metrics
- Pre-computed statistics
- Example: Average, percentiles
- Storage: Summary statistics

## Metric Indexing

### Time-Based Index
- Index by timestamp
- Fast range queries
- Efficient time-series operations

### Tag-Based Index
- Index by tags
- Fast tag-based queries
- Efficient filtering

### Metric-Based Index
- Index by metric name
- Fast metric discovery
- Efficient aggregation

## Metric Aggregation

### Pre-Computed Aggregations

#### Minute Aggregations
- Average per minute
- Min per minute
- Max per minute
- Count per minute

#### Hour Aggregations
- Average per hour
- Min per hour
- Max per hour
- Count per hour

#### Day Aggregations
- Average per day
- Min per day
- Max per day
- Count per day

#### Week Aggregations
- Average per week
- Min per week
- Max per week
- Count per week

#### Month Aggregations
- Average per month
- Min per month
- Max per month
- Count per month

### On-Demand Aggregations

#### Time Range Aggregations
- Aggregate over arbitrary time range
- Custom aggregation functions
- Dynamic grouping

#### Tag-Based Aggregations
- Aggregate by tag values
- Group by tag combinations
- Filter by tag predicates

## Metric Queries

### Time Range Queries
```
query_time_range(metric_name, since, until) -> [data_point]
```

### Latest Value Queries
```
query_latest(metric_name) -> data_point
```

### Aggregation Queries
```
query_aggregate(metric_name, since, until, aggregation) -> aggregated_value
```

### Tag-Based Queries
```
query_by_tags(metric_name, tags) -> [data_point]
```

### Rate Queries
```
query_rate(metric_name, since, until) -> rate
```

### Percentile Queries
```
query_percentile(metric_name, since, until, percentile) -> percentile_value
```

## Retention Policies

### Hot Data Retention
- Retention: 24 hours
- Storage: In-memory
- Query speed: < 1ms

### Warm Data Retention
- Retention: 30 days
- Storage: Disk
- Query speed: < 10ms

### Cold Data Retention
- Retention: Forever
- Storage: Archive
- Query speed: < 1s

## Data Lifecycle

1. **Ingestion**: Data received from Telemetry Pipeline
2. **Storage**: Data stored in appropriate tier
3. **Indexing**: Data indexed for fast queries
4. **Aggregation**: Pre-computed aggregations created
5. **Querying**: Data served for queries
6. **Archival**: Old data moved to archive
7. **Purge**: Very old data purged (if configured)

## Time Series Metrics

Track:
- Metrics stored
- Data points stored
- Storage usage by tier
- Query latency
- Query count
- Aggregation count

## Integration

The Time Series Engine integrates with:
- Telemetry Pipeline (data ingestion)
- Metric Engine (metric queries)
- Streaming Engine (real-time updates)
- Storage Model (archival)

## Security

Time Series Engine shall:
- Never modify original data
- Only store and query
- Maintain data lineage
- Ensure zero modification

## Acceptance Criteria

✓ Efficient metric storage
✓ Fast metric queries
✓ Time-based indexing
✓ Tag-based indexing
✓ Pre-computed aggregations
✓ Retention policies
✓ Data lifecycle management
✓ Query performance observable
