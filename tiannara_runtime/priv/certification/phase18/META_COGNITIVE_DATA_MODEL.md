# Phase 18.8 — Meta-Cognitive Data Model

## Abstract Data Types

### MetaCognitiveSession
- `session_id`: UUID
- `started_at`: timestamp
- `completed_at`: timestamp
- `pipeline_version`: string
- `status`: enum (running, completed, failed)
- `artifacts`: list of artifact references

### SelfMonitorState
- `cognitive_load`: float (0.0–1.0)
- `throughput`: float (ops/sec)
- `error_rate`: float (errors/op)
- `latency_p50`: duration
- `latency_p95`: duration
- `latency_p99`: duration
- `memory_pressure`: float (0.0–1.0)
- `timestamp`: timestamp

### ConfidenceCalibration
- `calibration_curve`: list of (confidence_bin, accuracy) tuples
- `expected_calibration_error`: float
- `maximum_calibration_error`: float
- `miscalibration_regions`: list of (bin_lower, bin_upper, delta)
- `calibration_score`: float (0.0–1.0)

### UncertaintyDimension
- `aleatoric`: float (0.0–1.0)
- `epistemic`: float (0.0–1.0)
- `total_uncertainty`: float (0.0–1.0)
- `uncertainty_decomposition`: map of source → contribution
- `timestamp`: timestamp

### CognitiveHealth
- `cognitive_load_score`: float (0.0–1.0)
- `error_density_score`: float (0.0–1.0)
- `response_time_variance`: float
- `resource_pressure_score`: float (0.0–1.0)
- `stability_index`: float (0.0–1.0)
- `composite_health_score`: float (0.0–1.0)
- `timestamp`: timestamp

### HealthDimension
- `dimension_name`: string
- `current_value`: float
- `baseline_value`: float
- `deviation`: float
- `threshold`: float
- `is_healthy`: boolean

### EscalationDecision
- `level`: enum (info, warning, critical, emergency)
- `reasons`: list of EscalationReason
- `recommendation`: string
- `triggered_at`: timestamp
- `resolved_at`: timestamp

### EscalationReason
- `dimension`: string
- `current_value`: float
- `threshold`: float
- `severity`: float

### ConstitutionalIntrospection
- `session_id`: UUID
- `findings`: list of IntrospectionFinding
- `overall_alignment_score`: float (0.0–1.0)
- `completed_at`: timestamp

### IntrospectionFinding
- `principle_id`: string
- `principle_name`: string
- `decision_id`: UUID
- `alignment_score`: float (0.0–1.0)
- `deviation_description`: string
- `evidence_ref`: string

### MetaCognitiveEvidence
- `evidence_id`: UUID
- `session_id`: UUID
- `source_stage`: string
- `payload`: blob
- `content_hash`: string
- `timestamp`: timestamp

### MetaCognitiveReplay
- `session_id`: UUID
- `replay_chain`: list of (stage, artifact_hash, timestamp)
- `integrity_proof`: string
- `replay_status`: enum (valid, invalid, incomplete)

### MetaCognitiveArchaeology
- `archive_id`: UUID
- `session_ids`: list of UUID
- `compressed_artifacts`: blob
- `archive_hash`: string
- `compression_method`: string
- `created_at`: timestamp
