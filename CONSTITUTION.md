# Tiannara Constitutional Architecture

**Version**: 1.1  
**Status**: FROZEN (Phase 11.5 + Principle 15)  
**Validated Through**: Run 18 (20k ticks, invariant holds) | Capability 12.10 (Distributed Scientific Validation)

---

## Preamble

This document defines the constitutional infrastructure of Tiannara ASC (Autonomous Software Civilization). These subsystems are considered immutable except for bug fixes and performance optimizations. All future phases must consume these APIs rather than redefine them.

---

## Article I: Canonical Entity Graph

### Section 1.1: Capability Graph Definition

The Capability Graph is the canonical entity graph storing unique capability IDs. It represents the set of technologies currently existing in civilization.

**Definition**:
```
graph_size() = |{unique capability IDs across all programs}|
```

**Invariants**:
- Each capability ID exists at most once in the graph
- Graph contains entities, not events
- Graph size counts unique IDs, not instances or entries

**Implementation**: `Tiannara.CapabilityRegistry`

---

### Section 1.2: Entity vs Instance Distinction

A **capability entity** is a unique technology identified by its ID (e.g., `:mathematics`).

A **capability instance** is an ownership record where a program possesses a capability.

Multiple programs may own the same capability entity. The graph tracks entities only.

**Example**:
```elixir
Program A owns :mathematics
Program B owns :mathematics
Program C owns :physics

Graph size = 2 (not 3)
Total entries = 3
```

---

## Article II: Canonical Event Ledger

### Section 2.1: Lifecycle Registry Definition

The Lifecycle Registry is the canonical event-sourced evolutionary ledger recording all lifecycle events for all entities in Tiannara.

**Purpose**: Separate events (what happened) from entities (what exists).

**Event Types**:
- `:created` - Novel entity invention
- `:rediscovered` - Re-discovery of existing entity
- `:removed` - Entity removal (with reason)
- `:promoted` - Entity promotion to higher tier
- `:selected` - Entity selection for survival
- `:merged` - Entity merger
- `:rolled_back` - Entity rollback
- `:quarantined` - Entity quarantine
- `:specialized` - Entity specialization
- `:synthesized` - Entity synthesis

**Implementation**: `Tiannara.LifecycleRegistry`

---

### Section 2.2: Event Payload Structure

All lifecycle events must include rich metadata for future analytics:

```elixir
%{
  entity_type: :capability,
  entity_id: "mathematics",
  tick: 12345,
  world_id: "world_1",
  program_id: "prog_42",
  parent_id: "parent_cap",
  discovery_id: "disc_99",
  source: :research,
  generation: 5,
  lineage: ["root", "parent", "current"],
  version: 3,
  metadata: %{...}
}
```

**Rule**: Metadata may expand but must never contract. New fields may be added; existing fields may not be removed.

---

### Section 2.3: Rediscovery Semantics

When a discovery generates an entity ID that already exists in the graph:

**DO**: Emit `:rediscovered` event  
**DO NOT**: Emit `:created` event  
**DO**: Increment rediscovered counter  
**DO NOT**: Increment created counter

**Rationale**: Most scientific work does not invent new concepts. It rediscovers, extends, or applies existing ones. The lifecycle registry must reflect this reality.

---

## Article III: Canonical Invariants

### Section 3.1: Entity Conservation Law

The fundamental invariant governing all entities in Tiannara:

```
UniqueCreated - Removed = ActiveUnique
```

Where:
- `UniqueCreated` = Count of `:created` events
- `Removed` = Count of `:removed` events (including promoted/merged)
- `ActiveUnique` = Current number of unique active entities in graph

**Verification**: Must hold after every selection pass, every tick, and every lifecycle operation.

**Implementation**: `Tiannara.LifecycleRegistry.verify!/2`

---

### Section 3.2: Event Conservation Law

Events must account for all entity instances:

```
Created + Rediscovered = Total Capability Entries
```

Where:
- `Created` = Novel inventions
- `Rediscovered` = Re-discoveries
- `Total Capability Entries` = Sum of all capability ownership records across all programs

**Verification**: Ensures no capability entry exists without corresponding lifecycle event.

---

### Section 3.3: Adoption Invariant

Capability diffusion must be traceable:

```
Σ(program capability maps) = Created + Rediscovered - Removals
```

**Verification**: Ensures adoption tracking matches event history.

---

## Article IV: World Manager

### Section 4.1: World Isolation

Each world operates as an independent simulation instance with its own:
- Capability graph
- Lifecycle events
- Programs
- Civilizations

**Rule**: Worlds may exchange discoveries but maintain separate state.

---

### Section 4.2: Cross-World Discovery Exchange

When a discovery from World A appears in World B:

**DO**: Record as `:rediscovered` in World B  
**DO**: Include `source_world_id` in metadata  
**DO NOT**: Merge world states

---

## Article V: Civilization Kernel

### Section 5.1: Civilization as Aggregate

A civilization is an aggregate of programs operating within a world. It has no independent state beyond its constituent programs.

**Metrics derived from**:
- Program count
- Capability diversity
- Innovation efficiency
- Diffusion coefficient

---

### Section 5.2: Innovation Efficiency

A measurable property of civilization exploration behavior:

```
Innovation Efficiency = Novel Creations / Total Discoveries
                      = Created / (Created + Rediscovered)
```

**Interpretation**:
- High (>50%) = Exploration-dominant civilization
- Low (<10%) = Exploitation-dominant civilization
- Typical mature society: 2-5%

---

## Article VI: Governance & Economics

### Section 6.1: Governance Immutability

Governance rules operate over canonical state. They may not modify:
- Capability graph structure
- Lifecycle event semantics
- Invariant definitions

**Rule**: Governance consumes state; it does not define state.

---

### Section 6.2: Economic Layer

Economic transactions reference canonical entities. Currency, funding, and resource allocation are derived layers atop the entity graph.

**Rule**: Economic state must be reconstructable from event ledger.

---

## Article VII: Telemetry & Ecology

### Section 7.1: Telemetry as Observer

Telemetry observes but never mutates. It provides:
- Performance metrics
- Execution timing
- Resource utilization
- System health

**Rule**: Telemetry has no side effects on canonical state.

---

### Section 7.2: Ecology as Analytics

Ecology consumes lifecycle events to derive:
- Half-life distributions
- Turnover rates
- Age distributions
- Survival curves
- Extinction risks

**Rule**: Ecology is read-only consumer of event ledger. It never emits events.

---

## Article VIII: Architectural Boundaries

### Section 8.1: Layer Responsibilities

| Layer | Responsibility | Mutable? |
|-------|---------------|----------|
| Capability Graph | Canonical entities | Yes (add/remove) |
| Lifecycle Registry | Event ledger | Append-only |
| World Manager | World isolation | Yes (create/destroy worlds) |
| Civilization Kernel | Aggregate metrics | Derived |
| Governance | Rule enforcement | No (read-only) |
| Economics | Resource allocation | Yes (transactions) |
| Telemetry | Performance observation | No (read-only) |
| Ecology | Evolutionary analytics | No (read-only) |

---

### Section 8.2: Dependency Direction

Dependencies flow downward:

```
OED (Phase 13)
  ↓
Cognitive OS (Phase 12)
  ↓
Research Institutions (Phase 12.1)
  ↓
Constitutional Infrastructure (Phase 11.5) ← FROZEN
```

**Rule**: Higher layers may consume lower layers. Lower layers may not depend on higher layers.

---

## Article IX: Amendment Process

### Section 9.1: Constitutional Amendments

Changes to frozen subsystems require:

1. **Justification**: Clear evidence that current semantics are incorrect (not merely inconvenient)
2. **Validation**: Invariant tests must pass before and after change
3. **Migration Plan**: All dependent systems must be updated
4. **Documentation**: Constitution must be updated with rationale
5. **Approval**: Explicit user approval required

---

### Section 9.2: Bug Fixes vs Semantic Changes

**Bug Fix**: Correcting implementation that violates documented semantics  
**Allowed**: Yes, with regression tests

**Semantic Change**: Modifying documented behavior or invariants  
**Allowed**: Only through amendment process (Section 9.1)

---

## Article X: Future Phases

### Section 10.1: Phase 12 Integration Rule

All Phase 12 subsystems must integrate through canonical APIs:

- Research Program Engine → Uses Capability Graph + Lifecycle Registry
- Discovery Exchange → Emits lifecycle events
- Human Collaborators → Operate on canonical state
- JTMS++ → References lifecycle events for justification
- VSA Memory → Indexes canonical entities
- Do-Calculus → Queries canonical state
- Neuro-Symbolic Routing → Routes through canonical APIs
- Cognitive Immune System → Monitors invariant violations
- Research OS Beta → Consolidates canonical substrate
- Distributed Validation → Verifies cross-world invariants
- Epistemic Coarse Graining → Compresses canonical structures
- Topological Knowledge → Analyzes canonical graph topology
- Active Epistemic Foraging → Prioritizes based on canonical metrics

**Rule**: No Phase 12 subsystem may maintain independent truth models.

---

### Section 10.2: Principle 15 — Constitutional Separation of Knowledge and Governance

Scientific reasoning determines **what is currently believed** based on evidence.

Governance determines **whether constitutional process was followed** during scientific reasoning.

Neither determines the other.

**Governance may**:
- Suspend publication pending review
- Quarantine institutions violating process
- Require additional validation steps
- Reject processes that violate constitutional rules

**Governance never**:
- Changes scientific conclusions
- Determines which hypotheses are true
- Overrides evidence-based assessments
- Participates in scientific reasoning

**Scientific evidence never**:
- Changes constitutional rules
- Modifies governance procedures
- Bypasses required review processes

This principle ensures that **truth emerges through reproducible evidence**, while **process integrity is maintained by governance oversight**. The two responsibilities remain constitutionally separate.

**Implementation**: In distributed validation, `DistributedValidationResult` contains only epistemic assessments (supporting/contradicting evidence, agreement levels, consensus status). Governance review is indicated by a boolean flag (`governance_review_required`), while actual governance decisions are recorded separately in the Lifecycle Registry as supervisory events.

---

### Section 10.3: Phase 13 (OED) Prerequisites

OED requires stable foundations:

✅ Capability Graph (Article I)  
✅ Lifecycle Registry (Article II)  
✅ Invariants (Article III)  
✅ World Manager (Article IV)  
✅ Civilization Kernel (Article V)  
✅ Governance (Article VI)  
✅ Telemetry & Ecology (Article VII)

**Rule**: OED evolves the architecture itself. All lower layers must be frozen first.

---

## Appendix A: Validated Metrics (Run 18)

At tick 20,000:

| Metric | Value |
|--------|-------|
| Programs | 2,000 |
| Total Capability Entries | 1,871 |
| Unique Capability IDs | 38 |
| Lifecycle Active State | 38 |
| Novel Creations | 38 |
| Rediscoveries | 1,833 |
| Removals | 0 |
| Innovation Efficiency | 2.0% |

**Invariant Status**: ✅ HOLDS (38 - 0 = 38)

---

## Appendix B: Glossary

**Entity**: Unique item identified by ID (e.g., capability, theory, ontology)  
**Instance**: Ownership record linking entity to program/world  
**Event**: Historical record of what happened to an entity  
**Creation**: First appearance of novel entity  
**Rediscovery**: Re-appearance of existing entity  
**Removal**: Entity deletion from graph  
**Promotion**: Entity advancement to higher tier  
**Graph Size**: Count of unique active entities  
**Total Entries**: Sum of all entity instances across all programs  
**Innovation Efficiency**: Ratio of creations to total discoveries  

---

**End of Constitution**
