# Cognitive Metric Engine

## Purpose

The Cognitive Metric Engine computes, stores, and queries all cognitive metrics related to reasoning, planning, memory, reflection, meta-cognition, executive stability, attention, and decision quality.

## Cognitive Metrics

### Reasoning Metrics

#### Reasoning Quality
```
reasoning_quality = average(reasoning_quality_scores)
```
- Unit: score (0-1)
- Aggregation: per-hour, per-day

#### Reasoning Depth
```
reasoning_depth = average(reasoning_depth_scores)
```
- Unit: score (0-1)
- Aggregation: per-hour, per-day

#### Reasoning Speed
```
reasoning_speed = reasoning_operations / time_period
```
- Unit: operations per second
- Aggregation: per-second, per-minute

### Planning Metrics

#### Planning Quality
```
planning_quality = average(planning_quality_scores)
```
- Unit: score (0-1)
- Aggregation: per-hour, per-day

#### Planning Success Rate
```
planning_success_rate = plans_completed / plans_created
```
- Unit: ratio (0-1)
- Aggregation: per-day, per-week

#### Planning Efficiency
```
planning_efficiency = plans_completed / planning_time
```
- Unit: plans per hour
- Aggregation: per-hour, per-day

### Memory Metrics

#### Memory Health
```
memory_health = memory_utilization_score
```
- Unit: score (0-1)
- Aggregation: per-hour, per-day

#### Memory Utilization
```
memory_utilization = memory_used / memory_available
```
- Unit: ratio (0-1)
- Aggregation: per-hour, per-day

#### Memory Access Latency
```
memory_access_latency = average(memory_access_time)
```
- Unit: milliseconds
- Aggregation: per-hour, per-day

### Reflection Metrics

#### Reflection Quality
```
reflection_quality = average(reflection_quality_scores)
```
- Unit: score (0-1)
- Aggregation: per-day, per-week

#### Reflection Frequency
```
reflection_frequency = reflections_performed / time_period
```
- Unit: reflections per hour
- Aggregation: per-hour, per-day

#### Reflection Impact
```
reflection_impact = improvements_from_reflection / reflections_performed
```
- Unit: ratio
- Aggregation: per-day, per-week

### Meta-Cognition Metrics

#### Meta-Cognition Quality
```
meta_cognition_quality = average(meta_cognition_quality_scores)
```
- Unit: score (0-1)
- Aggregation: per-day, per-week

#### Meta-Cognition Frequency
```
meta_cognition_frequency = meta_cognition_operations / time_period
```
- Unit: operations per hour
- Aggregation: per-hour, per-day

#### Meta-Cognition Accuracy
```
meta_cognition_accuracy = correct_meta_cognition / meta_cognition_operations
```
- Unit: ratio (0-1)
- Aggregation: per-day, per-week

### Executive Stability Metrics

#### Executive Stability
```
executive_stability = stability_score
```
- Unit: score (0-1)
- Aggregation: per-hour, per-day

#### Executive Stability Variance
```
executive_stability_variance = variance(stability_scores)
```
- Unit: variance
- Aggregation: per-hour, per-day

### Attention Metrics

#### Attention Quality
```
attention_quality = average(attention_quality_scores)
```
- Unit: score (0-1)
- Aggregation: per-hour, per-day

#### Attention Focus
```
attention_focus = focused_time / total_time
```
- Unit: ratio (0-1)
- Aggregation: per-hour, per-day

#### Attention Switching Rate
```
attention_switching_rate = attention_switches / time_period
```
- Unit: switches per minute
- Aggregation: per-minute, per-hour

### Decision Metrics

#### Decision Quality
```
decision_quality = average(decision_quality_scores)
```
- Unit: score (0-1)
- Aggregation: per-hour, per-day

#### Decision Success Rate
```
decision_success_rate = successful_decisions / total_decisions
```
- Unit: ratio (0-1)
- Aggregation: per-day, per-week

#### Decision Speed
```
decision_speed = decisions_made / time_period
```
- Unit: decisions per second
- Aggregation: per-second, per-minute

#### Decision Confidence
```
decision_confidence = average(decision_confidence_scores)
```
- Unit: score (0-1)
- Aggregation: per-hour, per-day

## Metric Queries

### Cognitive Metric Queries
```
query_reasoning_quality(since, until) -> quality
query_planning_quality(since, until) -> quality
query_memory_health(since, until) -> health
query_reflection_quality(since, until) -> quality
query_meta_cognition_quality(since, until) -> quality
query_executive_stability(since, until) -> stability
query_attention_quality(since, until) -> quality
query_decision_quality(since, until) -> quality
```

## Integration

The Cognitive Metric Engine integrates with:
- Metric Engine (metric computation)
- Telemetry Pipeline (event reception)
- Time Series Engine (metric storage)
- Observatory Platform (metric queries)

## Acceptance Criteria

✓ All cognitive metrics defined
✓ Metric computation
✓ Metric storage
✓ Metric querying
✓ Integration with metric engine
