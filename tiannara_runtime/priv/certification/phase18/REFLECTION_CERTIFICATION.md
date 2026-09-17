# Phase 18.7 — Reflection Certification

## Validation Stages

### 1. Outcome Accuracy
- **Criterion:** Every ingested Outcome must be traceable to a source phase with matching decision_id.
- **Verification:** For each source phase (18.2–18.6), certify that ≥99.5% of outcomes are correctly attributed and scored.
- **Pass condition:** OutcomeScore composite values are reproducible within ±0.01 tolerance under identical input.

### 2. Pattern Determinism
- **Criterion:** Pattern detection must be deterministic given identical outcome sets and configuration.
- **Verification:** Run pattern detection twice on the same outcome set; pattern count and confidence values must match exactly.
- **Pass condition:** Zero variance across runs with identical parameters.

### 3. Bias Detection
- **Criterion:** Bias assessments must correctly identify known bias injections in test fixtures.
- **Verification:** Inject synthetic bias signals (e.g., skewed sample for confirmation bias) and confirm detection score ≥0.7 for the targeted dimension.
- **Pass condition:** Each bias dimension achieves recall ≥0.8 on test fixtures.

### 4. Lesson Reproducibility
- **Criterion:** Lesson extraction must produce identical lesson sets from identical pattern and bias inputs.
- **Verification:** Execute lesson extraction twice; compare lesson count, categories, and derivation trails.
- **Pass condition:** Full set equality with no missing or spurious lessons.

### 5. Meta-State Determinism
- **Criterion:** MetaCognitionState transitions must be deterministic.
- **Verification:** Apply identical lesson sets to identical pre-states; post-states must match exactly.
- **Pass condition:** Version hash equality across independent transition runs.

### 6. Archaeology Completeness
- **Criterion:** The Archaeology bundle must contain every artifact produced during the session.
- **Verification:** Enumerate all evidence, replay, and state artifacts; compare against archaeology index.
- **Pass condition:** Complete coverage — no artifact omitted from the archive.

### 7. Replay Fidelity
- **Criterion:** A full replay of the session log must reproduce the identical final MetaCognitionState.
- **Verification:** Execute the replay pipeline against the session replay artifacts; compare final state hash.
- **Pass condition:** State hash match between original execution and replay execution.

## Certification Summary

| Stage | Metric | Threshold |
|---|---|---|
| Outcome Accuracy | Attribution correctness | ≥99.5% |
| Pattern Determinism | Cross-run variance | 0% |
| Bias Detection | Per-dimension recall | ≥0.8 |
| Lesson Reproducibility | Cross-run lesson equality | Exact match |
| Meta-State Determinism | Version hash equality | Exact match |
| Archaeology Completeness | Artifact coverage | 100% |
| Replay Fidelity | State hash match | Exact match |
