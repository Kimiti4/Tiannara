# Phase 20.4 — Integration Schema Report

## Overview

Complete schema specification for all immutable integration structures in the Constitutional Integration Engine.

## IntegrationCandidate

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| candidate_id | string | yes | Content-addressed identifier from Phase 20.3 |
| origin | string | yes | Evolution Sandbox generation reference |
| innovation_hash | string | yes | SHA-256 of innovation specification |
| evidence_hash | string | yes | SHA-256 of full evidence chain |
| validation_hash | string | yes | SHA-256 of validation artifacts |
| performance_metrics | object | yes | Predicted performance improvements |
| compatibility_report | string | no | Reference to CompatibilityReport (populated after Stage 2) |
| risk_profile | object | yes | Risk assessment with mitigations |
| migration_plan | string | no | Reference to MigrationPlan (populated after Stage 4) |
| dependencies | array | yes | List of dependency identifiers |
| owner | string | yes | Entity responsible for this candidate |
| fingerprint | string | yes | SHA-256 of canonical form |

## CompatibilityReport

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| report_id | string | yes | Content-addressed identifier |
| candidate | string | yes | Reference to IntegrationCandidate |
| api_compatibility | object | yes | Pass/fail per API interface with diagnostics |
| data_compatibility | object | yes | Data format and schema compatibility |
| replay_compatibility | object | yes | Replay chain compatibility assessment |
| dependency_compatibility | object | yes | Dependency graph compatibility |
| constitution_compatibility | object | yes | Constitutional compliance verification |
| performance_compatibility | object | yes | Performance impact projection |
| overall | string | yes | Pass/Fail (fail closed on any incompatibility) |
| diagnostics | array | yes | Detailed diagnostic messages per incompatibility |
| fingerprint | string | yes | SHA-256 of canonical form |

## MigrationPlan

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| plan_id | string | yes | Content-addressed identifier |
| candidate | string | yes | Reference to IntegrationCandidate |
| source_version | string | yes | Current runtime version identifier |
| target_version | string | yes | Target runtime version identifier |
| migration_steps | array | yes | Ordered list of deterministic state transforms |
| rollback_steps | array | yes | Ordered list of inverse transforms for rollback |
| verification_steps | array | yes | Verification criteria per step |
| estimated_cost | object | yes | Resource cost estimate per step |
| expected_state_hash | string | yes | SHA-256 of runtime state after migration |
| fingerprint | string | yes | SHA-256 of canonical form |

## SimulationReport

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| report_id | string | yes | Content-addressed identifier |
| candidate | string | yes | Reference to IntegrationCandidate |
| plan | string | yes | Reference to MigrationPlan |
| metrics | object | yes | Performance metrics from simulation |
| determinism_verified | boolean | yes | Whether replay produced identical hashes |
| resource_usage | object | yes | CPU, memory, storage consumption |
| stability_assessment | object | yes | Stability metrics and observations |
| failure_propagation | object | yes | Failure mode propagation analysis |
| comparison_to_predictions | object | yes | Simulation vs candidate predictions |
| overall | string | yes | Pass/Fail |
| fingerprint | string | yes | SHA-256 of canonical form |

## MigrationResult

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| result_id | string | yes | Content-addressed identifier |
| candidate | string | yes | Reference to IntegrationCandidate |
| plan | string | yes | Reference to MigrationPlan |
| intermediate_state_hashes | array | yes | SHA-256 hash after each migration step |
| final_state_hash | string | yes | SHA-256 of runtime state after migration |
| migration_replay_root | string | yes | Root hash of migration replay chain |
| status | string | yes | Success/Failure |
| fingerprint | string | yes | SHA-256 of canonical form |

## VerificationReport

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| report_id | string | yes | Content-addressed identifier |
| candidate | string | yes | Reference to IntegrationCandidate |
| migration | string | yes | Reference to MigrationResult |
| state_match | boolean | yes | final_state_hash == expected_state_hash |
| replay_intact | boolean | yes | Replay chains verified intact |
| archaeology_intact | boolean | yes | Archaeology chains verified intact |
| compatibility_preserved | boolean | yes | Post-migration compatibility confirmed |
| per_criterion | object | yes | Pass/fail per verification criterion |
| overall | string | yes | Pass/Fail |
| fingerprint | string | yes | SHA-256 of canonical form |

## AuditReport

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| report_id | string | yes | Content-addressed identifier |
| candidate | string | yes | Reference to IntegrationCandidate |
| auditor | string | yes | Auditor entity identifier |
| reproduction_results | object | yes | Results of independent reproduction |
| findings | array | yes | List of findings with severity |
| risk_assessment | object | yes | Risk assessment with mitigations |
| recommendation | string | yes | Approve/Reject/Conditional |
| fingerprint | string | yes | SHA-256 of canonical form |

## IntegrationCertificate

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| certificate_id | string | yes | Content-addressed identifier |
| candidate | string | yes | Reference to IntegrationCandidate |
| integration_root | string | yes | Root hash of entire integration chain |
| migration_root | string | yes | Root hash of migration chain |
| verification_root | string | yes | Root hash of verification chain |
| audit_root | string | yes | Root hash of audit chain |
| certificate_hash | string | yes | SHA-256 of certificate canonical form |
| issued_by | string | yes | Constitutional authority entity |
| issued_at | integer | yes | Deterministic timestamp |
| expires_at | integer | yes | Deterministic expiration timestamp |
| scope | string | yes | Authorized integration scope |
| conditions | array | no | Integration conditions and restrictions |
| fingerprint | string | yes | SHA-256 of canonical form |

## ActivationRecord

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| activation_id | string | yes | Content-addressed identifier |
| candidate | string | yes | Reference to IntegrationCandidate |
| certificate | string | yes | Reference to IntegrationCertificate |
| stages | array | yes | Per-stage results (Shadow, Limited, Progressive, Full, Freeze) |
| promotion_evidence | array | yes | Evidence supporting each stage promotion |
| status | string | yes | Active/Frozen/RolledBack |
| fingerprint | string | yes | SHA-256 of canonical form |

## RollbackRecord

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| rollback_id | string | yes | Content-addressed identifier |
| trigger | string | yes | Condition that triggered rollback |
| previous_version | string | yes | Version before rollback |
| restored_version | string | yes | Version restored to |
| replay_root | string | yes | Root hash of rollback replay chain |
| verification_root | string | yes | Root hash of rollback verification |
| evidence | object | yes | Evidence of trigger condition |
| fingerprint | string | yes | SHA-256 of canonical form |

## MonitoringReport

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| report_id | string | yes | Content-addressed identifier |
| candidate | string | yes | Reference to IntegrationCandidate |
| interval | object | yes | Monitoring period start and end |
| performance_drift | object | yes | Performance metric trends |
| resource_drift | object | yes | Resource usage trends |
| knowledge_drift | object | yes | Knowledge graph consistency trends |
| replay_divergence | object | yes | Replay hash stability |
| behavior_drift | object | yes | Behavioral metric trends |
| constitutional_violations | array | yes | Any observed violations |
| threshold_alerts | array | yes | Threshold violation alerts |
| overall | string | yes | Healthy/Degraded/Critical |
| fingerprint | string | yes | SHA-256 of canonical form |

## FreezeRecord

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| freeze_id | string | yes | Content-addressed identifier |
| candidate | string | yes | Reference to IntegrationCandidate |
| generation_update | object | yes | Updated RuntimeGeneration reference |
| archaeology_root | string | yes | Root hash of complete integration archaeology |
| final_fingerprint | string | yes | SHA-256 of frozen integration state |
| all_artifact_hashes | array | yes | Hashes of all pipeline artifacts |
| fingerprint | string | yes | SHA-256 of canonical form |
