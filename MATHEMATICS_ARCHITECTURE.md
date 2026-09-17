# Phase 16.X.0 — Constitutional Mathematics Architecture

document_version: 16.X.0

phase: 16.X

status: Architecture Review (no implementation)

owner: Constitutional Research Council

depends_on:
  - PHASE16_RUNTIME_TEST_REPORT.md
  - MATHEMATICAL_DISCOVERY_STACK.md

supersedes: null

constitutional_lifecycle:
  This document is part of the Constitutional Development Lifecycle (CDL).
  CAR deliverables (Phase 16.X.0):
    - MATHEMATICS_ARCHITECTURE.md (this file)
    - MATHEMATICS_PIPELINE.md
    - MATHEMATICS_DATA_MODEL.md
    - MATHEMATICS_REPLAY_MODEL.md
    - MATHEMATICS_CERTIFICATION.md

---

## Purpose

This document defines the **constitutional mathematics architecture** for Phase 16.X.

Mathematics is elevated from a research discipline into Tiannara's universal reasoning substrate. Every future capability — scientific (Phase 15), research (Phase 16), world modeling (Phase 17), engineering (Phase 18), civilizational coordination (Phase 19), and constitutional governance (Phase 20) — inherits mathematical representations, proofs, and formal verification rather than ad hoc symbolic structures.

This architecture review introduces **no runtime implementation**. It establishes the structural foundation that all subsequent sub-phases (X.1 through X.999) build upon.

---

## Constitutional Principle

Mathematics is **not** a parallel capability. It is the substrate beneath every capability:

```
Before Phase 16.X:

    [Ad hoc structures] → Science / Research / Engineering / Governance

After Phase 16.X:

          Mathematics Foundation
                 │
        ┌────────┼────────┐
        ▼        ▼        ▼
    Science   Research   Engineering   ... (all future phases)
```

---

## Relationship to Existing Phases

### Phase 15 (Constitutional Scientific Discovery) — Unchanged

Phase 15's scientific discovery stack (Observation → Hypothesis → Experiment → Evidence → Discovery) continues unchanged. Phase 16.X does not modify it. Instead, scientific discoveries that generate mathematical questions (invariants, symmetries, topological structure) feed into the Mathematical Discovery Stack, and mathematical discoveries provide tools back to science.

### Phase 16 (Autonomous Constitutional Research) — Unchanged

Phase 16's autonomous research pipeline (13-stage deterministic model) continues unchanged. Phase 16.X supplies the mathematical substrate that the research engine may call upon — but does not alter any frozen contract, schema, or gate.

### Phase 16.95 (Independent Constitutional Audit) — Unchanged

The independent auditor remains constitutionally separate. Phase 16.X introduces its own independent audit (X.96) that mirrors the same constitutional constraints.

### Forward Phases (17–20)

Phases 17–20 become **clients** of the mathematics layer. They consume proofs, symbolic computations, formal verifications, and mathematical knowledge without reimplementing mathematical infrastructure.

---

## Existing Math-Adjacent Code: Absorption Strategy

The codebase already contains 25+ math-adjacent modules across Python and Elixir. Phase 16.X must absorb or formally deprecate each one to avoid divergent behavior:

| Module | Location | Disposition | Rationale |
|--------|----------|-------------|-----------|
| `DoCalculusEngine` | `tiannara_core/interpretability/` | Absorb → symbolic engine causal domain (X.3) | Absorbs only symbolic rules (3 rules of do-calculus, backdoor/frontdoor criterion identification, identifiability checking). Excludes numerical estimation functions (`estimate_causal_effect_backdoor`, `estimate_causal_effect_frontdoor`) which remain in Phase 17 territory. |
| `SymbolicSimplifier` | `tiannara_runtime/opc/validation/` | Absorb → symbolic computation engine (X.3) | Algebraic simplification is a primitive of the symbolic kernel |
| `TheoremEngine` | `tiannara_core/logic/` | Absorb → proof engine (X.4) | Forward/backward chaining is a proof strategy |
| `ConstraintSolver` | `tiannara_core/logic/` | Absorb → proof engine (X.4) | CSP solving is a proof strategy for finite domains |
| `CategoryTheoreticValidator` | `tiannara_runtime/kernel/` | Absorb → formal verification (X.6) | Functoriality verification is a formal method |
| `TensorConstraintSolver` (2x) | `tiannara_runtime/opc/` + `meta/` | Deprecate → replaced by symbolic engine | Two implementations with different rank limits violates determinism |
| `SymbolicValidator` | `tiannara_runtime/opc/validator/` | Deprecate → replaced by symbolic engine | Stability validation moves to symbolic engine |
| `ProofSystem` (EID) | `tiannara_runtime/eid/` | Absorb → proof engine (X.4) | Emergence validation becomes a proof strategy |
| `EquilibriumEngine` | `tiannara_runtime/rrg/` | Remain (RRG domain-specific) | RRG-specific; not general mathematics |
| `PersistentHomology` | `tiannara_runtime/topology/` | Absorb → symbolic engine topology domain (X.3 Iteration 2) | Topology is a symbolic domain; deferred until after Proof Engine (X.4) per staged build strategy |
| `AxiomaticGenerator` | `tiannara_runtime/phase9/mes/` | Absorb → mathematical ontology (X.2) | Axiom generation is a mathematics KG function |
| `AxiomDiversityPreserver` | `tiannara_runtime/scl/` | Absorb → mathematical ontology (X.2) | Axiom diversity is a mathematics KG property |
| `LemmaNode` (memory_graph) | `tiannara_runtime/ecology/` | Absorb → mathematical knowledge graph (X.2) | Lemma nodes belong in the mathematics KG |

All absorptions are **structural renames with adapter shims**. The old modules continue to function during the transition epoch, then are deprecated and removed at the end of Phase 16.X.

---

## Dependency Architecture

Follows the Constitutional Development Lifecycle (CDL) uniform phase numbering:

```
Phase 16.X.0   Constitutional Architecture Review (5 deliverables, 8 mandatory audits)
       │
       ▼
Phase 16.X.05  Constitutional Freeze (schemas, APIs, behaviours, contracts frozen)
       │
       ▼
Phase 16.X.1   Ontology (structs, types, validators, serialization, content-addressed IDs)
       │
       ▼
Phase 16.X.2   Mathematics Registry (identifiers, registrations, lifecycle definitions)
       │
       ▼
Phase 16.X.3   Core Infrastructure (Knowledge Graph, Symbolic Engine kernel)
       │
       ├────────────────────────────────────┐
       ▼                                    ▼
Phase 16.X.4   Replay Layer           Phase 16.X.5   Archaeology Layer
       │                                    │
       └────────────────┬───────────────────┘
                        ▼
Phase 16.X.6   Runtime (Proof Engine, Conjecture Engine, Verification Engine,
               Mathematics Observatory)
       │
       ▼
Phase 16.X.7   Validation (7+ validation campaigns)
       │
       ▼
Phase 16.X.8   Independent Audit (reproduction from evidence only)
       │
       ▼
Phase 16.X.9   Long-Horizon Validation (10–100 year projections)
       │
       ▼
Phase 16.X.95  Readiness (MRI — Mathematical Readiness Index)
       │
       ▼
Phase 16.X.96  Pre-Certification Audit (deliverable completeness, cross-references)
       │
       ▼
Phase 16.X.97  Consolidation (summary of all deliverables, audits, risks)
       │
       ▼
Phase 16.X.98  Constitutional Readiness (READY or BLOCKED decision)
       │
       ▼
Phase 16.X.999 Constitutional Certification (CERTIFIED or WITHHELD)
```

---

## Constitutional Requirements

Every component in Phase 16.X must satisfy:

1. **Determinism** — Same input, same output, always. No wall-clock dependence. Tie-breaking by content hash ordering. Randomness from content-addressed seeds only.
2. **Replay** — Every mathematical operation is replayable from immutable artifacts. Proofs, symbolic reductions, and verifications must produce identical results on replay.
3. **Archaeology** — Every mathematical artifact (axiom, definition, conjecture, proof, theorem) has an archaeology record: origin, purpose, owner, dependencies, lineage.
4. **Content-addressed IDs** — All mathematical entities identified by blake3 hashes of canonical serialization.
5. **No certification in auditor** — The independent auditor (X.96) produces assertions, not certificates. Phase 16.X substitutes `MathematicalAssertion` for `MathematicalCertificate` in all auditor-facing interfaces.
6. **Fail-closed** — If any mathematical operation cannot produce a deterministic result, it fails closed (no result, no fallback).
7. **Evidence-only audit** — The independent auditor consumes only exported immutable artifacts. No runtime imports, no ETS, no database, no network.

---

## Key Architectural Boundary: Two Knowledge Graphs

Phase 16.1 defines a Scientific Knowledge Graph (`KnowledgeGraph` module) storing experimental evidence chains (ObservationNode → HypothesisNode → ExperimentNode → TheoryNode → EvidenceNode).

Phase 16.X.2 defines a **Mathematical Knowledge Graph** storing proof structure and abstraction hierarchies (AxiomNode → DefinitionNode → ConjectureNode → ProofNode → TheoremNode → CorollaryNode → AlgorithmNode).

These are **complementary, not overlapping**:

```
Scientific KG                          Mathematical KG
─────────────────                      ─────────────────
ObservationNode                        AxiomNode
HypothesisNode                         DefinitionNode
ExperimentNode                         ConjectureNode
TheoryNode                             ProofNode
EvidenceNode                           TheoremNode
                                       CorollaryNode
                                       AlgorithmNode
                                       ApplicationNode
```

The scientific KG asks: "What evidence supports this claim?"  
The mathematical KG asks: "What proof establishes this theorem?"

Both KGs are first-class citizens. Neither replaces the other. The feedback loop between them is mediated by the orchestrator layer.

---

## Frozen Interfaces Appendix (Spec-only)

### Frozen Schemas

Axiom, Definition, Conjecture, Lemma, Theorem, Proof, Corollary, Counterexample, MathematicalProgram, MathematicalExperiment, MathematicalAssertion, **ArchaeologyRecord**

`ArchaeologyRecord` minimum fields:

```elixir
%ArchaeologyRecord{
  origin: String,           # which system/phase created this artifact
  purpose: String,          # why it exists
  owner: String,            # constitutional owner
  dependencies: [String],   # IDs of artifacts this depends on
  lineage: [String]         # provenance chain (parent artifacts)
}
```

### Frozen APIs

MathematicsEngine, ProofEngine, ConjectureEngine, SymbolicEngine, VerificationEngine, MathematicsReplay, MathematicsArchaeology, MathematicsObservatory

### Frozen Behaviours

ProofBehaviour, ConjectureBehaviour, VerificationBehaviour, SymbolicBehaviour, OptimizationBehaviour, ReplayBehaviour

---

## Status

Architecture Review — no implementation.

All 5 CAR deliverables (MATHEMATICS_ARCHITECTURE.md, MATHEMATICS_PIPELINE.md, MATHEMATICS_DATA_MODEL.md, MATHEMATICS_REPLAY_MODEL.md, MATHEMATICS_CERTIFICATION.md) must be reviewed before any sub-phase begins implementation.

---

## Mandatory Audits

The following 8 mandatory CAR audits are defined. Each must pass before Phase 16.X.05 (Freeze) may begin.

### 1. Ownership Audit
Every entity, schema, API, and behaviour has exactly one constitutional owner: the Constitutional Research Council. Verified across all 30 schemas, 9 APIs, 6 behaviours. No orphan entities.

### 2. Replay Audit
Every mathematical operation is replayable from immutable artifacts. Three replay levels defined (hash → semantic → structural). See MATHEMATICS_REPLAY_MODEL.md.

### 3. Archaeology Audit
Every mathematical artifact carries an ArchaeologyRecord with 5 minimum fields: origin, purpose, owner, dependencies, lineage. See MATHEMATICS_DATA_MODEL.md §ArchaeologyRecord.

### 4. Determinism Audit
All operations deterministic: same input → same output always. Tie-breaking by content hash. No wall-clock or entropy sources. Randomness from content-addressed seeds only.

### 5. Dependency Audit
Explicit dependency graph with no hidden cycles. Inter-phase dependencies documented (Phase 15/16 unchanged, Phase 17+ are clients). See MATHEMATICS_PIPELINE.md.

### 6. Evidence Flow Audit
Mathematical evidence flows unidirectionally (Axiom → Definition → Conjecture → Proof → Theorem → Application). No bypass paths. Fail-closed pipeline.

### 7. Boundary Audit
No Phase 17 causal/world-model functionality. DoCalculusEngine scoped to symbolic rules only. No import of scientific evidence (Phase 15) or research artifacts (Phase 16).

### 8. Scalability Audit
Architecture scales to bounded limits:
- 10³ axioms per set, 10⁴ definitions, 10⁵ conjectures, 10⁶ proof steps, 10⁷ KG nodes
- All operations respect deterministic budget bounds
- Fail-closed when limits exceeded
- Scaling beyond bounds requires new constitutional freeze epoch
