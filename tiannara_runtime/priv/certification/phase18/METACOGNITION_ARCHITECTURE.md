# Phase 18.8 — Constitutional Metacognition: Architecture

The metacognition subsystem monitors cognition without performing reasoning. It is a pure observation layer that sits above all cognitive pipelines, recording their execution without interference.

## Pipeline

```
MetaController → SelfMonitor → ConfidenceEstimator → UncertaintyAnalyzer → HealthEvaluator → EscalationEngine → IntrospectionEngine → MetaEvidence → MetaReplay → MetaArchaeology
```

## Stages

| Stage | Role |
|---|---|
| MetaController | Session lifecycle management |
| SelfMonitor | Captures runtime metrics per cognitive cycle |
| ConfidenceEstimator | Compares predicted vs actual outcomes |
| UncertaintyAnalyzer | Decomposes uncertainty into aleatoric and epistemic components |
| HealthEvaluator | Assesses system health across 6 dimensions |
| EscalationEngine | Classifies and routes anomalies by severity |
| IntrospectionEngine | Verifies constitutional compliance of every execution |
| MetaEvidence | Persists evidence artifacts for audit |
| MetaReplay | Enables deterministic replay of any session |
| MetaArchaeology | Recovers historical execution traces from archived sessions |

## Constitutional Principle

Every cognitive execution must itself become observable. No observation shall alter the observed execution. No metadata shall influence future cognition. No learning, no optimization, no self-modification — the metacognition layer is a pure observer, constitutionally barred from feedback into the cognitive substrate.
