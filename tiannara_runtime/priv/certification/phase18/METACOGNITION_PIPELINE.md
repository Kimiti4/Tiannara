# Phase 18.8 — Metacognition Pipeline

## 1. MetaController

Manages the metacognition session lifecycle: start, tick, end.

| Field | Description |
|---|---|
| **Inputs** | Cognitive session ID, trigger event |
| **Outputs** | MetaCognitionState (initialized/ticking/finalized) |
| **Owner** | MetaControllerEngine |
| **Replay artifact** | session_events.log |
| **Evidence artifact** | session_boundary.evidence |
| **Archaeology artifact** | session_index.arch |

## 2. SelfMonitor

Captures real-time runtime metrics from the cognitive engine.

| Field | Description |
|---|---|
| **Inputs** | Runtime probe points |
| **Outputs** | SelfMonitorReading (cognitive load, throughput, error rate, latency, memory pressure) |
| **Owner** | SelfMonitorEngine |
| **Replay artifact** | monitor_readings.replay |
| **Evidence artifact** | monitor_snapshot.evidence |
| **Archaeology artifact** | monitor_timeseries.arch |

### Metrics captured

- **Cognitive load** — CPU and task saturation ratio
- **Throughput** — operations per second
- **Error rate** — failed operations / total operations
- **Latency** — p50/p95/p99 response times
- **Memory pressure** — heap usage, GC cycles, allocation rate

## 3. ConfidenceEstimator

Compares predicted outcomes against actual outcomes to produce a confidence score.

| Field | Description |
|---|---|
| **Inputs** | Predicted output, actual output, prediction metadata |
| **Outputs** | ConfidenceEstimate (score, calibrated, prediction interval) |
| **Owner** | ConfidenceEstimatorEngine |
| **Replay artifact** | confidence_series.replay |
| **Evidence artifact** | confidence_calibration.evidence |
| **Archaeology artifact** | confidence_distribution.arch |

## 4. UncertaintyAnalyzer

Decomposes uncertainty into aleatoric and epistemic components.

| Field | Description |
|---|---|
| **Inputs** | ConfidenceEstimate, model state, historical variance |
| **Outputs** | UncertaintyEstimate (aleatoric, epistemic, total) |
| **Owner** | UncertaintyAnalyzerEngine |
| **Replay artifact** | uncertainty_propagation.replay |
| **Evidence artifact** | uncertainty_decomposition.evidence |
| **Archaeology artifact** | uncertainty_regime.arch |

## 5. HealthEvaluator

Assesses system health across 6 dimensions.

| Field | Description |
|---|---|
| **Inputs** | SelfMonitorReading, UncertaintyEstimate |
| **Outputs** | HealthAssessment (6-dimension vector, aggregate score) |
| **Owner** | HealthEvaluatorEngine |
| **Replay artifact** | health_assessments.replay |
| **Evidence artifact** | health_report.evidence |
| **Archaeology artifact** | health_trend.arch |

### Six dimensions

1. **Responsiveness** — latency vs threshold
2. **Stability** — variance of throughput and error rate
3. **Accuracy** — confidence calibration error
4. **Resource efficiency** — memory and CPU within quota
5. **Uncertainty tolerance** — epistemic fraction vs threshold
6. **Constitutional compliance** — introspection pass/fail ratio

## 6. EscalationEngine

Classifies anomalies by severity and routes them for handling.

| Field | Description |
|---|---|
| **Inputs** | HealthAssessment, anomaly signals |
| **Outputs** | EscalationDecision (normal/info/warning/critical) |
| **Owner** | EscalationEngine |
| **Replay artifact** | escalation_log.replay |
| **Evidence artifact** | escalation_record.evidence |
| **Archaeology artifact** | escalation_summary.arch |

### Severity levels

| Level | Action |
|---|---|
| **normal** | None |
| **info** | Logged |
| **warning** | Logged, sentinel alert |
| **critical** | Logged, sentinel alert, cognitive pause requested |

## 7. IntrospectionEngine

Verifies constitutional compliance of every cognitive execution.

| Field | Description |
|---|---|
| **Inputs** | EscalationDecision, full pipeline context |
| **Outputs** | Introspection (checks passed, violations, compliance ratio) |
| **Owner** | IntrospectionEngine |
| **Replay artifact** | introspection_audit.replay |
| **Evidence artifact** | introspection_findings.evidence |
| **Archaeology artifact** | introspection_history.arch |

## 8. MetaEvidence

Persists evidence artifacts to the evidence store.

| Field | Description |
|---|---|
| **Inputs** | All previous stage outputs |
| **Outputs** | MetaEvidence (cryptographically linked chain) |
| **Owner** | MetaEvidenceEngine |
| **Replay artifact** | evidence_chain.replay |
| **Evidence artifact** | evidence_bundle.evidence |
| **Archaeology artifact** | evidence_index.arch |

## 9. MetaReplay

Enables deterministic replay of any metacognition session.

| Field | Description |
|---|---|
| **Inputs** | MetaEvidence, session ID |
| **Outputs** | MetaReplay (deterministic execution trace) |
| **Owner** | MetaReplayEngine |
| **Replay artifact** | replay_log.replay |
| **Evidence artifact** | replay_verification.evidence |
| **Archaeology artifact** | replay_catalog.arch |

## 10. MetaArchaeology

Recovers historical execution traces from archived or partial sessions.

| Field | Description |
|---|---|
| **Inputs** | Archived evidence, partial replay artifacts |
| **Outputs** | MetaArchaeology (reconstructed trace, confidence, gaps) |
| **Owner** | MetaArchaeologyEngine |
| **Replay artifact** | archaeology_replay.replay |
| **Evidence artifact** | archaeology_findings.evidence |
| **Archaeology artifact** | archaeology_record.arch |
