# Domain Readiness Model (Phase 20.98)

## Purpose

Compute readiness independently for each research domain. Each domain represents a field of knowledge or practice that the Constitutional OS may be called upon to govern, evolve, or support.

## Twenty Domains

| # | Domain | Readiness Based On |
|---|--------|-------------------|
| 1 | Engineering | Engineering artifacts, verification, validation |
| 2 | Physics | World models, scientific method, mathematics |
| 3 | Chemistry | World models, scientific method, discovery |
| 4 | Medicine | Knowledge graph, scientific capital |
| 5 | Cybernetics | Runtime, governance, evolution |
| 6 | Governance | Constitutional invariants, policy, council |
| 7 | Computation | Runtime, mathematics, replay |
| 8 | Agriculture | World models, knowledge graph |
| 9 | Energy | Resource optimization, runtime |
| 10 | Logistics | Engineering, optimization |
| 11 | Cognition | Cognitive runtime, metacognition |
| 12 | Materials | Scientific method, experimentation |
| 13 | Robotics | Engineering, runtime, world models |
| 14 | Economics | Civilizational runtime, governance |
| 15 | Philosophy | Constitutional principles, governance |
| 16 | Sociology | Civilizational runtime, governance |
| 17 | Linguistics | Knowledge graph, cognitive runtime |
| 18 | Aerospace | Engineering, world models, physics |
| 19 | Ecology | World models, knowledge graph, civilizational |
| 20 | Architecture | Engineering, ontology, archaeology |

## Domain Scoring

Each domain receives a readiness score (0.0–1.0) computed as:

```
domain_score[d] = Σ(dimension_weight[d][i] × dimension_score[i])
```

Where:
- `dimension_weight[d][i]` is the relevance weight of dimension `i` for domain `d`
- `dimension_score[i]` is the overall dimension score

Some dimensions may be weighted to 0 for domains where they are not applicable.

## Domain Readiness Matrix

The domain readiness matrix maps each of the 20 domains against the 10 readiness dimensions, producing a 20×10 matrix of relevance weights. This matrix is itself deterministic and content-addressed.
