# Phase 18.7 — Reflection Data Model

## Abstract Definitions

### Reflection
Top-level entity representing a single self-evaluation cycle. Contains a unique `reflection_id`, `session_ref` to the originating session, `pipeline_version`, `timestamp`, and a collection of Outcomes, Patterns, Biases, and Lessons produced during the cycle.

### ReflectionSession
A discrete run of the meta-cognition pipeline. Contains `session_id`, `start_time`, `end_time`, `phase_sources` (list of contributing phases 18.2–18.6), `state_before` and `state_after` (MetaCognitionState snapshots), and `status` (running, completed, failed).

### Outcome
A decision record ingested from a source phase. Fields: `outcome_id`, `phase_id`, `decision_id`, `timestamp`, `input_context` (hash or ref), `decision_value`, `result_value`, `expected_value` (if available).

### OutcomeScore
Derived evaluation of an Outcome. Fields: `score_id`, `outcome_ref`, `correctness` (0.0–1.0), `efficiency` (0.0–1.0), `alignment` (0.0–1.0), `composite` (weighted sum), `scoring_ruleset` (which rubric was applied).

### Pattern
A detected recurrence in the outcome set. Fields: `pattern_id`, `pattern_type` (frequency, sequence, anomaly), `confidence` (0.0–1.0), `support_count`, `description`, `derived_at`.

### PatternMatch
An instance of a Pattern firing against a specific Outcome. Fields: `match_id`, `pattern_ref`, `outcome_ref`, `match_strength` (0.0–1.0), `context_hash`.

### BiasAssessment
Container for a full bias evaluation of a decision set. Fields: `assessment_id`, `session_ref`, `timestamp`, `dimensions` (list of BiasDimension), `overall_bias_risk` (0.0–1.0).

### BiasDimension
A scored cognitive bias dimension. Fields: `dimension_id`, `assessment_ref`, `bias_type` (confirmation, availability, anchoring, framing, overconfidence), `score` (0.0–1.0), `evidence_count`, `severity` (low, medium, high, critical).

### Lesson
An extracted insight from pattern and bias analysis. Fields: `lesson_id`, `session_ref`, `category` (actionable, reusable, transferable), `description`, `source_pattern_ref`, `source_bias_ref`, `derived_at`, `applied_count`.

### LessonApplication
Tracks when a Lesson was applied in a subsequent decision. Fields: `application_id`, `lesson_ref`, `applied_in_phase`, `applied_at`, `outcome_ref`, `effectiveness` (0.0–1.0).

### MetaCognitionState
The persistent awareness and adaptation state. Fields: `state_id`, `version`, `awareness_level` (0.0–1.0), `adaptation_readiness` (0.0–1.0), `bias_profile` (map of bias_type → score), `applied_lessons` (list of lesson refs), `last_updated`.

### ReflectionEvidence
An immutable artifact capturing the rationale, rules, and schemas used during a reflection session. Fields: `evidence_id`, `session_ref`, `artifact_type`, `content_hash`, `storage_path`, `created_at`.

### ReflectionReplay
An ordered log of all pipeline transitions in a session, enabling deterministic re-execution. Fields: `replay_id`, `session_ref`, `step_sequence`, `events` (ordered list of transition records), `compaction_status`.

### ReflectionArchaeology
A compressed, indexed archive of a reflection session for long-term storage and audit. Fields: `archaeology_id`, `session_ref`, `archive_format`, `index_path`, `retention_period_days`, `size_bytes`, `checksum`.
