# Long-Horizon Model

## Purpose

The Long-Horizon Model defines how the Observatory supports observation over hours, days, weeks, months, and years, with metrics separated into active runtime, elapsed time, availability, continuity, recovery, and checkpointing.

## Long-Horizon Architecture

### Time Horizons

#### Hour Horizon
- Resolution: Seconds
- Retention: 24 hours
- Detail: High
- Use case: Real-time monitoring

#### Day Horizon
- Resolution: Minutes
- Retention: 7 days
- Detail: Medium
- Use case: Daily analysis

#### Week Horizon
- Resolution: Hours
- Retention: 4 weeks
- Detail: Medium
- Use case: Weekly trends

#### Month Horizon
- Resolution: Days
- Retention: 12 months
- Detail: Low
- Use case: Monthly analysis

#### Year Horizon
- Resolution: Weeks
- Retention: Forever
- Detail: Low
- Use case: Yearly evolution

### Metric Separation

#### Active Runtime
- Actual computation time
- Excludes idle time
- Excludes recovery time
- Use case: Performance analysis

#### Elapsed Time
- Wall clock time
- Includes all time
- Use case: Availability analysis

#### Availability
- Uptime percentage
- Downtime tracking
- Recovery success
- Use case: Reliability analysis

#### Continuity
- Continuity score
- Knowledge preservation
- Experiment preservation
- Use case: Continuity analysis

#### Recovery
- Recovery count
- Recovery success rate
- Recovery duration
- Use case: Recovery analysis

#### Checkpointing
- Checkpoint frequency
- Checkpoint size
- Checkpoint success
- Use case: Persistence analysis

## Long-Horizon Visualization

### Time Horizon View

#### Multi-Horizon View
- Multiple time horizons shown
- Switch between horizons
- Compare horizons

#### Horizon Detail
- Current horizon detail
- Time range
- Resolution
- Retention

### Metric Separation View

#### Separated Metrics
- Active runtime metrics
- Elapsed time metrics
- Availability metrics
- Continuity metrics
- Recovery metrics
- Checkpointing metrics

#### Comparison View
- Compare metrics across horizons
- Compare metrics across separation
- Highlight differences

## Long-Horizon Metrics

### Availability Metrics

#### Uptime
```
uptime = active_runtime / elapsed_time
```
- Unit: ratio (0-1)
- Horizon: Hour, Day, Week, Month, Year

#### Downtime
```
downtime = elapsed_time - active_runtime
```
- Unit: seconds
- Horizon: Hour, Day, Week, Month, Year

#### Availability Score
```
availability_score = uptime * 100
```
- Unit: percentage
- Horizon: Hour, Day, Week, Month, Year

### Continuity Metrics

#### Continuity Score
```
continuity_score = knowledge_preservation * experiment_preservation
```
- Unit: score (0-1)
- Horizon: Hour, Day, Week, Month, Year

#### Knowledge Preservation
```
knowledge_preservation = preserved_knowledge / total_knowledge
```
- Unit: ratio (0-1)
- Horizon: Hour, Day, Week, Month, Year

#### Experiment Preservation
```
experiment_preservation = preserved_experiments / total_experiments
```
- Unit: ratio (0-1)
- Horizon: Hour, Day, Week, Month, Year

### Recovery Metrics

#### Recovery Count
```
recovery_count = total_recoveries
```
- Unit: count
- Horizon: Hour, Day, Week, Month, Year

#### Recovery Success Rate
```
recovery_success_rate = successful_recoveries / total_recoveries
```
- Unit: ratio (0-1)
- Horizon: Hour, Day, Week, Month, Year

#### Recovery Duration
```
recovery_duration = average(recovery_completion_time - recovery_start_time)
```
- Unit: seconds
- Horizon: Hour, Day, Week, Month, Year

### Checkpointing Metrics

#### Checkpoint Frequency
```
checkpoint_frequency = checkpoints_created / time_period
```
- Unit: checkpoints per hour
- Horizon: Hour, Day, Week, Month, Year

#### Checkpoint Size
```
checkpoint_size = average(checkpoint_sizes)
```
- Unit: bytes
- Horizon: Hour, Day, Week, Month, Year

#### Checkpoint Success Rate
```
checkpoint_success_rate = successful_checkpoints / total_checkpoints
```
- Unit: ratio (0-1)
- Horizon: Hour, Day, Week, Month, Year

## Long-Horizon Queries

### Time Horizon Queries
```
query_time_horizon(horizon) -> horizon_config
query_metrics_for_horizon(horizon, metric_name) -> [data_point]
query_metrics_across_horizons(metric_name) -> {horizon: [data_point]}
```

### Metric Separation Queries
```
query_active_runtime_metrics(metric_name) -> [data_point]
query_elapsed_time_metrics(metric_name) -> [data_point]
query_availability_metrics() -> availability_metrics
query_continuity_metrics() -> continuity_metrics
query_recovery_metrics() -> recovery_metrics
query_checkpointing_metrics() -> checkpointing_metrics
```

### Long-Horizon Analysis
```
query_trend_over_horizon(horizon, metric_name) -> trend
query_comparison_across_horizons(metric_name) -> comparison
query_anomaly_over_horizon(horizon, metric_name) -> anomalies
```

## Long-Horizon Features

### Time Navigation

#### Horizon Selection
- Select time horizon
- Switch between horizons
- Compare horizons

#### Time Range Selection
- Select time range within horizon
- Quick ranges
- Custom range

#### Time Jump
- Jump to specific time
- Jump to milestone
- Jump to event

### Metric Filtering

#### Filter by Separation
- Filter by active runtime
- Filter by elapsed time
- Filter by availability
- Filter by continuity
- Filter by recovery
- Filter by checkpointing

#### Filter by Metric Type
- Filter by metric category
- Filter by metric name
- Filter by metric unit

### Analysis Features

#### Trend Analysis
- Detect trends over time
- Highlight significant trends
- Predict future trends

#### Anomaly Detection
- Detect anomalies over time
- Highlight significant anomalies
- Investigate anomalies

#### Correlation Analysis
- Find correlated metrics
- Show correlation strength
- Highlight significant correlations

## Integration

The Long-Horizon Model integrates with:
- Observatory Platform (visualization rendering)
- Time Series Engine (metric storage)
- Metric Engine (metric queries)
- Storage Model (historical data)

## Acceptance Criteria

✓ 5 time horizons supported
✓ 6 metric separations
✓ Long-horizon metrics defined
✓ Long-horizon queries
✓ Long-horizon features
✓ Time navigation
✓ Metric filtering
✓ Analysis features
✓ Integration with observatory
