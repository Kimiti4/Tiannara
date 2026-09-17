# Tiannara Constitutional Specification v1.0

**Status**: CONSTITUTIONALLY FROZEN  
**Date**: June 13, 2026  
**Authority**: Core Systems Architecture  
**Amendment Process**: Formal constitutional amendment required (see Part XII)

---

## Preamble

This document defines the immutable constitutional principles governing the Tiannara Cognitive Operating System. It is not a roadmap. It is not a design document. It is the **constitutional specification** against which all implementation must be validated.

Every subsystem, every feature, every extension must answer one question:

> **"Does this conform to the Constitution?"**

Not "Is this a good new idea?"

This distinction prevents architectural drift over years of development.

---

# Part I: Core Principles

## Principle 1: Everything is an Institution

Programs are temporary. Campaigns evolve. Institutions persist.

The institution is the fundamental unit of cognition in Tiannara. All cognitive activity occurs within institutional boundaries.

## Principle 2: Everything Emits Events

Nothing mutates state silently. Every meaningful action produces semantic events that flow through the Semantic Event Bus.

Events are the only legitimate mechanism for cross-subsystem communication.

## Principle 3: Everything Has Lifecycle

Capabilities, discoveries, hypotheses, claims, theories, campaigns, programs, institutions, ontologies—all use the same Lifecycle Registry with canonical event semantics.

Lifecycle is universal. There are no exceptions.

## Principle 4: Everything Exists Inside the Knowledge Graph

There is no separate claim graph. There is one graph with different node types and edge types. One substrate serves all reasoning systems.

JTMS++ reasons over claims. Topological Knowledge reasons over topology. CIS monitors for contradictions. All operate on the same graph.

## Principle 5: InstitutionKernel Owns Every State Mutation

No subsystem mutates shared state directly. The Kernel remains the single constitutional authority for all state changes.

Direct struct manipulation is forbidden. All mutations go through kernel APIs.

## Principle 6: Governance Validates Actions Before Mutation

Validation precedes execution. Never afterwards. Governance workflows must approve actions before they mutate institutional state.

Post-hoc validation is insufficient. Prevention is constitutional.

## Principle 7: Economics Represents Scarce Cognition

Attention, time, compute, memory, validation, experiments, publication—all have economic cost tracked through the Economic Ledger.

Resources are finite. Economics enforces prioritization.

## Principle 8: Memory Compresses Upward

Operational → Research → Institutional → Civilizational

Each layer summarizes the previous. Information is compressed, not merely stored. This is Epistemic Coarse Graining in miniature.

## Principle 9: The Runtime Atlas is the OS Registry

Every institution automatically registers itself. Everything is discoverable. Nothing is manually wired.

The atlas enables autonomous discovery and collaboration without central coordination.

## Principle 10: CIS Remains the Immune System

Every future subsystem exposes hooks. No subsystem bypasses CIS monitoring. Security is not optional—it is constitutional.

CIS integration is pre-plugged. Implementation cannot skip security.

## Principle 11: Explanatory Traceability

Every institutional decision must be reconstructable from:
- The triggering events
- The governing policies
- The evidence used
- The lifecycle history
- The knowledge graph state

Explainability is not a feature—it is a constitutional requirement. This principle naturally integrates with Event Bus, Lifecycle Registry, Governance layer, Knowledge Graph, and Memory pipeline without introducing new subsystems.

No decision occurs in isolation. Every action leaves an auditable trace through the constitutional infrastructure.

---

# Part II: Kernel

## InstitutionKernel Definition

The InstitutionKernel is a GenServer process that owns ALL institutional state mutation. It provides the following services:

### Core Services

1. **Runtime Scheduler** - Processes ticks, manages program execution
2. **Lifecycle Manager** - Tracks entity lifecycles, emits canonical events
3. **Governance Validator** - Validates actions before state mutation
4. **Economics Manager** - Manages ledger entries, enforces conservation
5. **Memory Manager** - Handles four-tier memory compression pipeline
6. **Event Router** - Routes semantic events to subscribers
7. **State Synchronizer** - Ensures consistency across subsystems
8. **Telemetry Collector** - Gathers metrics for observability
9. **Security Hooks** - Pre-plugged interfaces for CIS integration

### Kernel API Contract

```elixir
@spec start_link(institution_id :: atom(), init_state :: map()) :: {:ok, pid()}
@spec tick(kernel_pid :: pid(), current_tick :: integer()) :: :ok
@spec spawn_campaign(kernel_pid :: pid(), name :: String.t(), params :: map()) :: {:ok, atom()}
@spec spawn_program(kernel_pid :: pid(), campaign_id :: atom(), params :: map()) :: {:ok, atom()}
@spec emit_semantic_event(kernel_pid :: pid(), event_type :: atom(), metadata :: map()) :: :ok
@spec validate_compliance(kernel_pid :: pid()) :: {:compliant | :violation, [String.t()]}
@spec ledger_balance(kernel_pid :: pid()) :: map()
@spec register_security_hook(kernel_pid :: pid(), hook_type :: atom(), callback :: function()) :: :ok
```

### Invariant: Kernel State Ownership

**All institutional state mutations must go through InstitutionKernel.** Direct struct manipulation is constitutionally forbidden.

Verification: Codebase scan reveals zero direct state mutations outside kernel APIs.

---

# Part III: Event Model

## Semantic Event Bus

The Semantic Event Bus sits between semantic events and lifecycle registry, enabling multi-subscriber architecture.

### Event Flow

```
Semantic Event → Institution Event Bus → Multiple Subscribers
                                      → Lifecycle Registry
                                      → Institutional Memory
                                      → Knowledge Graph
                                      → Discovery Portfolio
                                      → Economic Ledger
                                      → Governance
                                      → CIS
                                      → Telemetry
```

### Canonical Event Types

- `InstitutionCreated` / `InstitutionDissolved`
- `CampaignSpawned` / `CampaignArchived`
- `ProgramStarted` / `ProgramCompleted` / `ProgramSuspended` / `ProgramMerged` / `ProgramForked` / `ProgramArchived`
- `DiscoveryCandidate` / `DiscoveryValidated` / `DiscoveryReplicated` / `DiscoveryPublished` / `DiscoveryAdopted` / `DiscoveryStandardized` / `DiscoveryObsolete` / `DiscoveryRetracted`
- `HypothesisProposed` / `HypothesisConfirmed` / `HypothesisRefuted`
- `ExperimentExecuted` / `EvidenceCollected`
- `LedgerEntry` / `BudgetAllocated` / `CommitmentMade`
- `GovernanceApproved` / `GovernanceRejected`
- `ConstitutionAmended`
- `AnomalyDetected` / `ContradictionFound`

### Event Semantics

Every event must include:
- `event_id`: Unique identifier
- `timestamp`: Tick number
- `source`: Entity that triggered event
- `entity_type`: Type of affected entity
- `entity_id`: ID of affected entity
- `action`: Action taken
- `metadata`: Additional context

### Invariant: Event Completeness

**Every institutional action emits a semantic event.** Missing events indicate architectural violation.

---

# Part IV: Lifecycle

## Lifecycle Registry

The Lifecycle Registry maintains canonical event logs for all entities. It uses event sourcing with immutable event history.

### Entity Types with Lifecycle

- Capabilities
- Discoveries
- Hypotheses
- Claims
- Theories
- Campaigns
- Programs
- Institutions
- Ontologies

### Canonical Lifecycle States

Each entity type has specific states, but all follow the pattern:

```
created → active → [transitions] → terminal_state
```

### Lifecycle Events

- `created`: Entity instantiated
- `mutated`: Entity modified
- `validated`: Entity passed validation
- `invalidated`: Entity failed validation
- `archived`: Entity preserved
- `removed`: Entity deleted

### Rediscovery Handling

When an entity is "rediscovered" (same concept created independently), it receives a NEW lifecycle entry with `rediscovered` action, NOT a mutation of the original.

True creations and rediscoveries are separated in the event log.

### Invariant: Lifecycle Consistency

**All entities in state must have corresponding lifecycle entries.** Orphaned entities indicate data corruption.

---

# Part V: Knowledge Graph

## Knowledge Graph Definition

The Knowledge Graph is a directed acyclic graph containing multiple node types and edge types. It replaces the former "Claim Graph."

### Node Types

- `:claim` - Assertions requiring justification (JTMS++ focus)
- `:evidence` - Empirical or logical support
- `:discovery` - Validated findings
- `:hypothesis` - Proposed explanations
- `:policy` - Governance rules
- `:experiment` - Executed tests
- `:researcher` - Human or AI agents
- `:institution` - Research institutions
- `:capability` - System capabilities
- `:ontology` - Conceptual frameworks

### Edge Types

- `:justifies` - Evidence supports claim
- `:contradicts` - Evidence refutes claim
- `:depends_on` - Claim depends on other claim
- `:derived_from` - Discovery derived from hypothesis
- `:tested_by` - Hypothesis tested by experiment
- `:authored_by` - Entity authored by researcher
- `:owned_by` - Entity owned by institution
- `:implements` - Capability implements ontology

### Graph Properties

- **Acyclicity**: No circular dependencies in justification chains
- **Justification Chains**: Each claim has traceable justification path
- **Multi-Reasoning Support**: JTMS++, Topological Knowledge, CIS all operate on same graph

### Knowledge Graph API

```elixir
@spec add_node(institution_id :: atom(), node_id :: atom(), node_type :: atom(), metadata :: map()) :: :ok
@spec add_edge(institution_id :: atom(), from_id :: atom(), to_id :: atom(), edge_type :: atom()) :: :ok
@spec query_by_type(institution_id :: atom(), node_type :: atom()) :: [map()]
@spec get_justification_chain(institution_id :: atom(), claim_id :: atom()) :: [atom()]
@spec detect_cycles(institution_id :: atom()) :: boolean()
```

### Invariant: Graph Acyclicity

**No circular dependencies in justification chains.** Cycle detection runs after every graph mutation.

---

# Part VI: Institution

## ResearchInstitution Definition

ResearchInstitution is a permanent entity with constitution, kernel, and full cognitive stack.

### Institution Structure

```elixir
defmodule TiannaraOS.ResearchInstitution do
  defstruct [
    # Identity
    :id,
    :world_id,
    :founded_tick,
    :status,  # :active | :dormant | :dissolved
    
    # Constitution
    constitution: %{},
    
    # Kernel
    kernel_pid: nil,
    
    # Identity & Reputation
    identity: %{
      mission: String.t(),
      research_philosophy: atom(),
      core_competencies: [atom()],
      reputation: float(),
      trust_score: float(),
      scientific_domain_vector: %{}
    },
    
    # Ownership
    campaigns: %{},
    active_program_count: 0,
    
    # Four-Tier Memory
    operational_memory: [],
    research_memory: %{},
    institutional_memory: %{},
    civilizational_memory: %{},
    
    # Economic Ledger
    economic_ledger: %{},
    
    # Governance
    governance_state: %{},
    
    # Knowledge Graph
    knowledge_graph: %{},
    
    # Discovery Portfolio
    discovery_portfolio: %{},
    
    # World Model
    world_model: %{},
    
    # Lifecycle Integration
    semantic_event_log: [],
    last_lifecycle_sync_tick: nil,
    
    # Telemetry
    telemetry: %{}
  ]
end
```

## Institution Constitution

Every institution owns a constitution defining its scientific culture.

### Constitution Structure

```elixir
constitution: %{
  mission: String.t(),
  governance_rules: %{
    decision_making: :democratic | :hierarchical | :meritocratic,
    voting_threshold: float(),
    quorum_requirements: integer()
  },
  ethics_framework: %{
    prohibited_research: [atom()],
    required_approvals: [atom()],
    ethical_principles: [String.t()]
  },
  economic_rules: %{
    profit_distribution: map(),
    funding_priorities: map(),
    budget_allocation_strategy: atom()
  },
  publication_rules: %{
    open_access: boolean(),
    peer_review_required: boolean(),
    citation_standards: atom()
  },
  research_rules: %{
    validation_standards: atom(),
    replication_requirements: integer(),
    evidence_thresholds: map()
  },
  amendment_process: %{
    proposal_threshold: float(),
    ratification_threshold: float(),
    cooling_off_period_ticks: integer()
  }
}
```

### Constitution Amendment Process

1. Proposal submitted (requires proposal_threshold support)
2. Voting period begins
3. Ratification if threshold met
4. Cooling-off period before activation
5. Amendment recorded in lifecycle

### Invariant: Constitution Immutability During Amendment

**Constitution cannot change except through formal amendment process.** Direct constitution mutation is forbidden.

## ResearchCampaign

Campaigns are long-lived scientific fields with evolutionary properties.

### Campaign Genome

```elixir
campaign_genome: %{
  exploration_rate: float(),        # novel vs established research
  validation_priority: float(),     # replicate vs discover
  cross_domain_synthesis: float(),  # interdisciplinary level
  anomaly_sensitivity: float(),     # focus on outliers
  risk_tolerance: float()           # bold vs conservative
}
```

### Campaign Fitness

```elixir
campaign_fitness: %{
  discovery_yield: float(),
  hypothesis_success_rate: float(),
  resource_efficiency: float(),
  citation_impact: float()
}
```

### Three Temporal Scales

- **Programs** evolve quickly (ticks)
- **Campaigns** evolve slowly (thousands of ticks)
- **Institutions** evolve very slowly (tens of thousands of ticks)

## ResearchProgram

Programs are transient processes owned by campaigns.

### Program States

- `:completed` - Successfully finished
- `:suspended` - Temporarily halted
- `:merged` - Combined with another program
- `:forked` - Split into multiple programs
- `:archived` - Preserved for historical reference

## Institution World Model

Institutions maintain separate world models from civilization.

```elixir
world_model: %{
  beliefs: %{},
  confidence_levels: %{},
  disagreements: [],
  evidence_base: []
}
```

Disagreement drives scientific progress.

## Runtime Atlas Registration

Every institution auto-publishes to Runtime Atlas on creation.

```elixir
@spec register_in_runtime_atlas(institution_id :: atom(), metadata :: map()) :: :ok
```

Makes institutions queryable by domain, reputation, trust score.

---

# Part VII: Governance

## Governance Framework

Governance validates actions before state mutation through workflow-based approval processes.

### Approval Workflows

1. **Ethics Approval** - Validates research ethics compliance
2. **Safety Approval** - Validates safety constraints
3. **Economic Approval** - Validates budget availability
4. **Publication Approval** - Validates publication readiness

### Governance State

```elixir
governance_state: %{
  policies: [map()],
  treaties: [map()],
  compliance_status: :compliant | :violation,
  pending_approvals: [map()]
}
```

### Compliance Validation

```elixir
@spec validate_compliance(institution_id :: atom()) :: {:compliant | :violation, [String.t()]}
```

Returns violation details if non-compliant.

### Invariant: Pre-Mutation Validation

**All state mutations require prior governance approval.** Post-hoc validation is insufficient.

---

# Part VIII: Economics

## Economic Ledger

The Economic Ledger tracks resources using double-entry bookkeeping with conservation invariant.

### Ledger Entry Types

- `:income` - Funding received
- `:expense` - Resources spent
- `:allocation` - Budget category assignment
- `:commitment` - Reserved funds
- `:reserve` - Emergency funds

### Assets

```elixir
assets: %{
  intellectual_capital: float(),
  knowledge_assets: float(),
  reputation_value: float()
}
```

### Liabilities

```elixir
liabilities: %{
  outstanding_commitments: float(),
  treaty_obligations: float()
}
```

### Opportunity Costs

```elixir
opportunity_costs: %{
  foregone_research_paths: [map()]
}
```

### Conservation Invariant

```
Total Income + Asset Appreciation - Total Expenses - Liability Increase = Current Balance + Commitments + Reserves
```

### Verification

```elixir
@spec verify_conservation(institution_id :: atom()) :: boolean()
```

Runs after every ledger mutation.

### Invariant: Ledger Conservation

**Ledger must always balance.** Violation indicates economic corruption.

---

# Part IX: Memory

## Four-Tier Memory Compression Pipeline

Memory compresses upward through four tiers, each summarizing the previous.

### Tier 1: Operational Memory

- Current tick events
- Auto-pruned after processing
- Volatile, high-frequency

### Tier 2: Research Memory

- Structured records: hypotheses, experiments, evidence
- Persistent across ticks
- Queryable by research programs

### Tier 3: Institutional Memory

- Patterns extracted from research memory
- Heuristics developed over time
- Meta-knowledge about research effectiveness

### Tier 4: Civilizational Memory

- High-level abstractions
- Interface to Phase 12.11 coarse graining
- Read-only for most operations

### Compression Pipeline

```elixir
@spec compress_operational_to_research(operational_events :: [map()]) :: map()
@spec extract_patterns(research_memory :: map()) :: map()
@spec abstract_for_civilization(institutional_memory :: map()) :: map()
```

### Invariant: Memory Compression Integrity

**Each memory layer is derivable from previous layer.** No information created ex nihilo.

---

# Part X: Validation

## Validation Framework

The Validation Framework ensures constitutional compliance through automated checks.

### Validation Categories

1. **Structural Validation** - Verifies data integrity
2. **Lifecycle Validation** - Checks lifecycle consistency
3. **Economic Validation** - Verifies ledger conservation
4. **Governance Validation** - Checks compliance status
5. **Graph Validation** - Detects cycles in knowledge graph
6. **Memory Validation** - Verifies compression integrity

### Validation API

```elixir
@spec validate_institution(institution_id :: atom()) :: {:valid | :invalid, [String.t()]}
@spec run_all_validations(state :: map()) :: {:passed | :failed, map()}
```

### Automated Validation Triggers

- After every tick
- After every state mutation
- On demand via API
- Periodic background checks

### Invariant: Continuous Validation

**Validation runs continuously, not just at boundaries.** Violations detected immediately.

---

# Part XI: Research Runtime

## Unified Research Runtime

Phase 12.1 transforms research institutions into persistent cognitive operating units.

### Institution Capabilities

A fully implemented ResearchInstitution can:

1. Own its constitution and governance
2. Run multiple campaigns concurrently
3. Spawn, suspend, merge, fork, archive, and complete research programs
4. Maintain its four-tier memory
5. Emit semantic events through the Event Bus
6. Record lifecycle events through the Lifecycle Registry
7. Maintain a knowledge graph
8. Account for resources through the economic ledger
9. Validate every action through governance
10. Register itself automatically in the Runtime Atlas

### Validation Criteria

**Institution operates autonomously for tens or hundreds of thousands of ticks while preserving every constitutional invariant.**

Only after this passes is Phase 12.1 complete.

### Implementation Order

Follow this sequence exactly:

1. **Milestone 1**: Institution Kernel (Constitutional Kernel) - 10h
2. **Milestone 2**: Campaigns & Programs (Evolutionary) - 8h
3. **Milestone 3**: Four-Tier Memory (Compression Pipeline) - 7h
4. **Milestone 4**: Governance Framework (Workflows) - 5h
5. **Milestone 5**: Economic Ledger (With Assets) - 5h
6. **Milestone 6**: Knowledge Graph & Discovery Portfolio - 7h
7. **Milestone 7**: Validation, Telemetry & Integration - 8h

**Total Effort**: 50 hours

---

# Part XII: Extension Rules

## Constitutional Amendment Process

This specification can only be amended through formal process:

### Amendment Proposal

1. Submit amendment proposal with rationale
2. Gather support (proposal_threshold)
3. Enter voting period
4. Ratify if threshold met
5. Cooling-off period
6. Activate amendment
7. Record in lifecycle

### Amendment Constraints

- Cannot violate core principles (Part I)
- Cannot remove existing invariants
- Can only add or refine
- Must maintain backward compatibility where possible

## Extension Guidelines

When implementing new capabilities:

### Rule 1: Reuse Existing Subsystems

If a capability can be implemented using existing constitutional components, DO NOT create another subsystem.

Reuse. Compose. Integrate.

### Rule 2: Ask the Right Question

Do not ask: "What subsystem should exist?"

Instead ask: "How would a Research Institution use the existing architecture?"

### Rule 3: Preserve Invariants

Every extension must preserve all constitutional invariants. If an invariant is violated, the extension is invalid.

### Rule 4: Expose Hooks

Every new subsystem must expose hooks for:
- CIS monitoring
- Telemetry collection
- Lifecycle tracking
- Event emission
- Governance validation

### Rule 5: Register in Atlas

Every new entity type must register in Runtime Atlas for discoverability.

## Future Phases

### Phase 12: Institutional Cognition

All Phase 12 sub-phases implement behaviors on frozen substrate:

- 12.1: Unified Research Runtime ← CURRENT
- 12.2: Discovery Exchange (networking only)
- 12.3: Human Collaboration
- 12.4: JTMS++ (reasons over canonical Knowledge Graph)
- 12.5: VSA Memory
- 12.6: Do-Calculus
- 12.7: Neuro-Symbolic Routing
- 12.8: Cognitive Immune System V1 (plugs into hooks)
- 12.9: Research OS Beta
- 12.10: Distributed Validation
- 12.11: Epistemic Coarse Graining
- 12.12: Topological Knowledge
- 12.13: Active Epistemic Foraging

### Phase 13: Institutional Self-Evolution

The OS improves itself by rewriting knowledge, governance, policies, constitutions, and eventually ontologies.

Not by rewriting code. By rewriting knowledge.

---

# Appendix A: Constitutional Invariants Summary

1. **Kernel State Ownership** - All mutations through kernel
2. **Event Completeness** - Every action emits event
3. **Lifecycle Consistency** - All entities have lifecycle entries
4. **Graph Acyclicity** - No circular justification chains
5. **Ledger Conservation** - Ledger always balances
6. **Memory Compression Integrity** - Each layer derivable from previous
7. **Constitution Immutability During Amendment** - Formal process required
8. **Pre-Mutation Validation** - Governance approves before mutation
9. **Continuous Validation** - Validation runs continuously
10. **CIS Integration** - No subsystem bypasses security
11. **Explanatory Traceability** - Every decision reconstructable from constitutional state

---

# Appendix B: Version History

- **v1.0** (June 13, 2026): Initial constitutional specification after architecture freeze
  - 11 Core Principles defined
  - 11 Constitutional Invariants established
  - Extension Rules codified
  - Phase 12 reframed as Institutional Cognition
  - Phase 13 simplified to Institutional Self-Evolution
  - Architecture frozen at Institution layer

---

# Appendix C: Related Documents

- PHASE_12_1_FINAL_ARCHITECTURE.md - Detailed architecture design
- Constitution.md - Original constitutional principles
- finalroadmap.md - Implementation roadmap
- walkthrough.md - System walkthrough

---

**This document is CONSTITUTIONALLY FROZEN.** Amendments require formal process. All implementation must conform to this specification.
