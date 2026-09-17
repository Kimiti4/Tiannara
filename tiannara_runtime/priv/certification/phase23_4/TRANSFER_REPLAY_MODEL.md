# Transfer Replay Model

## Purpose

Enable deterministic replay of the complete transfer lifecycle. Every transfer
decision — discovery, abstraction, analogy, validation, adaptation, integration —
must be reconstructable from stored state.

## Replayable Events

| Event | Recorded Data |
|-------|---------------|
| Transfer Discovery | Source entity, target domain, similarity metrics |
| Abstraction | Input knowledge, abstraction level, abstracted form |
| Analogy Detection | Source elements, target elements, alignment score |
| Validation | Candidate ID, per-dimension results, outcome |
| Adaptation | Source entity, adaptation parameters, adapted entity |
| Integration | Adapted entity, integration target, certification |

## Replay Properties

- Replaying the same event log produces identical state
- Replay can be paused, stepped, and inspected at any point
- Partial replay (from a specific checkpoint) is supported
- External observers cannot distinguish live from replay

## Replay Data Model

Each replay event records:
- Event type
- Timestamp (logical, not wall-clock)
- Input entity IDs and snapshots
- Output entity IDs and snapshots
- Algorithm parameters
- Deterministic random seed (if applicable)
- Parent event IDs (for lineage)
- Content hash (for integrity verification)
