# Phase 20.7 — Experiment Report

## Overview

Experiment Report provides a consolidated summary and metrics framework for all experimental activity within the Autonomous Experimentation Framework. It defines how experimental health, throughput, reproducibility, and impact are measured.

## Experiment Metrics

### Throughput Metrics

| Metric | Description |
|--------|-------------|
| Experiment Throughput | Number of experiments completed per unit time |
| Active Experiments | Number of experiments in progress |
| Experiment Velocity | Average time from proposal to freeze |
| Stage Completion Rate | Rate at which experiments advance through pipeline stages |

### Quality Metrics

| Metric | Description |
|--------|-------------|
| Reproducibility Rate | Fraction of experiments achieving full reproducibility |
| Statistical Validity Rate | Fraction with valid statistical assumptions |
| Certification Rate | Fraction of experiments certified |
| First-Attempt Success Rate | Fraction certified on first attempt |
| Failure Rate | Fraction of experiments that fail at any stage |

### Impact Metrics

| Metric | Description |
|--------|-------------|
| Hypothesis Confirmation Rate | Fraction of experiments that confirm hypothesis |
| Knowledge Update Rate | Fraction that result in knowledge updates |
| Theory Change Rate | Fraction that change theory confidence |
| Engineering Impact Rate | Fraction that inform engineering projects |
| Discovery Rate | Fraction that lead to new discoveries |

### Resource Metrics

| Metric | Description |
|--------|-------------|
| Resource Utilization | Fraction of allocated resources consumed |
| Average Resource Cost | Average resource consumption per experiment |
| Resource Efficiency | Knowledge gained per unit resource consumed |
| Budget Compliance Rate | Fraction of experiments within budget |

### Reproducibility Metrics

| Metric | Description |
|--------|-------------|
| Full Reproducibility Rate | Fraction achieving full pipeline reproducibility |
| Computational Reproducibility Rate | Fraction achieving computational reproducibility |
| Statistical Reproducibility Rate | Fraction achieving statistical reproducibility |
| Replay Success Rate | Fraction of replay verifications that pass |

### Safety Metrics

| Metric | Description |
|--------|-------------|
| Safety Limit Violations | Number of experiments reaching safety limits |
| Fail-Closed Rate | Fraction of failures that correctly fail closed |
| Recovery Success Rate | Fraction of recoveries that restore clean state |

## Experiment Registry Summary

| Sub-registry | Contents |
|--------------|----------|
| Proposal Registry | All experiment proposals |
| Design Registry | All experiment designs |
| Schedule Registry | All experiment schedules |
| Execution Registry | All experiment runs |
| Analysis Registry | All statistical reports |
| Classification Registry | All result classifications |
| Reproducibility Registry | All reproducibility reports |
| Certification Registry | All experiment certificates |
| Replay Registry | All experiment replay roots |
| Archaeology Registry | All experiment archaeology records |

## Report Format

The ExperimentReport is generated on demand and contains:

- Metrics dashboard (all metrics with current values and trends)
- Active experiment summary (experiments in progress with stage and status)
- Recent completions (recently frozen experiments with results summary)
- Quality summary (reproducibility, statistical validity, certification rates)
- Safety summary (failures, safety violations, fail-closed events)
- Impact summary (knowledge updates, theory changes, engineering impact)
- Resource summary (utilization, efficiency, budget compliance)
- Trend analysis (metric trends over time with projections)
