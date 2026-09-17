# Phase 17.8 — Research Replay Model

## Replay Architecture

Every autonomous research action must be deterministically replayable from
immutable inputs. The replay model extends Phase 17.7 Digital Twin replay
to cover the full research lifecycle.

## Replay Hierarchy

```
ResearchProgram.replay_fingerprint
    │
    ├── knowledge_gap fingerprints
    ├── research_question fingerprints
    ├── hypothesis fingerprints
    ├── experiment.portfolio fingerprints
    │      │
    │      ├── experiment[].replay_fingerprint
    │      │      │
    │      │      ├── experiment design hash
    │      │      ├── digital_twin simulation replay
    │      │      └── evidence collection hash
    │      │
    │      └── portfolio optimization hash
    │
    ├── experiment_schedule fingerprint
    ├── evidence_ledger hashes
    ├── theory_update fingerprints
    └── knowledge_integration fingerprint
```

## Fingerprint Computation

Each research artifact has a `replay_fingerprint` computed as:

```
fp_<SHA256(canonical_representation)>
```

The canonical representation drops only:
- `replay_fingerprint` (self-reference)
- `created_at` (irrelevant for content identity)
- Archaeology/internal IDs that are derived from content

## Replay Verification

### verify_research_program(program)
1. Compute fingerint of program excluding replay_fingerprint
2. Compare with stored replay_fingerprint
3. If match, recursively verify all sub-artifacts
4. All must match for program to be replay-verified

### verify_experiment(experiment)
1. Reconstruct experiment design from canonical inputs
2. Re-execute in Digital Twin with identical seed
3. Compare outcome fingerprint
4. Must match stored evidence hashes

### verify_campaign(campaign)
1. Re-execute all experiments in campaign order
2. Verify each experiment outcome sequentially
3. Compare final campaign fingerprint

## Determinism Requirements

1. All random number generators use seeded, deterministic algorithms
2. All scheduling decisions use deterministic ordering
3. All priority calculations use deterministic functions
4. All theory updates are pure functions of evidence
5. All archaeology records are immutable append-only
