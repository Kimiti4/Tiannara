# Discovery Archaeology Model

## Purpose

The Discovery Archaeology Model enables reconstruction of why discoveries occurred, what evidence existed, which theories competed, which hypotheses failed, and how knowledge evolved over time.

## Archaeological Questions

The model answers:
- Why were specific discoveries made?
- What evidence supported each discovery?
- What alternative hypotheses were considered?
- Which theories competed and which prevailed?
- Why did certain hypotheses fail?
- How did knowledge evolve across domains?
- What unknown factors influenced discovery paths?

## Archaeology Architecture

```
┌─────────────────────────────────────────────────────────┐
│               Discovery Archaeology Engine               │
├─────────────────────────────────────────────────────────┤
│  Discovery Trace Layer                                  │
│  ├─ Every discovery links to its inputs                 │
│  ├─ Every discovery links to its evidence               │
│  └─ Every discovery links to its alternatives           │
├─────────────────────────────────────────────────────────┤
│  Knowledge Evolution Layer                              │
│  ├─ Knowledge state over time                           │
│  ├─ Knowledge milestones and transitions                │
│  └─ Knowledge divergence and convergence                │
├─────────────────────────────────────────────────────────┤
│  Hypothesis Competition Layer                           │
│  ├─ Which hypotheses competed                            │
│  ├─ How competition was resolved                        │
│  └─ What evidence determined the outcome                │
├─────────────────────────────────────────────────────────┤
│  Narrative Reconstruction Layer                         │
│  ├─ Natural language description of discovery chains    │
│  ├─ Causal narrative of knowledge evolution             │
│  └─ Summary of scientific journey                       │
└─────────────────────────────────────────────────────────┘
```

## Archaeology Record

```
DiscoveryArchaeology {
  archaeology_id: content-addressed,
  epoch: integer,
  discovery_trace: [
    {
      discovery_id: reference,
      stage: enum,
      timestamp: integer,
      inputs: [content_hash],
      alternatives_considered: [{alternative, rejection_reason}],
      evidence: [evidence_id],
      outcome: content_hash
    }
  ],
  knowledge_evolution: {
    timeline: [{timestamp, knowledge_state, transition}],
    milestones: [{timestamp, discovery, impact}]
  },
  narrative: string,
  archaeology_hash: string,
  timestamp: integer
}
```

## Narrative Generation

The archaeology engine generates human-readable narratives:
- "Discovery was made because observation of X contradicted existing theory Y"
- "Hypothesis A was preferred over B because it predicted outcomes with higher accuracy"
- "Theory X was replaced by Y after experiment Z produced contradictory evidence"
- "Knowledge of domain D evolved through discoveries 1, 2, 3..."
