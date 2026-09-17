# Phase 18.8 — Metacognition Runtime Freeze

## Frozen Schemas

All 11 structs are frozen and must NOT be modified after Phase 18.8 certification:

| # | Schema | Module |
|---|---|---|
| 1 | MetaCognitionState | metacognition.state |
| 2 | ConfidenceEstimate | metacognition.confidence |
| 3 | UncertaintyEstimate | metacognition.uncertainty |
| 4 | SelfMonitorReading | metacognition.monitor |
| 5 | HealthAssessment | metacognition.health |
| 6 | EscalationDecision | metacognition.escalation |
| 7 | Reflection | metacognition.reflection |
| 8 | Introspection | metacognition.introspection |
| 9 | MetaEvidence | metacognition.evidence |
| 10 | MetaReplay | metacognition.replay |
| 11 | MetaArchaeology | metacognition.archaeology |

## Frozen APIs

All 7 engines have frozen public interfaces:

| Engine | Key API |
|---|---|
| MetaControllerEngine | `start_session/1`, `tick/1`, `finalize/1` |
| SelfMonitorEngine | `capture/1`, `readings/1` |
| ConfidenceEstimatorEngine | `estimate/2`, `calibrate/1` |
| UncertaintyAnalyzerEngine | `decompose/1`, `propagate/2` |
| HealthEvaluatorEngine | `assess/2`, `dimension/2` |
| EscalationEngine | `evaluate/1`, `severity/1` |
| IntrospectionEngine | `inspect/2`, `compliance/1` |

## Frozen Behaviours

| Behaviour | Callbacks |
|---|---|
| MetaBehaviour | `session_started/1`, `session_ticked/2`, `session_finalized/1` |
| ConfidenceBehaviour | `confidence_estimated/1`, `calibration_updated/1` |
| HealthBehaviour | `health_assessed/1`, `health_degraded/1` |
| EscalationBehaviour | `escalation_triggered/1`, `escalation_resolved/1` |

## Migration Note

Legacy systems at `meta_cognition/` and `metacognitive/` are preserved as archaeological predecessors. These directories contain the prototype implementations that informed the Phase 18.8 design. They are archived and will be removed after Phase 18.999.

Do not reference legacy modules in new code. All new metacognition consumers must import from the `metacognition.` namespace.
