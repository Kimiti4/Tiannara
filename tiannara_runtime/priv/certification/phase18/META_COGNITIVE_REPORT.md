# Phase 18.8 — Meta-Cognitive Control: Report

## Pipeline Summary

Phase 18.8 implements a deterministic, read-only meta-cognitive introspection pipeline. The system monitors its own cognitive processes, calibrates confidence, propagates uncertainty, assesses health, escalates issues, and performs constitutional introspection — all without self-modification.

## Self-Monitoring Dimensions

| Dimension | Description | Range |
|---|---|---|
| Cognitive Load | Utilization of active cognitive capacity | 0.0–1.0 |
| Throughput | Operations processed per second | 0–∞ |
| Error Rate | Errors per operation | 0.0–1.0 |
| Latency | Response time percentiles (p50, p95, p99) | duration |
| Memory Pressure | Memory utilization ratio | 0.0–1.0 |

## Confidence Calibration

- **Calibration Curve**: Binned confidence vs. accuracy plot produced per session.
- **Expected Calibration Error (ECE)**: Mean absolute difference between confidence and accuracy across bins.
- **Maximum Calibration Error (MCE)**: Worst-case bin deviation.
- **Miscalibration Detection**: Regions where |confidence - accuracy| exceeds threshold are flagged.

## Uncertainty Propagation

| Type | Description | Source |
|---|---|---|
| Aleatoric | Data-inherent irreducible uncertainty | Input noise, stochastic processes |
| Epistemic | Model-knowledge reducible uncertainty | Missing information, limited training |

## Health Assessment

| Dimension | Description | Threshold |
|---|---|---|
| Cognitive Load Score | Normalized load (inverse of raw load) | < 0.3 critical |
| Error Density Score | Running error rate over window | > 0.1 critical |
| Response Time Variance | Standard deviation of latency | > 2x baseline |
| Resource Pressure Score | Combined resource utilization | < 0.3 critical |
| Stability Index | Inverse of state oscillation | < 0.5 unstable |

## Escalation Levels

| Level | Trigger | Action |
|---|---|---|
| Info | Minor deviation from baseline | Log only |
| Warning | Threshold exceeded, no immediate risk | Notify supervisor |
| Critical | Threshold exceeded with active degradation | Alert human operator |
| Emergency | System health critically compromised | Halt non-essential processing |

## Constitutional Introspection

Each introspection session evaluates decisions against a defined constitutional principle set. Findings include per-principle alignment scores, deviation descriptions, and evidence references. The overall alignment score aggregates across all evaluated principles.

## Replay & Archaeology

- **Replay**: Deterministic reconstruction of any meta-cognitive session from its artifact chain. Verified via hash-chain integrity checks.
- **Archaeology**: Compressed long-term storage of completed sessions. Supports post-hoc analysis and audit.

## Metrics

- Session completion rate: target > 99.9%
- Replay verification success rate: target 100%
- Introspection principle coverage: target 100%
- Calibration ECE: target < 0.05

## Limitations

1. No self-modification: identified issues must be resolved by external agents.
2. Replay fidelity depends on artifact integrity; storage corruption cannot be detected post-hoc.
3. Constitutional introspection is limited to explicitly defined principles.
4. Uncertainty decomposition assumes independence between aleatoric and epistemic components.
5. Health thresholds are static; adaptive thresholding is a future enhancement.
