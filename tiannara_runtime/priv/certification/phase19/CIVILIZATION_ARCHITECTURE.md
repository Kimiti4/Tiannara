# Phase 19 — Constitutional Civilizational Intelligence: Architecture

## Abstract

Phase 19 establishes Tiannara's autonomous scientific civilization — a self-governing, constitutionally bounded system of institutions, research programs, economic flows, and collaborative discovery operating under deterministic replay and certification.

## Architectural Principle

No new reasoning primitives are introduced. Phase 19 composes all previously certified systems (Phases 1–18) into a unified civilizational pipeline. Every component inherits the frozen semantics, replay guarantees, and certification invariants of its predecessors.

## Pipeline

```
CivilizationController
  → InstitutionManager
    → ResearchProgram
      → PortfolioGovernor
        → ScientificEconomy
          → CollaborationEngine
            → CivilizationKnowledgeGraph
              → Replay
                → Archaeology
```

## Core Concepts

- **Constitutional Institution**: Each institution is a constitutional research organization — its charter, membership, rules, and lifecycle are encoded as frozen artifacts subject to replay verification.
- **Scientific Discovery as Economic Asset**: Discoveries produced by research programs become constitutional economic assets within the ScientificEconomy. They carry novelty weight, maturity scores, and resource costs.
- **Deterministic Civilization**: Every civilizational state transition is logged, replayable, and archaeologically recoverable from artifact traces.

## System Boundaries

| Boundary | Scope |
|----------|-------|
| Controller | Civilization lifecycle, global governance, registry |
| Institution | Physics, Mathematics, Robotics, Medicine, Engineering institutes |
| Portfolio | Cross-institutional research portfolio governance |
| Economy | Capital ledger, rewards, resource allocation |
| Collaboration | Cross-domain discovery graph |
| Knowledge | Merged civilizational knowledge graph |
| Replay | Deterministic state reconstruction |
| Archaeology | Civilization archaeology from artifacts |

## Invariants

1. Every institution must be registered before it can host research programs.
2. Every research program must belong to exactly one institution.
3. Portfolio governance precedes economy settlement.
4. Collaboration edges only form between certified research programs.
5. All artifacts (evidence, replay, archaeology) are idempotent under replay.
6. The civilization knowledge graph is a monotonic DAG.
