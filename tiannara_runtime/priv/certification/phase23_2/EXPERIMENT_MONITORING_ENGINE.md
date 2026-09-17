# Experiment Monitoring Engine

## Purpose

The Experiment Monitoring Engine continuously observes active experiments, tracking progress, resource usage, prediction divergence, unexpected outcomes, safety status, reproducibility, and scientific yield. Every experiment is monitored throughout its execution lifecycle.

## Monitored Dimensions

| Dimension | Metrics | Alert Threshold |
|-----------|---------|-----------------|
| Progress | % complete, time remaining, milestone status | < 50% progress at 75% elapsed time |
| Resource Usage | CPU, GPU, memory, storage vs. allocation | > 90% of any allocated resource |
| Prediction Divergence | Actual vs. predicted outcomes | Deviation > 3 sigma |
| Unexpected Outcomes | Anomalous results, outliers | Statistical outlier detection |
| Safety Status | Constraint violations, resource exhaustion | Any constitutional violation |
| Reproducibility | Variance across runs | Coefficient of variation > 0.1 |
| Scientific Yield | Information gain rate | Below expected threshold |

## Monitoring Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Experiment Monitoring Engine                │
├─────────────────────────────────────────────────────────┤
│  Probe Manager │  MetricCollector │  AnomalyDetector    │
│  ├─ Progress   │  ├─ Real-time    │  ├─ Statistical     │
│  ├─ Resource   │  ├─ Aggregated   │  ├─ ML-based        │
│  ├─ Prediction │  └─ Historical   │  └─ Constitutional  │
│  └─ Safety     │                  │                     │
├────────────────┼──────────────────┼─────────────────────┤
│  Alert Manager │  Dashboard       │  Logger             │
│  ├─ Threshold  │  ├─ Per-exp      │  ├─ Structured      │
│  ├─ Escalation │  ├─ Portfolio    │  ├─ Immutable       │
│  └─ Notification│  └─ Summary     │  └─ Replayable      │
└────────────────┴──────────────────┴─────────────────────┘
```

## Alert Levels

| Level | Meaning | Action |
|-------|---------|--------|
| Info | Noticeable deviation | Logged for analysis |
| Warning | Potential issue | Flag in dashboard |
| Error | Confirmed problem | Notify adaptation engine |
| Critical | Constitutional violation | Halt experiment, notify governance |
| Emergency | System integrity threat | Immediate termination |

## Monitoring Record

```
MonitoringSnapshot {
  snapshot_id: content-addressed,
  experiment_id: reference,
  timestamp: integer,
  progress: {percent_complete, time_remaining, milestones},
  resource_usage: {cpu, gpu, memory, storage},
  prediction_divergence: float,
  unexpected_outcomes: [outcome],
  safety_status: :safe | :warning | :violated,
  reproducibility_score: float,
  scientific_yield: float,
  snapshot_hash: string
}
```

## Observatory Integration

The monitoring engine exposes all data to the Observatory for:
- Real-time experiment dashboards
- Historical trend analysis
- Cross-experiment comparisons
- Alert correlation across experiments
- Scientific yield tracking
