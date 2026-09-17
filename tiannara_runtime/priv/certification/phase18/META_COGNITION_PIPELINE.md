# Phase 18.7 — Meta-Cognition Pipeline

## Pipeline Overview

```
OutcomeSource → OutcomeCollector → OutcomeAnalyzer → PatternDetector → BiasDetector → LessonExtractor → MetaCognitionController → MetaCognitionState → Replay → Archaeology
```

## Transitions

### 1. OutcomeSource → OutcomeCollector
- **Inputs:** Raw decision records from Phases 18.2, 18.3, 18.4, 18.5, 18.6
- **Outputs:** Normalized Outcome events with phase provenance
- **Owner:** OutcomeCollector
- **Replay artifact:** `replay/outcome_source_events.json`
- **Evidence artifact:** `evidence/outcome_source_schema.json`
- **Archaeology artifact:** `archaeology/outcome_source_lineage.json`

### 2. OutcomeCollector → OutcomeAnalyzer
- **Inputs:** Normalized Outcome events
- **Outputs:** Scored OutcomeScore records (correctness, efficiency, alignment)
- **Owner:** OutcomeAnalyzer
- **Replay artifact:** `replay/collected_outcomes.json`
- **Evidence artifact:** `evidence/outcome_scoring_rubric.json`
- **Archaeology artifact:** `archaeology/outcome_collector_decay.json`

### 3. OutcomeAnalyzer → PatternDetector
- **Inputs:** OutcomeScore records
- **Outputs:** Pattern records with match sets and confidence
- **Owner:** PatternDetector
- **Replay artifact:** `replay/analyzed_outcomes.json`
- **Evidence artifact:** `evidence/pattern_detection_rules.json`
- **Archaeology artifact:** `archaeology/pattern_cluster_history.json`

### 4. PatternDetector → BiasDetector
- **Inputs:** Pattern records
- **Outputs:** BiasAssessment records with per-dimension scores
- **Owner:** BiasDetector
- **Replay artifact:** `replay/detected_patterns.json`
- **Evidence artifact:** `evidence/bias_dimension_definitions.json`
- **Archaeology artifact:** `archaeology/bias_trend_series.json`

### 5. BiasDetector → LessonExtractor
- **Inputs:** BiasAssessment records, Pattern records
- **Outputs:** Lesson records classified by type (actionable, reusable, transferable)
- **Owner:** LessonExtractor
- **Replay artifact:** `replay/bias_assessments.json`
- **Evidence artifact:** `evidence/lesson_extraction_rules.json`
- **Archaeology artifact:** `archaeology/lesson_derivation_graph.json`

### 6. LessonExtractor → MetaCognitionController
- **Inputs:** Lesson records
- **Outputs:** MetaCognitionState delta (awareness, readiness, bias profile adjustments)
- **Owner:** MetaCognitionController
- **Replay artifact:** `replay/extracted_lessons.json`
- **Evidence artifact:** `evidence/state_transition_rules.json`
- **Archaeology artifact:** `archaeology/meta_state_migrations.json`

### 7. MetaCognitionController → MetaCognitionState
- **Inputs:** MetaCognitionState delta
- **Outputs:** Updated persisted MetaCognitionState with version bump
- **Owner:** MetaCognitionController
- **Replay artifact:** `replay/state_deltas.json`
- **Evidence artifact:** `evidence/state_snapshot_schema.json`
- **Archaeology artifact:** `archaeology/state_version_history.json`

### 8. MetaCognitionState → Replay
- **Inputs:** Final MetaCognitionState
- **Outputs:** Full replay log of the reflection session
- **Owner:** Replay subsystem
- **Replay artifact:** `replay/session_replay.json`
- **Evidence artifact:** `evidence/replay_format_spec.json`
- **Archaeology artifact:** `archaeology/replay_compaction_log.json`

### 9. Replay → Archaeology
- **Inputs:** Replay log
- **Outputs:** Archaeology bundle (compressed, indexed, provenance-tracked)
- **Owner:** Archaeology subsystem
- **Replay artifact:** `archaeology/session_archive.json`
- **Evidence artifact:** `evidence/archaeology_retention_policy.json`
- **Archaeology artifact:** `archaeology/archaeology_index.json`
