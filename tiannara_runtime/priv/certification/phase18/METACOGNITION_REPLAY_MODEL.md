# Phase 18.8 — Metacognition Replay Model

## Root

```
metacognition_session_id
```

Every replay is rooted in a single `MetaCognitionState.session_id`. The replay model reconstructs all observations produced during that session in deterministic order.

## Reconstructed Artifacts

### Self-Monitor Readings

Replay reconstructs every `SelfMonitorReading` captured during the session, ordered by tick. Each reading includes the full metric vector (cognitive load, throughput, error rate, latency p50/p95/p99, memory pressure). Readings are deterministic given the same cognitive session inputs.

### Confidence Estimates

Replay reconstructs every `ConfidenceEstimate` produced by the ConfidenceEstimator. The confidence score, calibrated score, and prediction interval are all deterministic. The replay verifies that the predicted vs actual comparison yields the same score at each tick.

### Uncertainty Propagation

Replay reconstructs the `UncertaintyEstimate` at each tick, including the decomposition into aleatoric and epistemic components. The propagation of uncertainty across the pipeline is recomputed identically given the same confidence estimates.

### Health Assessments

Replay reconstructs every `HealthAssessment` — the full 6-dimension vector and the aggregate score. Each dimension's computation is deterministic and reproducible from the self-monitor readings and uncertainty estimates at the corresponding tick.

### Escalation Decisions

Replay reconstructs every `EscalationDecision` including the severity level, reason, and triggering dimension. The escalation logic is a pure function of the health assessment — no external state influences the decision.

### Introspection Findings

Replay reconstructs every `Introspection` result including checks passed, checks failed, compliance ratio, and the full list of violations. Constitutional checks are deterministic — the same execution always produces the same compliance verdict.
