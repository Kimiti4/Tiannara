# Phase 20.7 — Experiment Replay Model

## Overview

Every experiment artifact supports deterministic replay. Replay must reproduce identical SHA-256 hashes at every step, across all experiment pipeline stages, without any runtime state.

## Replay Types

### Proposal Replay
Reconstruct the experiment proposal from its originating engineering, discovery, or research request. Must reproduce identical experiment_id, hypothesis, variables, and statistical plan.

### Design Replay
Reconstruct the experiment design from the proposal and constitutional rules. Must reproduce identical ExperimentPlan including variables, controls, sample size, and success/failure criteria.

### Environment Replay
Reconstruct the execution environment from the ExperimentPlan. Must reproduce identical environment snapshot hash and configuration fingerprint.

### Execution Replay
Reconstruct experiment execution from the environment and plan. Must reproduce identical observations, execution trace, and timing data. Every treatment application, observation collection, and state transition must reproduce identical hashes.

### Analysis Replay
Reconstruct statistical analysis from observations and statistical plan. Must reproduce identical test statistics, p-values, confidence intervals, effect sizes, and classification.

### Reproducibility Replay
Reconstruct the reproducibility verification. Must reproduce identical hash comparisons and reproducibility level determination.

### Full Experiment Replay
Reconstruct the complete experiment lifecycle from proposal through freeze. Starting from the experiment proposal, replay every pipeline stage in order. Must reproduce identical fingerprints at every stage.

## Replay Chain Structure

```
step_hash[0] = SHA-256(genesis_seed || experiment_id)
step_hash[N] = SHA-256(step_hash[N-1] || stage_data[N])
root_hash = step_hash[N]  (final step)
```

Where stage_data[N] = canonical binary encoding of stage N's inputs and outputs.

## Deterministic Ordering

Replay steps follow the experiment pipeline order:

1. Proposal
2. Constitutional Review
3. Resource Reservation
4. Environment Preparation
5. Execution
6. Observation Capture
7. Statistical Analysis
8. Result Classification
9. Reproducibility Verification
10. Knowledge Integration
11. Archaeology Recording
12. Freeze

Each stage must replay before its dependent stage.

## Verification

- Every replay step must produce an identical SHA-256 hash to the recorded value
- If any step produces a different hash, replay is considered failed
- A failed replay invalidates the experiment's certification
- The ExperimentReplayRegistry tracks all replay roots and verification status

## Constraints

- Replay must be fully deterministic: same inputs always produce same outputs
- Replay must be acyclic: no replay step depends on a later step
- Replay must be content-addressed: every intermediate hash uniquely identifies that state
- Replay must be independent of runtime state: cold storage replay must reproduce identical hashes
- Reproducibility verification must itself be reproducible
