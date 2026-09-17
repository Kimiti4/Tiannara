# Phase 20.8 — Optimization Replay Model

## Overview

Every optimization artifact supports deterministic replay. Replay must reproduce identical SHA-256 hashes at every step, across all optimization pipeline stages.

## Replay Types

### Metric Collection Replay
Reconstruct metric collection from observations. Must reproduce identical MetricSet including raw metrics, derived metrics, trends, and baseline comparisons.

### Bottleneck Detection Replay
Reconstruct bottleneck detection from metrics. Must reproduce identical BottleneckReport including bottleneck_id, severity, frequency, causal_chain, and evidence_root.

### Candidate Generation Replay
Reconstruct candidate generation from bottleneck and evidence sources. Must reproduce identical OptimizationCandidate set including expected_gain, expected_cost, expected_risk, and affected_domains.

### Trade-off Analysis Replay
Reconstruct trade-off analysis from candidate and performance profile. Must reproduce identical TradeoffReport including per-dimension scores, advantages, disadvantages, and risk profile.

### Simulation Replay
Reconstruct optimization simulation from candidate and current profile. Must reproduce identical predicted metrics, confidence bounds, and risk assessment.

### Recommendation Replay
Reconstruct recommendation from trade-off analysis and simulation. Must reproduce identical priority, recommendation_type, and expected_impact.

### Full Optimization Replay
Reconstruct the complete optimization lifecycle from observation through recommendation. Starting from the initial observation, replay every pipeline stage in order. Must reproduce identical fingerprints at every stage.

## Replay Chain Structure

```
step_hash[0] = SHA-256(genesis_seed || optimization_session_id)
step_hash[N] = SHA-256(step_hash[N-1] || stage_data[N])
root_hash = step_hash[N]  (final step)
```

## Deterministic Ordering

Replay steps follow the optimization pipeline order:

1. Observation
2. Metric Collection
3. Bottleneck Detection
4. Candidate Generation
5. Trade-off Analysis
6. Simulation
7. Recommendation
8. Experiment Request (if applicable)
9. Validation
10. Certification
11. Integration Request
12. Freeze

## Verification

- Every replay step must produce an identical SHA-256 hash to the recorded value
- If any step produces a different hash, replay is considered failed
- A failed replay invalidates the optimization's certification
- The OptimizationReplayRegistry tracks all replay roots and verification status

## Constraints

- Replay must be fully deterministic: same inputs always produce same outputs
- Replay must be acyclic: no replay step depends on a later step
- Replay must be content-addressed: every intermediate hash uniquely identifies that state
- Replay must be independent of runtime state: cold storage replay must reproduce identical hashes
