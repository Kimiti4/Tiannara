# Theory Replay Model

## Purpose

Enable deterministic replay of the complete theory evolution timeline. Every
synthesis decision — formation, unification, splitting, contradiction, resolution,
framework construction — must be reconstructable from stored state.

## Replayable Events

| Event | Recorded Data |
|-------|---------------|
| Theory Formation | Input models, laws, discoveries; formation algorithm parameters |
| Theory Unification | Parent theories, unification criteria, merged output |
| Theory Splitting | Parent theory, split dimension, sub-theory outputs |
| Contradiction Detection | Conflicting entities, conflict type, evidence |
| Conflict Resolution | Contradiction ID, resolution type, justification |
| Framework Construction | Component theories, integration assumptions |
| Theory Evaluation | Score vector, per-dimension breakdown |
| Paradigm Shift | Old paradigm, new paradigm, driving evidence |

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
