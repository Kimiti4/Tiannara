# Long-Horizon Archaeology Model (Phase 20.97)

## Purpose

Define the archaeology model for long-horizon validation. Every generation must answer: what changed, why, which discoveries motivated it, which engineering artifacts changed, which mathematical structures evolved, which governance decisions occurred, which runtime generation resulted, and how can the generation be reconstructed.

## Per-Generation Archaeology Record

Each generation's archaeology deposit answers:

| Question | Answer Source |
|----------|--------------|
| What changed? | Evolution event descriptions |
| Why? | Evidence chain for each event |
| Which discoveries motivated it? | Discovery event references |
| Which engineering artifacts changed? | Engineering change records |
| Which mathematical structures evolved? | Mathematical domain changes |
| Which governance decisions occurred? | Governance event records |
| Which runtime generation resulted? | Runtime snapshot hash |
| How can the generation be reconstructed? | Replay chain + archaeology artifacts |

## Archaeology Deposit Structure

Per generation:
```
Generation[N] Archaeology
  ├── Generation snapshot (all domain hashes)
  ├── Evolution event records (ordered)
  ├── Evidence chains (per event)
  ├── Continuity reports (per domain)
  ├── Metrics snapshot
  ├── Replay chain segment
  └── Parent generation reference
```

## Archaeology Continuity

- Every generation must have a complete archaeology record
- Archaeology records form a continuous chain
- No generation may be skipped or omitted
- Archaeology must be verifiable independently of runtime
- Archaeology must support full OS reconstruction

## Failure Recording

All failures produce archaeological explanations:
- Generation corruption → archaeology record with suspicion hash
- Knowledge drift → archaeology record with drift magnitude
- Governance drift → archaeology record with invariant violation
- Replay drift → archaeology record with mismatch details
- Scientific stagnation → archaeology record with productivity analysis
