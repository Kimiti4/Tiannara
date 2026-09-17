# Phase 18.7 — Reflection Replay Model

## Root

The replay root is `reflection_session_id`. Every replay log is partitioned by session and ordered by step sequence.

## Reconstructed Stages

### Outcome Analysis Reconstruction
For each outcome ingested during the session, the replay log records:
- `source_phase` and `decision_id` for provenance
- The raw `decision_value` and `result_value`
- The computed `OutcomeScore` with per-dimension breakdown
- The scoring ruleset version applied

Replay verification asserts that re-running the outcome analysis on identical inputs yields identical scores.

### Pattern Detection Reconstruction
For each pattern emitted, the replay log captures:
- `pattern_type` and the set of `PatternMatch` records
- The algorithm configuration (frequency thresholds, sequence window, anomaly sensitivity)
- The `confidence` and `support_count` at detection time

Replay determinism requires that the same outcome set produces the same pattern set under identical configuration.

### Bias Assessment Reconstruction
For each BiasAssessment, the replay log stores:
- The full set of `BiasDimension` scores
- The evidence count per bias type
- The overall bias risk composite
- The dimension definitions version

Replay must reproduce identical bias scores given the same pattern inputs.

### Lesson Extraction Reconstruction
For each Lesson, the replay log includes:
- The derivation trail: which patterns and bias dimensions triggered the lesson
- The category classification (actionable, reusable, transferable)
- The description text (hashed for equality checking)

Replay must produce identical lesson sets from the same pattern and bias inputs.

### Meta-Cognition State Transition Reconstruction
For each state delta, the replay log records:
- The pre-image state version and hash
- The delta applied (awareness, readiness, bias profile changes)
- The post-image state version and hash
- The transition ruleset version

Replay of the full state delta sequence must produce an identical final `MetaCognitionState`.

## Replay Artifact Structure

```
reflection_sessions/
  {session_id}/
    replay/
      outcome_source_events.json
      collected_outcomes.json
      analyzed_outcomes.json
      detected_patterns.json
      bias_assessments.json
      extracted_lessons.json
      state_deltas.json
      session_replay.json
```

Each file is a JSON array of ordered transition records. The `session_replay.json` is a master index referencing all step sequences with hashes for integrity verification.
