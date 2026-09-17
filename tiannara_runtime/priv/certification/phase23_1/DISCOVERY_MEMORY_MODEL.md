# Discovery Memory Model

## Purpose

The Discovery Memory Model defines how discoveries are stored, indexed, retrieved, and linked within Tiannara's knowledge architecture. Discovery memory is content-addressed, immutable, and fully traceable through provenance chains.

## Memory Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Discovery Memory                       │
├─────────────────────────────────────────────────────────┤
│  Observation Store                                       │
│  ├─ All observations, immutable, content-addressed       │
│  └─ Indexed by source, type, time, relevance            │
├─────────────────────────────────────────────────────────┤
│  Question Store                                          │
│  ├─ All questions, linked to source observations         │
│  └─ Indexed by status, priority, domain                 │
├─────────────────────────────────────────────────────────┤
│  Hypothesis Store                                        │
│  ├─ All hypotheses, linked to questions                  │
│  └─ Indexed by status, confidence, domain               │
├─────────────────────────────────────────────────────────┤
│  Evidence Store                                          │
│  ├─ All evidence, immutable, linked to experiments       │
│  └─ Indexed by type, hypothesis, reproducibility        │
├─────────────────────────────────────────────────────────┤
│  Theory Store                                            │
│  ├─ All theories, linked to supporting evidence          │
│  └─ Indexed by domain, status, scope                    │
├─────────────────────────────────────────────────────────┤
│  Provenance Graph                                        │
│  ├─ Links between all discovery artifacts                │
│  └─ Supports forward and backward provenance traversal  │
└─────────────────────────────────────────────────────────┘
```

## Memory Operations

| Operation | Description |
|-----------|-------------|
| Record | Immutable storage with content addressing |
| Retrieve | Query by ID, type, time, source, domain |
| Link | Create provenance edges between artifacts |
| Traverse | Forward/backward provenance traversal |
| Query | Complex queries across memory stores |

## Content Addressing

Every artifact is content-addressed using SHA-256 of its content:
- Artifact ID = hash(content)
- Modification creates a new artifact with a new ID
- Old artifacts are never deleted
- Provenance edges link versions

## Provenance Graph

The provenance graph links:
- Observations → Questions
- Questions → Hypotheses
- Hypotheses → Predictions
- Predictions → Experiments
- Experiments → Evidence
- Evidence → Validation
- Validation → Theories
- Theories → Knowledge
