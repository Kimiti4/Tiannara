# Tiannara Institutional Behavioral Specification v1.0

## Constitutional Amendment 12.1C — Institutional Behavior Freeze

**Status**: FROZEN (Immutable)  
**Effective Date**: 2026-06-26  
**Validated By**: Capability 12.1.2B (Adaptive Institutional Scientific Episodes)  
**Amendment Process**: Requires Phase 13 Constitutional Convention  

---

## Preamble

This specification defines the **immutable behavioral contract** governing all Research Institutions within the Tiannara Cognitive Operating System.

It does not describe implementation details.

It describes **what every Institution guarantees**, forever.

These guarantees are empirically validated by Capability 12.1.2B and cannot be violated without constitutional amendment.

The purpose is to establish a stable foundation for:
- Multi-institution collaboration (Phase 12.2+)
- Human-AI scientific partnership (Phase 12.3)
- Advanced reasoning substrates (Phase 12.4-12.8)
- Distributed validation (Phase 12.9-12.13)

---

## Part I — Institutional Purpose

### Definition

A **Research Institution** is the primary cognitive actor of the Tiannara Operating System.

It exists to perform autonomous scientific investigation while maintaining constitutional compliance.

### Core Responsibilities

Every Research Institution must:

1. **Investigate scientific questions** autonomously
2. **Generate hypotheses** from research goals
3. **Design experiments** to test hypotheses
4. **Collect evidence** through experiment execution
5. **Evaluate evidence** quality and consistency
6. **Revise beliefs** based on evidence evaluation
7. **Preserve institutional knowledge** in Knowledge Graph
8. **Publish validated discoveries** when confidence exceeds threshold
9. **Reject invalid discoveries** when evidence contradicts hypothesis
10. **Remain constitutionally compliant** throughout all operations

### Non-Goals

An Institution is NOT:
- A collection of modules or subsystems
- An AI framework or algorithm library
- A data processing pipeline
- A workflow engine

An Institution IS:
- A persistent cognitive entity
- A constitutional actor with agency
- A scientific investigator with memory
- A collaborative partner in distributed cognition

---

## Part II — Canonical Scientific Episode

### Definition

Every scientific investigation is exactly one:

```elixir
ResearchCycleResult
```

This is the **only** canonical representation of institutional scientific work.

### Properties

Every `ResearchCycleResult` is:

1. **Immutable**: Once created, never modified
2. **Complete**: Contains full audit trail of episode
3. **Traceable**: Every decision reconstructable from events
4. **Historical**: Permanent record in institutional memory
5. **Consumable**: Direct input to future capabilities

### Uniqueness Guarantee

No other transaction object may represent a scientific episode.

Future capabilities must consume `ResearchCycleResult`, not replace it.

---

## Part III — Terminal Outcomes

### Finite Outcome Set

Every `ResearchCycleResult` must terminate in **exactly one** outcome:

| Outcome | Meaning | When |
|---------|---------|------|
| `SUCCESS` | Hypothesis supported by evidence | Confidence ≥ 0.7, evidence consistent |
| `NEGATIVE_RESULT` | Hypothesis falsified by evidence | Evidence contradicts hypothesis |
| `INCONCLUSIVE` | Insufficient consensus for conclusion | Evidence contradictory or ambiguous |
| `REJECTED` | Governance prevented execution | Violates policy or ethics |
| `DEFERRED` | Economic constraints prevented execution | Insufficient budget |

### Immutability

No additional terminal states may exist without constitutional amendment.

Every future capability must preserve this finite outcome set.

### Outcome Determinism

Outcomes are determined by:
- Evidence quality and consistency
- Governance decisions
- Economic constraints
- Belief revision calculations

NOT by:
- Hardcoded workflow paths
- Module-specific logic
- Implementation details

---

## Part IV — Canonical Episode Flow

### Mandatory Sequence

Every institutional episode follows this constitutional order:

```
Research Goal
    ↓
Hypothesis Generation
    ↓
Governance Review
    ↓
Experiment Design
    ↓
Experiment Execution
    ↓
Evidence Collection
    ↓
Evidence Evaluation
    ↓
Belief Revision
    ↓
Knowledge Graph Update
    ↓
Publication Decision
    ↓
Ledger Update
    ↓
Memory Consolidation
    ↓
ResearchCycleResult (Terminal)
```

### Behavioral Guarantees

1. **Order Preservation**: Phases execute in specified sequence
2. **Completeness**: All phases execute (except early termination by governance/budget)
3. **Atomicity**: Episode either completes fully or terminates with clear status
4. **Traceability**: Each phase emits semantic events and lifecycle records

### Early Termination

Episodes may terminate early at:
- **Governance Review**: If rejected → Status: `REJECTED`
- **Budget Check**: If insufficient funds → Status: `DEFERRED`

Early termination still produces valid `ResearchCycleResult`.

---

## Part V — Constitutional Services

### Mandatory Composition

Every `ResearchCycleResult` composes these existing constitutional services:

1. **InstitutionKernel**: Owns all state mutation
2. **Governance Engine**: Validates before mutation
3. **Lifecycle Registry**: Records entity lifecycles
4. **Semantic Event Bus**: Emits institutional events
5. **Knowledge Graph**: Stores hypotheses, evidence, discoveries
6. **Economic Ledger**: Accounts research costs
7. **Memory Pipeline**: Compresses operational → civilizational memory
8. **Runtime Atlas**: Registers active institutions
9. **Validation Framework**: Checks constitutional invariants
10. **Constitution Dashboard**: Monitors institutional health

### Bypass Prohibition

No capability may bypass these services.

All mutations must flow through Kernel → Governance → Services.

### Service Stability

These services are frozen infrastructure (bug fixes only, no feature additions).

---

## Part VI — Immutable Behavioral Guarantees

Every Research Institution guarantees:

### Guarantee 1: Single Result Per Request
Every research request produces exactly one `ResearchCycleResult`.

### Guarantee 2: Kernel Ownership
Every state mutation passes through `InstitutionKernel`.

### Guarantee 3: Governance Approval
Every mutation is approved by Governance before execution.

### Guarantee 4: Lifecycle Recording
Every entity creation/removal is recorded in Lifecycle Registry.

### Guarantee 5: Semantic Event Emission
Every mutation emits corresponding semantic event.

### Guarantee 6: Knowledge Traceability
Every knowledge graph mutation is traceable to originating episode.

### Guarantee 7: Ledger Conservation
Every ledger mutation maintains balance conservation law.

### Guarantee 8: Memory Hierarchy Preservation
Every memory mutation preserves compression hierarchy (operational → research → institutional → civilizational).

### Guarantee 9: Explainability
Every decision is explainable via traceability chain.

### Guarantee 10: Historical Immutability
Every completed episode is historically immutable (never edited, only superseded).

---

## Part VII — Explanatory Traceability

### Reconstruction Chain

Every `ResearchCycleResult` must reconstruct:

```
Trigger Event
    ↓
Research Goal
    ↓
Hypothesis Generated
    ↓
Governance Decision
    ↓
Experiment Designed
    ↓
Evidence Collected
    ↓
Belief Revised
    ↓
Knowledge Delta
    ↓
Ledger Delta
    ↓
Memory Delta
    ↓
Publication Decision
    ↓
Lifecycle Events
    ↓
Semantic Events
    ↓
ResearchCycleResult (Final)
```

### Completeness Requirement

Nothing in institutional cognition may become opaque.

Explainability is constitutional, not optional.

### Audit Trail

The following must be present in every `ResearchCycleResult`:
- `lifecycle_events`: All entity lifecycle records
- `semantic_events`: All emitted institutional events
- `governance_decisions`: All approval/rejection decisions
- `knowledge_delta`: Nodes/edges added to Knowledge Graph
- `ledger_delta`: Economic transactions
- `memory_delta`: Memory compression results
- `constitutional_validation`: Invariant check results

---

## Part VIII — ResearchCycleResult Constitutional Status

### Frozen Object

`ResearchCycleResult` is now a **constitutional object**.

It has the same immutability status as:
- Event Model
- Lifecycle Registry
- Knowledge Graph schema
- Institution Kernel interface

### Consumption Rule

Future capabilities **consume** `ResearchCycleResult`.

They do **not**:
- Replace it
- Redefine it
- Duplicate it
- Create parallel transaction objects

### Extension Prohibition

No capability may add fields to `ResearchCycleResult` without constitutional amendment.

Capabilities extend behavior by composing the result, not modifying its structure.

---

## Part IX — Consumption Contracts

### JTMS++ (Phase 12.4)

**Consumes:**
- `belief_change`: Prior/posterior confidence deltas
- `knowledge_delta`: Hypothesis and evidence nodes
- `evidence`: Raw observations and confidence scores

**Purpose:** Advanced belief revision with truth maintenance

**Constraint:** Must not access kernel state directly if information exists in `ResearchCycleResult`

---

### VSA Memory (Phase 12.5)

**Consumes:**
- Entire `ResearchCycleResult`: For semantic embedding
- `memory_delta`: Compression metadata

**Purpose:** Semantic retrieval of similar research episodes

**Constraint:** Embeds complete episodes, not partial state

---

### Discovery Exchange (Phase 12.2)

**Transfers:**
- `ResearchCycleResult`: Between institutions

**Purpose:** Inter-institution knowledge sharing

**Constraint:** Preserves full traceability during transfer

---

### Human Collaboration (Phase 12.3)

**Reviews:**
- `ResearchCycleResult`: Human-readable summary
- `publication`: Decision rationale
- `evaluation`: Evidence quality assessment

**Purpose:** Human oversight of institutional science

**Constraint:** Presents canonical artifact, not internal logs

---

### Distributed Validation (Phase 12.10)

**Validates:**
- `ResearchCycleResult`: Cross-institution consensus
- `constitutional_validation`: Invariant preservation

**Purpose:** Consensus over scientific claims

**Constraint:** Validates complete episodes, not partial state

---

### Do-Calculus (Phase 12.6)

**Extends:**
- `experiment`: Causal intervention design
- `evidence`: Counterfactual analysis

**Purpose:** Causal reasoning over experimental data

**Constraint:** Builds on existing experiment structure

---

### Topological Knowledge (Phase 12.12)

**Reasons Over:**
- Collections of `ResearchCycleResult` objects
- Networks of hypotheses, evidence, institutions

**Purpose:** Higher-order scientific abstraction

**Constraint:** Operates on episode networks, not raw state

---

### Cognitive Immune System (Phase 12.8)

**Monitors:**
- `semantic_events`: Anomaly detection
- `lifecycle_events`: Behavioral patterns
- `traceability_chain`: Integrity verification
- `ResearchCycleResult`: Epistemic corruption detection

**Purpose:** Defend against epistemic attacks

**Constraint:** Detects anomalies in canonical artifacts

---

## Part X — Behavioral Invariants

### Institutional Invariants

The following invariants must hold for all time:

1. **Episode Count Invariant**: `ResearchCycleResult` count equals completed episodes
2. **Outcome Uniqueness**: Every completed episode has exactly one terminal outcome
3. **Traceability Completeness**: Every terminal outcome has one complete traceability chain
4. **Mutation Reconstructability**: Every traceability chain reconstructs every mutation
5. **Publication Reference**: Every publication references exactly one `ResearchCycleResult`
6. **Discovery Origin**: Every discovery originates from exactly one `ResearchCycleResult`
7. **Knowledge Graph Reference**: Every knowledge graph addition references one `ResearchCycleResult`
8. **Ledger Entry Reference**: Every ledger entry references one `ResearchCycleResult`
9. **Memory Consolidation Reference**: Every memory consolidation references one `ResearchCycleResult`

### Identification Principle

`ResearchCycleResult` becomes the **canonical identifier** linking institutional history.

All institutional state references episodes, not arbitrary timestamps or IDs.

---

## Part XI — Behavioral Validation

### Validated Test Suite

Capability 12.1.2B validated five adaptive episodes that constitute the permanent behavioral test suite:

### Episode 1: Successful Discovery
**Goal**: "Does increasing mutation rate improve capability diversity?"  
**Evidence**: Positive correlation confirmed (confidence 0.6, 0.75)  
**Outcome**: `SUCCESS` (confidence increased 0.5 → 0.5875)  
**Proves**: Institution can validate hypotheses and increase confidence

### Episode 2: Negative Result
**Goal**: "Does decreasing mutation rate improve capability diversity?"  
**Evidence**: Contradicted hypothesis predictions (confidence 0.75, 0.8)  
**Outcome**: `NEGATIVE_RESULT` (confidence decreased 0.5 → 0.3075)  
**Proves**: Institution can falsify hypotheses and decrease confidence

### Episode 3: Contradictory Evidence
**Goal**: "Does mutation rate affect innovation speed?"  
**Evidence**: Mixed results (some positive, some negative)  
**Outcome**: `INCONCLUSIVE` (publication deferred)  
**Proves**: Institution can preserve uncertainty and avoid premature conclusions

### Episode 4: Governance Rejection
**Goal**: "Test research that violates ethical guidelines"  
**Behavior**: Governance rejected before execution  
**Outcome**: `REJECTED` (no experiment, no mutation)  
**Proves**: Institution respects governance boundaries and prevents unconstitutional research

### Episode 5: Budget Exhaustion
**Goal**: "Attempt expensive research requiring more budget than available"  
**Behavior**: Institution refused execution (needed 999,999, had 970)  
**Outcome**: `DEFERRED` (research deferred, attempted allocation recorded)  
**Proves**: Institution respects economic constraints and preserves traceability even when deferring

### Adaptive Behavior Demonstrated

These episodes prove the institution exhibits:
- **Evidence-based reasoning**: Different outcomes from different evidence
- **Confidence adaptation**: Bayesian belief revision
- **Uncertainty preservation**: Defers publication when evidence contradictory
- **Governance responsiveness**: Refuses unconstitutional research
- **Economic constraint respect**: Defers when budget insufficient
- **Complete traceability**: All decisions reconstructable

---

## Part XII — Freeze Declaration

### Declaration

As of 2026-06-26, the Institutional Behavioral Specification is **FROZEN**.

This means:

1. **No architectural redesign** of institutional cognition
2. **No new persistent state** outside existing constitutional model
3. **No alternative transaction objects** replacing `ResearchCycleResult`
4. **No bypassing** of constitutional services
5. **No modification** of terminal outcome set
6. **No violation** of behavioral guarantees

### Amendment Process

Changes to this specification require:
1. Phase 13 Constitutional Convention
2. Empirical validation of proposed changes
3. Unanimous approval by all active institutions
4. Migration plan for existing `ResearchCycleResult` artifacts

### Stability Guarantee

This specification will remain stable through:
- Phase 12.2: Inter-Institution Knowledge Exchange
- Phase 12.3: Human Collaboration
- Phase 12.4: JTMS++ Belief Revision
- Phase 12.5: VSA Memory Retrieval
- Phase 12.6: Do-Calculus Causal Reasoning
- Phase 12.7: Neuro-Symbolic Routing
- Phase 12.8: Cognitive Immune System
- Phase 12.9: Research OS Beta
- Phase 12.10: Distributed Validation
- Phase 12.11: Epistemic Coarse Graining
- Phase 12.12: Topological Knowledge
- Phase 12.13: Active Epistemic Foraging

Only Phase 13 (Institutional Self-Improvement) may propose amendments.

---

## Appendix A — ResearchCycleResult Schema

```elixir
%ResearchCycleResult{
  # Research Inputs
  goal: String.t(),
  budget_allocated: float(),
  
  # Research Process
  hypothesis: %{id: String.t(), statement: String.t(), confidence: float()},
  experiment: %{id: String.t(), design: String.t(), variables: map()},
  evidence: [%{id: String.t(), observation: String.t(), confidence: float()}],
  evaluation: %{average_confidence: float(), recommendation: atom()},
  belief_change: %{prior: float(), posterior: float(), delta: float()},
  publication: %{decision: atom(), reason: String.t(), confidence: float()},
  
  # Constitutional Deltas
  knowledge_delta: %{nodes_added: list(), edges_added: list()},
  ledger_delta: %{expense: float(), previous_balance: float(), new_balance: float()},
  memory_delta: %{compression_ratio: float(), civilizational_added: integer()},
  
  # Event Audit Trail
  lifecycle_events: [%{entity_type: atom(), event: atom(), entity_id: String.t()}],
  semantic_events: [%{event_type: atom(), metadata: map(), timestamp: integer()}],
  governance_decisions: [%{decision: atom(), approved: boolean(), reason: String.t()}],
  
  # Execution Metadata
  execution_time_ms: integer(),
  tick_range: {integer(), integer()},
  constitutional_validation: %{status: atom(), invariants_checked: map()},
  
  # Status
  status: :success | :negative_result | :inconclusive | :rejected | :deferred,
  failure_reason: String.t() | nil
}
```

---

## Appendix B — Validation Checklist

Before declaring any capability complete, verify:

- [ ] Produces exactly one `ResearchCycleResult` per request
- [ ] All mutations pass through `InstitutionKernel`
- [ ] Governance approves before mutation
- [ ] Lifecycle events recorded for all entities
- [ ] Semantic events emitted for all mutations
- [ ] Knowledge graph updates reference episode ID
- [ ] Ledger balances after mutation
- [ ] Memory hierarchy preserved
- [ ] Complete traceability chain present
- [ ] Episode immutable after completion
- [ ] Terminal outcome is one of five allowed states
- [ ] Constitutional invariants all pass

---

## Appendix C — Future Capability Integration Guide

When implementing Phase 12.2+ capabilities:

1. **Identify which fields** of `ResearchCycleResult` your capability needs
2. **Consume the canonical artifact** directly
3. **Do not access kernel state** if information exists in result
4. **Produce new `ResearchCycleResult`** if creating new episodes
5. **Reference existing results** when building on prior work
6. **Preserve traceability** by linking to parent episode IDs
7. **Respect outcome semantics** (don't invent new terminal states)

Example:

```elixir
# CORRECT: Consume ResearchCycleResult
def process_discovery(research_result) do
  belief = research_result.belief_change
  evidence = research_result.evidence
  # ... process using canonical fields
end

# INCORRECT: Access kernel state directly
def process_discovery(kernel_pid, episode_id) do
  state = GenServer.call(kernel_pid, :get_state)
  # ... bypass canonical artifact
end
```

---

**Document Status**: FROZEN  
**Last Updated**: 2026-06-26  
**Next Review**: Phase 13 Constitutional Convention  
**Maintained By**: Tiannara Constitutional Council  
