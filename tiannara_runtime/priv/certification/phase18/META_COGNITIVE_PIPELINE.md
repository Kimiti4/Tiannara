# Phase 18.8 — Meta-Cognitive Pipeline

## Pipeline Flow

```
CognitiveState
    → SelfMonitor
    → ConfidenceCalibrator
    → UncertaintyPropagator
    → CognitiveHealth
    → EscalationDecider
    → ConstitutionalIntrospector
    → MetaCognitiveState
    → Replay
    → Archaeology
```

---

## Transition: CognitiveState → SelfMonitor

| Field | Value |
|---|---|
| **Inputs** | Raw cognitive state (task queues, resource usage, inference buffers, decision stacks) |
| **Outputs** | SelfMonitorState (load, throughput, error rate, latency, memory pressure) |
| **Owner** | MetaCognition Supervisor |
| **Replay artifact** | `cognitive_state_snapshot` — serialized state at tick N |
| **Evidence artifact** | `self_monitor_readings` — raw monitoring readings with timestamps |
| **Archaeology artifact** | `cognitive_state_archive` — compressed historical snapshots |

---

## Transition: SelfMonitor → ConfidenceCalibrator

| Field | Value |
|---|---|
| **Inputs** | SelfMonitorState readings |
| **Outputs** | ConfidenceCalibration (calibration curve, miscalibration flags) |
| **Owner** | Confidence Calibration Agent |
| **Replay artifact** | `self_monitor_replay` — sequential monitor readings |
| **Evidence artifact** | `calibration_evidence` — predicted vs. observed confidence pairs |
| **Archaeology artifact** | `calibration_history` — calibration curves over time |

---

## Transition: ConfidenceCalibrator → UncertaintyPropagator

| Field | Value |
|---|---|
| **Inputs** | ConfidenceCalibration data |
| **Outputs** | UncertaintyDimensions (aleatoric, epistemic) |
| **Owner** | Uncertainty Propagation Agent |
| **Replay artifact** | `confidence_calibration_replay` — calibration states |
| **Evidence artifact** | `uncertainty_evidence` — decomposed uncertainty components |
| **Archaeology artifact** | `uncertainty_archive` — uncertainty trends |

---

## Transition: UncertaintyPropagator → CognitiveHealth

| Field | Value |
|---|---|
| **Inputs** | UncertaintyDimensions |
| **Outputs** | CognitiveHealth (load, error density, latency variance, resource pressure, stability index) |
| **Owner** | Cognitive Health Agent |
| **Replay artifact** | `uncertainty_propagation_replay` — propagation chain |
| **Evidence artifact** | `health_evidence` — health dimension measurements |
| **Archaeology artifact** | `health_history` — health scores over time |

---

## Transition: CognitiveHealth → EscalationDecider

| Field | Value |
|---|---|
| **Inputs** | CognitiveHealth dimensions |
| **Outputs** | EscalationDecision (level, reason, recommendation) |
| **Owner** | Escalation Decision Agent |
| **Replay artifact** | `health_assessment_replay` — health assessment records |
| **Evidence artifact** | `escalation_evidence` — escalation triggers and context |
| **Archaeology artifact** | `escalation_archive` — escalation event history |

---

## Transition: EscalationDecider → ConstitutionalIntrospector

| Field | Value |
|---|---|
| **Inputs** | EscalationDecision |
| **Outputs** | ConstitutionalIntrospection (findings, alignment scores) |
| **Owner** | Constitutional Introspection Agent |
| **Replay artifact** | `escalation_replay` — escalation decision records |
| **Evidence artifact** | `introspection_evidence` — principle-by-principle analysis |
| **Archaeology artifact** | `introspection_archive` — introspection findings history |

---

## Transition: ConstitutionalIntrospector → MetaCognitiveState

| Field | Value |
|---|---|
| **Inputs** | ConstitutionalIntrospection |
| **Outputs** | MetaCognitiveState (aggregated meta-cognitive summary) |
| **Owner** | MetaCognition Supervisor |
| **Replay artifact** | `introspection_replay` — introspection process replay |
| **Evidence artifact** | `meta_cognitive_summary` — compiled meta-cognitive state |
| **Archaeology artifact** | `meta_state_archive` — historical state snapshots |

---

## Transition: MetaCognitiveState → Replay

| Field | Value |
|---|---|
| **Inputs** | MetaCognitiveState |
| **Outputs** | MetaCognitiveReplay (deterministic reconstruction) |
| **Owner** | Replay Controller |
| **Replay artifact** | `replay_manifest` — ordered list of all replay artifacts |
| **Evidence artifact** | `replay_verification` — hash-chain integrity proof |
| **Archaeology artifact** | `replay_archive` — full replay log |

---

## Transition: Replay → Archaeology

| Field | Value |
|---|---|
| **Inputs** | MetaCognitiveReplay |
| **Outputs** | MetaCognitiveArchaeology (compressed temporal archive) |
| **Owner** | Archaeology Controller |
| **Replay artifact** | `archaeology_manifest` — index of all archived sessions |
| **Evidence artifact** | `archaeology_verification` — data integrity verification |
| **Archaeology artifact** | `archaeology_store` — long-term compressed archive |
