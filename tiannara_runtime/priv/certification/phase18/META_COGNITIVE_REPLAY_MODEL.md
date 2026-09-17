# Phase 18.8 — Meta-Cognitive Replay Model

## Root Identifier

All replay is rooted in `meta_cognitive_session_id`. The session ID links every artifact across the pipeline into a single reconstructable timeline.

## Reconstructable Artifacts

### Self-Monitoring Readings
- Source: `self_monitor_readings` evidence artifacts
- Replay format: chronological sequence of SelfMonitorState snapshots
- Reconstruction: `replay_self_monitor(session_id) → List[SelfMonitorState]`
- Integrity: each snapshot includes a hash of the previous snapshot

### Confidence Calibrations
- Source: `calibration_evidence` evidence artifacts
- Replay format: ordered list of ConfidenceCalibration records
- Reconstruction: `replay_calibrations(session_id) → List[ConfidenceCalibration]`
- Integrity: calibration curves are hash-chained

### Uncertainty Propagation
- Source: `uncertainty_evidence` evidence artifacts
- Replay format: sequence of UncertaintyDimension records
- Reconstruction: `replay_uncertainty(session_id) → List[UncertaintyDimension]`
- Integrity: each propagation step references prior uncertainty state

### Health Assessments
- Source: `health_evidence` evidence artifacts
- Replay format: ordered list of CognitiveHealth snapshots
- Reconstruction: `replay_health(session_id) → List[CognitiveHealth]`
- Integrity: health dimensions are bound by rolling checksum

### Escalation Decisions
- Source: `escalation_evidence` evidence artifacts
- Replay format: sequential list of EscalationDecision records
- Reconstruction: `replay_escalations(session_id) → List[EscalationDecision]`
- Integrity: each decision references the health assessment that triggered it

### Introspection Findings
- Source: `introspection_evidence` evidence artifacts
- Replay format: ordered list of ConstitutionalIntrospection records
- Reconstruction: `replay_introspections(session_id) → List[ConstitutionalIntrospection]`
- Integrity: each finding references prior findings and the session root

## Replay Verification

```
verify_replay(session_id) → ReplayStatus
  - valid: all artifacts present, hashes match, chain intact
  - invalid: hash mismatch or broken chain detected
  - incomplete: artifacts missing
```
