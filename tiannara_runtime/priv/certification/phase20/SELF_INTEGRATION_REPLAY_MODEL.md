# Phase 20.9 — Self-Integration Replay Model

## Overview

Every self-integration artifact supports deterministic replay. Replay must reproduce identical SHA-256 hashes at every step, across all integration pipeline stages, without any runtime state.

## Replay Types

### Proposal Replay
Reconstruct the integration proposal from its originating improvement (engineering, experiment result, or optimization). Must reproduce identical proposal_id, scope, affected subsystems, and evidence chain.

### Compatibility Replay
Reconstruct the 9-dimension compatibility analysis. Must reproduce identical pass/fail decisions and diagnostics for every dimension.

### Mathematical Verification Replay
Reconstruct mathematical consistency verification. Must reproduce identical consistency confirmation and proof impact analysis.

### Replay Verification Replay
Reconstruct replay compatibility verification. Must reproduce identical chain continuity assessment and hash predictions.

### Knowledge Preservation Replay
Reconstruct knowledge preservation check. Must reproduce identical consistency metrics and preservation confirmation.

### Promotion Decision Replay
Reconstruct the promotion decision from all prior artifacts. Must reproduce identical promotion_state assignment and conditions.

### Rollforward Replay
Reconstruct the generation transition. Must reproduce identical intermediate state hashes, migrated state hashes, and rollforward_hash.

### Generation Freeze Replay
Reconstruct the generation freeze. Must reproduce identical constitutional_hash and archaeology_root.

### Full Self-Integration Replay
Reconstruct the complete self-integration lifecycle from proposal through historical preservation. Starting from the integration proposal, replay every pipeline stage in order. Must reproduce identical fingerprints at every stage.

## Replay Chain Structure

```
step_hash[0] = SHA-256(genesis_seed || integration_session_id)
step_hash[N] = SHA-256(step_hash[N-1] || stage_data[N])
root_hash = step_hash[N]  (final step)
```

## Deterministic Ordering

Replay steps follow the integration pipeline order:

1. Integration Proposal
2. Compatibility Analysis
3. Mathematical Verification
4. Replay Verification
5. Knowledge Preservation Check
6. Generation Promotion Decision
7. Sandbox Runtime
8. Canary Runtime
9. Production Candidate
10. Generation Freeze
11. Historical Preservation

## Verification

- Every replay step must produce an identical SHA-256 hash to the recorded value
- If any step produces a different hash, replay is considered failed
- A failed replay invalidates the integration's certification
- The SelfIntegrationReplayRegistry tracks all replay roots and verification status

## Constraints

- Replay must be fully deterministic: same inputs always produce same outputs
- Replay must be acyclic: no replay step depends on a later step
- Replay must be content-addressed: every intermediate hash uniquely identifies that state
- Replay must be independent of runtime state: cold storage replay must reproduce identical hashes
