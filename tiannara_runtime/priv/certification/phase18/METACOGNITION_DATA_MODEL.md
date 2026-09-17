# Phase 18.8 — Metacognition Data Model

All 11 structs are abstract definitions. No implementation details are specified — these are the constitutional contracts.

---

### 1. MetaCognitionState

Tracks the lifecycle of a single metacognition session.

| Field | Type | Invariant |
|---|---|---|
| `session_id` | UUID | Immutable, unique |
| `cognitive_session_id` | UUID | Must reference an active cognitive session |
| `status` | enum(initialized, ticking, finalized) | Linear progression only |
| `started_at` | timestamp | Monotonic |
| `finalized_at` | timestamp\|nil | nil iff status != finalized |
| `tick_count` | uint64 | Monotonic, >= 0 |
| `last_tick_at` | timestamp\|nil | nil iff tick_count == 0 |

---

### 2. ConfidenceEstimate

Output of the ConfidenceEstimator.

| Field | Type | Invariant |
|---|---|---|
| `session_id` | UUID | Links to MetaCognitionState |
| `predicted` | map<string, float> | Keys match output schema |
| `actual` | map<string, float> | Keys match output schema |
| `score` | float [0.0, 1.0] | 1.0 = perfect confidence |
| `calibrated_score` | float [0.0, 1.0] | Must be <= score |
| `prediction_interval` | (float, float) | Lower <= Upper |
| `sample_count` | uint64 | Must match the sample count of the prediction |

---

### 3. UncertaintyEstimate

Output of the UncertaintyAnalyzer.

| Field | Type | Invariant |
|---|---|---|
| `session_id` | UUID | Links to MetaCognitionState |
| `aleatoric` | float [0.0, 1.0] | Uncertainty from inherent noise |
| `epistemic` | float [0.0, 1.0] | Uncertainty from knowledge gaps |
| `total` | float [0.0, 1.0] | total = aleatoric + epistemic |
| `epistemic_fraction` | float [0.0, 1.0] | epistemic / total, 0 if total == 0 |

---

### 4. SelfMonitorReading

Output of the SelfMonitor, captured at a tick boundary.

| Field | Type | Invariant |
|---|---|---|
| `session_id` | UUID | Links to MetaCognitionState |
| `tick` | uint64 | Monotonic |
| `cognitive_load` | float [0.0, 1.0] | 0 = idle, 1 = saturated |
| `throughput` | float >= 0 | Ops/sec |
| `error_rate` | float [0.0, 1.0] | Failed / total |
| `latency_p50` | duration >= 0 | Milliseconds |
| `latency_p95` | duration >= 0 | >= latency_p50 |
| `latency_p99` | duration >= 0 | >= latency_p95 |
| `memory_pressure` | float [0.0, 1.0] | 0 = empty, 1 = OOM risk |

---

### 5. HealthAssessment

Output of the HealthEvaluator.

| Field | Type | Invariant |
|---|---|---|
| `session_id` | UUID | Links to MetaCognitionState |
| `tick` | uint64 | Monotonic |
| `responsiveness` | float [0.0, 1.0] | 1.0 = healthy |
| `stability` | float [0.0, 1.0] | 1.0 = healthy |
| `accuracy` | float [0.0, 1.0] | 1.0 = healthy |
| `resource_efficiency` | float [0.0, 1.0] | 1.0 = healthy |
| `uncertainty_tolerance` | float [0.0, 1.0] | 1.0 = healthy |
| `constitutional_compliance` | float [0.0, 1.0] | 1.0 = healthy |
| `aggregate_score` | float [0.0, 1.0] | Weighted mean of the 6 dimensions |

---

### 6. EscalationDecision

Output of the EscalationEngine.

| Field | Type | Invariant |
|---|---|---|
| `session_id` | UUID | Links to MetaCognitionState |
| `tick` | uint64 | Monotonic |
| `severity` | enum(normal, info, warning, critical) | Must be non-decreasing per session (only warnings can escalate, not de-escalate within a session) |
| `reason` | string | Non-empty if severity > normal |
| `dimension` | string\|nil | Which health dimension triggered escalation |

---

### 7. Reflection

A recorded observation about a cognitive execution. Internal artifact.

| Field | Type | Invariant |
|---|---|---|
| `reflection_id` | UUID | Immutable |
| `session_id` | UUID | Links to MetaCognitionState |
| `tick` | uint64 | Monotonic |
| `observation` | string | Free-form constitutional observation |
| `confidence_at_reflection` | float [0.0, 1.0] | ConfidenceEstimate.score at time of reflection |
| `attached_evidence` | list<UUID> | References to MetaEvidence entries |

---

### 8. Introspection

Output of the IntrospectionEngine.

| Field | Type | Invariant |
|---|---|---|
| `session_id` | UUID | Links to MetaCognitionState |
| `tick` | uint64 | Monotonic |
| `checks_passed` | uint64 | >= 0 |
| `checks_failed` | uint64 | >= 0 |
| `compliance_ratio` | float [0.0, 1.0] | passed / (passed + failed), 1.0 if no checks |
| `violations` | list<string> | Empty if checks_failed == 0 |

---

### 9. MetaEvidence

Persisted evidence artifact.

| Field | Type | Invariant |
|---|---|---|
| `evidence_id` | UUID | Immutable |
| `session_id` | UUID | Links to MetaCognitionState |
| `tick` | uint64 | Monotonic |
| `stage` | string | Which pipeline stage produced it |
| `payload` | binary | Serialized stage output |
| `payload_hash` | SHA256 | hash(payload) |
| `previous_evidence_id` | UUID\|nil | Links to prior evidence; nil for first entry |
| `signature` | signature | Cryptographic chain integrity |

---

### 10. MetaReplay

Deterministic replay record of a session.

| Field | Type | Invariant |
|---|---|---|
| `replay_id` | UUID | Immutable |
| `session_id` | UUID | Links to MetaCognitionState |
| `reconstructed_events` | list<binary> | Ordered list of deterministic events |
| `event_count` | uint64 | Length of reconstructed_events |
| `verification_hash` | SHA256 | Hash of the full reconstructed trace |
| `is_complete` | bool | True iff all events were recovered |

---

### 11. MetaArchaeology

Reconstructed historical trace from archived or partial data.

| Field | Type | Invariant |
|---|---|---|
| `archaeology_id` | UUID | Immutable |
| `session_id` | UUID | Links to MetaCognitionState |
| `reconstructed_trace` | list<binary> | Best-effort reconstruction |
| `confidence` | float [0.0, 1.0] | How much of the trace was recovered |
| `gap_count` | uint64 | Number of missing segments |
| `gap_positions` | list<uint64> | Tick positions of each gap |
| `sources` | list<string> | Which archives were consulted |
