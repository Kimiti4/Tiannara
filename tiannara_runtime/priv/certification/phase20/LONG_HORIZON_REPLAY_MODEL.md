# Long-Horizon Replay Model (Phase 20.97)

## Purpose

Define the replay model for long-horizon validation. Replay reconstructs the entire generation history — all evolution events, all runtime transitions, all knowledge transitions, all governance decisions — with identical hashes required across all generations.

## Replay Scope

| Replay Type | Coverage | Description |
|-------------|----------|-------------|
| Full | Genesis → Latest | Complete generation history replay |
| Generation Chain | N consecutive generations | Subset replay for targeted verification |
| Event Chain | Single lineage of events | Event-level replay across generations |
| Domain Chain | Single domain across generations | Domain-specific continuity verification |

## Replay Structure

```
Generation 1: state_hash[1] → step_hash[1]
    ↓
Generation 2: state_hash[2] → step_hash[2] = SHA-256(gen2 || state_hash[2] || step_hash[1])
    ↓
Generation N: state_hash[N] → step_hash[N] = SHA-256(genN || state_hash[N] || step_hash[N-1])
    ↓
Chain Root: root_hash = step_hash[N]
```

## Replay Verification

For each generation in the replay:
1. Load generation snapshot from archaeology
2. Replay all evolution events deterministically
3. Compute expected state after events
4. Compare against recorded generation state hash
5. Compute step hash
6. Compare against recorded step hash

## Identical Hash Requirements

- Full replay from Genesis to Generation 100,000 must produce identical hashes
- No tolerance for hash mismatch at any generation
- Any mismatch = replay drift (critical failure)
- Mismatch triggers archaeological investigation
