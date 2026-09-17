# Literature Replay Model

## Purpose

Enable deterministic replay of the complete literature integration lifecycle.
Every decision — acquisition, extraction, contradiction detection, consensus
formation, synthesis, integration — must be reconstructable from stored state.

## Replayable Events

| Event | Recorded Data |
|-------|---------------|
| Publication Acquisition | Source, authentication result, document representation |
| Claim Extraction | Publication ID, extracted claims with context |
| Evidence Extraction | Publication ID, extracted evidence, mapped claims |
| Citation Graph Update | New citation edges, context, strength |
| Contradiction Detection | Conflicting claims, contradiction type, evidence |
| Consensus Update | Consensus state per topic, evidence weights |
| Research Gap Discovery | Gap type, description, supporting publications |
| Literature Synthesis | Input claims, synthesis type, output theme/meta-theory |
| Meta-Analysis | Input studies, method, pooled results |
| Knowledge Integration | Integrated claims, target systems, certification |

## Replay Properties

- Replaying the same event log produces identical state
- Replay can be paused, stepped, and inspected at any point
- Partial replay (from a specific checkpoint) is supported
- External observers cannot distinguish live from replay
