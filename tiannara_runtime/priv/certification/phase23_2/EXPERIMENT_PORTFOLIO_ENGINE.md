# Experiment Portfolio Engine

## Purpose

The Experiment Portfolio Engine manages the complete portfolio of experiments across all research programs. The portfolio continuously re-evaluates its composition to maximize scientific value while respecting resource constraints and constitutional priorities.

## Portfolio Structure

```
┌─────────────────────────────────────────────────────────┐
│                 Experiment Portfolio                     │
├─────────────────────────────────────────────────────────┤
│  Candidate Experiments   │  Active Experiments          │
│  ├─ Proposed             │  ├─ Running                  │
│  ├─ Peer-reviewed        │  ├─ Paused                   │
│  └─ Ready                │  └─ Monitoring               │
├──────────────────────────┼──────────────────────────────┤
│  Scheduled Experiments   │  Completed Experiments       │
│  ├─ Queued               │  ├─ Successful               │
│  ├─ Timetabled           │  ├─ Failed                   │
│  └─ Resource-assigned    │  └─ Inconclusive             │
├──────────────────────────┼──────────────────────────────┤
│  Failed Experiments      │  Archived Experiments        │
│  ├─ Execution failure    │  ├─ Historical               │
│  ├─ Validation failure   │  ├─ Replayable               │
│  └─ Cancelled            │  └─ Archaeologically intact  │
└─────────────────────────────────────────────────────────┘
```

## Portfolio Operations

### Addition
Experiments enter the portfolio through:
- Hypothesis-driven proposal
- Discovery feedback spawning
- Constitutional mandate
- Cross-domain suggestion
- Replication requirement

### Evaluation
Each portfolio entry is evaluated on:
- Scientific value
- Resource cost
- Risk
- Urgency
- Dependency satisfaction
- Constitutional alignment
- Portfolio diversity contribution

### Rebalancing
The portfolio is rebalanced when:
- New experiments are proposed
- Experiments complete or fail
- Resource availability changes
- Discovery alters priorities
- Constitutional directives change

### Retirement
Experiments leave the portfolio through:
- Successful completion
- Irrecoverable failure
- Supersession by better experiment
- Constitutional cancellation
- Archival after completion

## Portfolio Metrics

| Metric | Description |
|--------|-------------|
| Portfolio Size | Total experiments across all states |
| Active Ratio | Active / Total experiments |
| Candidate Ratio | Candidate / Total experiments |
| Completion Rate | Completed / Total over window |
| Success Rate | Successful / Completed over window |
| Failure Rate | Failed / Completed over window |
| Portfolio Diversity | Distribution across domains |
| Portfolio Churn | Rate of entry/exit |

## Constitutional Guarantees

- No experiment is ever permanently deleted
- Failed experiments are preserved
- All portfolio decisions are replayable
- Portfolio state is content-addressed
- Portfolio evolution is archaeologically traceable
