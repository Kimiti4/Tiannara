# Phase 12.1: Unified Research Runtime - FINAL Constitutional Architecture

**Version**: 3.0 (Post-Constitutional Review)  
**Date**: June 13, 2026  
**Status**: ARCHITECTURE FROZEN - READY FOR IMPLEMENTATION

---

## Executive Summary

This is the **final architectural revision** before Phase 12 implementation begins. After incorporating constitutional refinements, Tiannara's research infrastructure has reached **99% architectural completeness**. The remaining work is capability realization, not architectural evolution.

### Last Major Architectural Redesign

This plan represents Tiannara's **last major architectural redesign**. From this point forward:
- Phase 12 = Capability realization on frozen foundation
- Phase 13 = Ontological evolution using stable substrate
- No new top-level abstractions introduced

### Key Constitutional Additions

1. **InstitutionKernel → Constitutional Kernel** (owns all state mutation)
2. **Semantic Event Bus** inserted between semantic events and lifecycle registry
3. **Runtime Atlas Registration** (institutions auto-publish to OS)
4. **Claim Graph → Knowledge Graph** (multi-node type graph)
5. **Campaign Evolution** (genome, fitness, strategy, memory)
6. **Institution Identity** (mission, philosophy, reputation, trust)
7. **Memory Compression Pipeline** (each layer summarizes previous)
8. **Economic Assets** (intellectual capital, knowledge assets)
9. **Discovery Lifecycle Expansion** (published before adopted)
10. **Program State Expansion** (merged, forked, archived)
11. **CIS Security Hooks** (pre-plugged interfaces)
12. **Institution World Model** (separate from civilization model)
13. **Institution Constitution** (genome for scientific culture)

---

## Executive Summary

This revised plan addresses the architectural critique that identified `ResearchProgram` as the wrong top-level entity. The new architecture inverts the hierarchy:

- **ResearchInstitution** = Permanent entity (persists across deep time)
- **ResearchCampaign** = Long-lived scientific field (survives multiple programs)
- **ResearchProgram** = Transient process (executes within campaign context)

An **InstitutionKernel** owns all core services (scheduling, lifecycle, governance, budgeting, event routing), reducing coupling and preparing for Phase 12.2+ integration.

---

## Architectural Hierarchy

```
ResearchInstitution (permanent)
├── InstitutionKernel (GenServer)
│   ├── Scheduler (tick processing)
│   ├── Lifecycle Manager
│   ├── Event Router (semantic → canonical)
│   ├── Governance Validator
│   └── Budget Ledger Manager
│
├── ResearchCampaigns (long-lived)
│   ├── Campaign A: "Quantum Computing"
│   │   ├── Program 1 (completed)
│   │   ├── Program 2 (active)
│   │   └── Program 3 (pending)
│   └── Campaign B: "Neural Networks"
│       └── ...
│
├── Four-Tier Memory
│   ├── Operational Memory (current tick)
│   ├── Research Memory (hypotheses, experiments, evidence)
│   ├── Institutional Memory (patterns, heuristics)
│   └── Civilizational Interface (read-only, Phase 12.11)
│
├── Economic Ledger
│   ├── Income entries
│   ├── Expense entries
│   ├── Allocations
│   ├── Commitments
│   └── Reserves
│
├── Governance Framework
│   ├── Policies (ethics, safety, economic, publication)
│   ├── Treaties (inter-institution agreements)
│   └── Compliance workflows (multi-stage approvals)
│
├── Claim Graph (JTMS++ prep)
│   ├── Claims (justified beliefs)
│   ├── Supporting evidence
│   └── Dependency chains
│
└── Discovery Portfolio
    ├── Discoveries with status tracking
    ├── Citation network
    └── Adoption metrics
```

---

## Implementation Milestones

### Layer A — Infrastructure (Milestones 1-5)

#### Milestone 1: Institution Kernel ✅ FOUNDATION

**Objective**: Create permanent institution entity with kernel managing all core services.

**New Files**:
1. `lib/tiannara/os/research_institution.ex` - Institution struct
2. `lib/tiannara/os/institution_kernel.ex` - GenServer kernel
3. `lib/tiannara/os/research_campaign.ex` - Campaign struct

**Key Design Decisions**:

1. **Institution is permanent, programs are transient**
   ```elixir
   # BEFORE: ResearchProgram was top-level
   state.research_programs[%{id => program}]
   
   # AFTER: ResearchInstitution is top-level
   state.research_institutions[%{id => institution}]
   institution.campaigns[%{campaign_id => campaign}]
   campaign.programs[%{program_id => program}]
   ```

2. **InstitutionKernel owns everything**
   - Single GenServer per institution
   - Manages tick processing, event routing, compliance
   - All subsystems register with kernel

3. **Semantic events route through kernel to canonical registry**
   ```elixir
   # Semantic event (domain-specific)
   emit_semantic_event(:program_spawned, %{
     campaign_id: camp_id,
     program_id: prog_id,
     agenda: "quantum_error_correction"
   })
   
   # Kernel routes to canonical lifecycle registry
   LifecycleRegistry.record_created(:research_program, prog_id, tick, metadata)
   ```

**Institution Struct**:
```elixir
defmodule TiannaraOS.ResearchInstitution do
  @derive Jason.Encoder
  defstruct [
    # Identity
    :id,                    # atom() - unique identifier
    :world_id,              # atom() - operating world
    :founded_tick,          # integer() - creation tick
    :status,                # :active | :dormant | :dissolved
    
    # Kernel
    kernel_pid: nil,        # pid() | nil - InstitutionKernel process
    
    # Ownership
    campaigns: %{},         # map(campaign_id => ResearchCampaign.t())
    active_program_count: 0, # integer() - currently executing programs
    
    # Four-Tier Memory
    operational_memory: [],      # list(operational_event())
    research_memory: %{},        # %{hypotheses: [], experiments: [], evidence: []}
    institutional_memory: %{},   # %{patterns: [], heuristics: []}
    civilizational_interface: %{}, # read-only interface (Phase 12.11)
    
    # Economic Ledger
    economic_ledger: [],    # list(ledger_entry())
    
    # Governance
    governance_state: %{    # policies, treaties, compliance
      policies: [],
      treaties: [],
      compliance_status: :compliant,
      pending_approvals: []
    },
    
    # Claim Graph (JTMS++ prep)
    claim_graph: %{},       # map(claim_id => claim_node())
    
    # Lifecycle Integration
    semantic_event_log: [],      # list(semantic_event())
    last_lifecycle_sync_tick: nil # integer()
  ]
  
  @type t :: %__MODULE__{
    id: atom(),
    world_id: atom(),
    founded_tick: integer(),
    status: atom(),
    kernel_pid: pid() | nil,
    campaigns: map(),
    active_program_count: integer(),
    operational_memory: [map()],
    research_memory: map(),
    institutional_memory: map(),
    civilizational_interface: map(),
    economic_ledger: [map()],
    governance_state: map(),
    claim_graph: map(),
    semantic_event_log: [map()],
    last_lifecycle_sync_tick: integer() | nil
  }
end
```

**Campaign Struct**:
```elixir
defmodule TiannaraOS.ResearchCampaign do
  @derive Jason.Encoder
  defstruct [
    :id,                    # atom()
    :institution_id,        # atom()
    :name,                  # String.t() - e.g., "Quantum Computing Research"
    :founded_tick,          # integer()
    :status,                # :active | :completed | :archived
    
    # Programs
    programs: %{},          # map(program_id => ResearchProgram.t())
    completed_programs: [], # list(program_id)
    
    # Knowledge accumulation
    accumulated_knowledge: %{}, # patterns learned across programs
    key_discoveries: [],        # list(discovery_id)
    
    # Metrics
    total_programs_spawned: 0,
    successful_programs: 0,
    discoveries_produced: 0
  ]
end
```

**InstitutionKernel API**:
```elixir
defmodule TiannaraOS.InstitutionKernel do
  use GenServer
  
  @doc "Start institution kernel process"
  @spec start_link(atom(), map()) :: {:ok, pid()}
  def start_link(institution_id, init_state) do
    GenServer.start_link(__MODULE__, {institution_id, init_state})
  end
  
  @doc "Process one tick for institution"
  @spec tick(pid(), integer()) :: :ok
  def tick(kernel_pid, current_tick) do
    GenServer.call(kernel_pid, {:tick, current_tick})
  end
  
  @doc "Spawn new campaign within institution"
  @spec spawn_campaign(pid(), String.t(), map()) :: {:ok, atom()}
  def spawn_campaign(kernel_pid, name, params) do
    GenServer.call(kernel_pid, {:spawn_campaign, name, params})
  end
  
  @doc "Spawn program within campaign"
  @spec spawn_program(pid(), atom(), map()) :: {:ok, atom()}
  def spawn_program(kernel_pid, campaign_id, params) do
    GenServer.call(kernel_pid, {:spawn_program, campaign_id, params})
  end
  
  @doc "Emit semantic event (routes to canonical lifecycle registry)"
  @spec emit_semantic_event(pid(), atom(), map()) :: :ok
  def emit_semantic_event(kernel_pid, event_type, metadata) do
    GenServer.cast(kernel_pid, {:emit_semantic_event, event_type, metadata})
  end
  
  @doc "Validate governance compliance"
  @spec validate_compliance(pid()) :: {:compliant | :violation, [String.t()]}
  def validate_compliance(kernel_pid) do
    GenServer.call(kernel_pid, :validate_compliance)
  end
  
  @doc "Get economic ledger balance"
  @spec ledger_balance(pid()) :: map()
  def ledger_balance(kernel_pid) do
    GenServer.call(kernel_pid, :ledger_balance)
  end
  
  # GenServer callbacks
  @impl true
  def init({institution_id, init_state}) do
    state = %{
      institution_id: institution_id,
      institution: init_state,
      current_tick: 0,
      subscribers: []
    }
    {:ok, state}
  end
  
  @impl true
  def handle_call({:tick, current_tick}, _from, state) do
    # Process tick: schedule programs, check compliance, emit events
    updated_state = process_tick(state, current_tick)
    {:reply, :ok, %{updated_state | current_tick: current_tick}}
  end
  
  @impl true
  def handle_cast({:emit_semantic_event, event_type, metadata}, state) do
    # Route semantic event to canonical lifecycle registry
    route_to_lifecycle_registry(event_type, metadata, state.current_tick)
    {:noreply, state}
  end
end
```

**Success Criteria**:
- ✅ Institution persists across ticks
- ✅ Campaigns can be created/managed
- ✅ Programs spawn within campaigns
- ✅ Kernel processes ticks correctly
- ✅ Semantic events route to canonical registry
- ✅ All unit tests pass

**Estimated Effort**: 8 hours

---

#### Milestone 2: Research Campaigns & Program Orchestration

**Objective**: Implement campaign management and program execution within campaign context.

**New Files**:
4. `lib/tiannara/os/campaign_manager.ex` - Campaign lifecycle management
5. `lib/tiannara/os/program_orchestrator.ex` - Program execution orchestration

**Key Features**:

1. **Campaign Manager**
   ```elixir
   defmodule TiannaraOS.CampaignManager do
     @doc "Create new campaign within institution"
     def create_campaign(institution_id, name, research_domain, initial_budget)
     
     @doc "Archive completed campaign"
     def archive_campaign(institution_id, campaign_id)
     
     @doc "Extract campaign knowledge for institutional memory"
     def extract_campaign_knowledge(institution_id, campaign_id)
   end
   ```

2. **Program Orchestrator**
   ```elixir
   defmodule TiannaraOS.ProgramOrchestrator do
     @doc "Execute program within campaign context"
     def execute_program(campaign_id, program_id, tick)
     
     @doc "Complete program and archive results"
     def complete_program(campaign_id, program_id, outcome)
     
     @doc "Spawn child program from parent insights"
     def spawn_child_program(campaign_id, parent_program_id, modifications)
   end
   ```

**Program Evolution**:
- Programs remain similar to current `ResearchProgram` struct
- But now owned by campaigns, not institutions directly
- Programs inherit campaign context (domain, goals, knowledge)

**Success Criteria**:
- ✅ Campaigns manage program lifecycles
- ✅ Programs execute within campaign context
- ✅ Campaign knowledge accumulates across programs
- ✅ Child programs inherit parent insights

**Estimated Effort**: 6 hours

---

#### Milestone 3: Four-Tier Institutional Memory

**Objective**: Implement layered memory system preparing for Phase 12.11 epistemic coarse graining.

**New Files**:
6. `lib/tiannara/os/institutional_memory.ex` - Memory management system

**Memory Tiers**:

1. **Operational Memory** (volatile, current tick only)
   ```elixir
   operational_memory: [
     %{tick: 1000, event: :program_started, program_id: :prog_1},
     %{tick: 1000, event: :budget_allocated, amount: 100.0}
   ]
   ```

2. **Research Memory** (persistent, hypotheses/experiments/evidence)
   ```elixir
   research_memory: %{
     hypotheses: [
       %{id: :hyp_1, proposed_tick: 1000, tested_tick: 1500, outcome: :supported}
     ],
     experiments: [...],
     evidence: [...]
   }
   ```

3. **Institutional Memory** (persistent, patterns/heuristics/meta-knowledge)
   ```elixir
   institutional_memory: %{
     patterns: [
       %{pattern: "quantum_algorithms_succeed_with_high_budget", confidence: 0.85}
     ],
     heuristics: [...],
     meta_knowledge: [...]
   }
   ```

4. **Civilizational Interface** (read-only, populated by Phase 12.11)
   ```elixir
   civilizational_interface: %{
     # Read-only access to civilization-wide knowledge
     # Populated by Epistemic Coarse Graining (Phase 12.11)
     query_fn: fn pattern -> matching_civilization_knowledge end
   }
   ```

**Memory Operations**:
```elixir
defmodule TiannaraOS.InstitutionalMemory do
  @doc "Record operational event (auto-pruned after tick)"
  def record_operational_event(institution_id, event)
  
  @doc "Archive hypothesis/experiment/evidence to research memory"
  def archive_research_record(institution_id, type, record)
  
  @doc "Extract patterns from research memory to institutional memory"
  def extract_patterns(institution_id)
  
  @doc "Query relevant memory for new research agenda"
  def query_relevant_memory(institution_id, agenda_description, top_k \\ 5)
  
  @doc "Prune operational memory (keep only current tick)"
  def prune_operational_memory(institution_id)
end
```

**Success Criteria**:
- ✅ Four-tier memory structure implemented
- ✅ Operational memory auto-prunes
- ✅ Research memory persists hypotheses/experiments/evidence
- ✅ Institutional memory extracts patterns
- ✅ Memory retrieval latency < 10ms

**Estimated Effort**: 6 hours

---

#### Milestone 4: Governance Framework with Workflows

**Objective**: Implement multi-stage governance approval workflows instead of boolean compliance.

**New Files**:
7. `lib/tiannara/os/governance_framework.ex` - Governance management

**Governance Workflows**:

1. **Ethics Approval Workflow**
   ```
   Proposed Research → Ethics Review → Safety Assessment → Approval/Denial
   ```

2. **Safety Approval Workflow**
   ```
   Risk Assessment → Mitigation Plan → Safety Board Review → Approval/Denial
   ```

3. **Economic Approval Workflow**
   ```
   Budget Proposal → Cost-Benefit Analysis → Economic Board → Approval/Denial
   ```

4. **Publication Approval Workflow**
   ```
   Draft Discovery → Peer Review → Validation → Publication Approval
   ```

**Governance State**:
```elixir
governance_state: %{
  policies: [
    %{id: :ethics_policy_v1, type: :ethics, version: 1},
    %{id: :safety_policy_v2, type: :safety, version: 2}
  ],
  treaties: [
    %{id: :treaty_A_B, partner_institution: :inst_B, terms: [...]}
  ],
  compliance_status: :compliant, # :compliant | :violation | :under_review
  pending_approvals: [
    %{
      approval_id: :appr_1,
      type: :ethics,
      subject: :prog_1,
      stage: :ethics_review,
      submitted_tick: 1000
    }
  ]
}
```

**Governance API**:
```elixir
defmodule TiannaraOS.GovernanceFramework do
  @doc "Submit research proposal for ethics approval"
  def submit_ethics_approval(institution_id, program_id, proposal)
  
  @doc "Check compliance status"
  def check_compliance(institution_id)
  
  @doc "Join inter-institution treaty"
  def join_treaty(institution_id, treaty_id, partner_institution_id)
  
  @doc "Validate action against governance policies"
  def validate_action(institution_id, action_type, action_details)
  
  @doc "Process pending approvals"
  def process_pending_approvals(institution_id)
end
```

**Success Criteria**:
- ✅ Four approval workflows implemented
- ✅ Pending approvals tracked
- ✅ Compliance checking works
- ✅ Treaty management functional

**Estimated Effort**: 5 hours

---

#### Milestone 5: Economic Ledger System

**Objective**: Replace simple budget tracking with full economic ledger compatible with Phase 12.2 Discovery Exchange.

**New Files**:
8. `lib/tiannara/os/economic_ledger.ex` - Ledger management

**Ledger Entry Types**:
```elixir
@type ledger_entry :: %{
  entry_id: atom(),
  tick: integer(),
  entry_type: :income | :expense | :allocation | :commitment | :reserve,
  amount: float(),
  category: atom(),
  description: String.t(),
  reference_id: atom() | nil  # links to program/discovery/etc
}
```

**Ledger Operations**:
```elixir
defmodule TiannaraOS.EconomicLedger do
  @doc "Record income entry"
  def record_income(institution_id, source, amount, description)
  
  @doc "Record expense entry"
  def record_expense(institution_id, category, amount, purpose, reference_id \\ nil)
  
  @doc "Allocate budget to categories"
  def allocate_budget(institution_id, allocations)
  
  @doc "Create commitment (reserved for future use)"
  def create_commitment(institution_id, amount, purpose, expiration_tick)
  
  @doc "Get ledger balance summary"
  def ledger_balance(institution_id)
  
  @doc "Get spending by category"
  def spending_by_category(institution_id)
  
  @doc "Verify ledger conservation invariant"
  def verify_conservation(institution_id)
end
```

**Ledger Conservation Invariant**:
```
Total Income - Total Expenses = Current Balance + Commitments + Reserves
```

**Verification**:
```elixir
def verify_conservation(institution_id) do
  total_income = sum_entries(institution_id, :income)
  total_expenses = sum_entries(institution_id, :expense)
  current_balance = get_current_balance(institution_id)
  total_commitments = sum_commitments(institution_id)
  total_reserves = sum_reserves(institution_id)
  
  expected = current_balance + total_commitments + total_reserves
  actual = total_income - total_expenses
  
  assert abs(expected - actual) < 0.01,
    "Ledger violation: income=#{total_income}, expenses=#{total_expenses}, " <>
    "balance=#{current_balance}, commitments=#{total_commitments}, reserves=#{total_reserves}"
end
```

**Success Criteria**:
- ✅ Five entry types supported
- ✅ Ledger conservation invariant holds
- ✅ Budget allocation works
- ✅ Commitments tracked separately
- ✅ Spending reports generated

**Estimated Effort**: 4 hours

---

### Layer B — Institution Services (Milestones 6-7)

#### Milestone 6: Discovery Portfolio & Claim Graph

**Objective**: Implement discovery management with status tracking and claim graph for JTMS++ preparation.

**New Files**:
9. `lib/tiannara/os/discovery_portfolio.ex` - Discovery management
10. `lib/tiannara/os/claim_graph.ex` - Claim graph for JTMS++ prep

**Discovery Status Tracking**:
```elixir
@type discovery_status :: :candidate | :validated | :replicated | :adopted | :obsolete | :retracted

discovery_portfolio: %{
  discovery_id => %{
    discovery_id: atom(),
    added_tick: integer(),
    status: discovery_status(),
    validation_level: :l1 | :l2 | :l3,
    citation_count: integer(),
    adoption_count: integer(),
    adopting_institutions: [atom()]
  }
}
```

**Claim Graph Structure**:
```elixir
claim_graph: %{
  claim_id => %{
    claim_id: atom(),
    claim_type: :hypothesis | :discovery | :theory,
    supporting_evidence: [atom()],
    confidence: float(),
    dependent_claims: [atom()],
    justification_chain: [atom()],
    last_validated_tick: integer()
  }
}
```

**Claim Graph Operations**:
```elixir
defmodule TiannaraOS.ClaimGraph do
  @doc "Add claim to graph"
  def add_claim(institution_id, claim_id, claim_type, supporting_evidence, confidence)
  
  @doc "Add dependency between claims"
  def add_dependency(institution_id, parent_claim_id, dependent_claim_id)
  
  @doc "Invalidate claim and cascade to dependents"
  def invalidate_claim(institution_id, claim_id)
  
  @doc "Get justification strength for claim"
  def justification_strength(institution_id, claim_id)
  
  @doc "Detect circular dependencies"
  def detect_circular_dependencies(institution_id)
end
```

**Success Criteria**:
- ✅ Six discovery statuses tracked
- ✅ Claim graph supports dependencies
- ✅ Circular dependency detection works
- ✅ Justification strength calculable
- ✅ Invalidation cascades correctly

**Estimated Effort**: 5 hours

---

#### Milestone 7: Validation, Telemetry & Integration

**Objective**: Complete validation suite, telemetry instrumentation, and Runtime Atlas updates.

**Validation Campaigns**:

1. **Single Institution Lifecycle Test** (10k ticks)
   - Verify institution persistence
   - Test campaign/program management
   - Validate memory accumulation
   - Check governance compliance
   - Verify ledger conservation

2. **Multi-Institution Collaboration Test** (20k ticks)
   - Test treaty management
   - Verify cross-institution citations
   - Track adoption metrics
   - Validate claim graph consistency

3. **Governance Stress Test**
   - Attempt policy violations
   - Verify approval workflows
   - Test compliance restoration

4. **Memory Retrieval Performance Test**
   - Measure retrieval latency (< 10ms)
   - Verify relevance ranking (> 0.7 for top-5)
   - Test memory pruning efficiency

**Telemetry Metrics**:

1. **Institution Health**
   - Active campaigns count
   - Active programs count
   - Budget utilization rate
   - Compliance status

2. **Research Productivity**
   - Discoveries per tick
   - Hypothesis success rate
   - Experimental efficiency
   - Citation/adoption counts

3. **Memory Performance**
   - Memory tier sizes
   - Retrieval latency
   - Pruning frequency
   - Hit rate

4. **Economic Health**
   - Ledger balance
   - Income/expense rates
   - Commitment utilization
   - Budget allocation efficiency

5. **Lifecycle Events**
   - Semantic events emitted
   - Canonical events routed
   - Event emission latency
   - Missing events count

**Runtime Atlas Updates**:

New Components:
1. **ResearchInstitution** - Permanent entity
2. **InstitutionKernel** - Core GenServer
3. **ResearchCampaign** - Long-lived campaign
4. **InstitutionalMemory** - Four-tier memory
5. **GovernanceFramework** - Approval workflows
6. **EconomicLedger** - Ledger system
7. **DiscoveryPortfolio** - Discovery management
8. **ClaimGraph** - JTMS++ preparation

Modified Components:
1. **ResearchProgram** - Now owned by campaigns
2. **State** - Added `research_institutions` field

**Success Criteria**:
- ✅ All 4 validation campaigns pass
- ✅ All telemetry metrics active
- ✅ Runtime Atlas updated
- ✅ All invariants hold
- ✅ Performance benchmarks met

**Estimated Effort**: 8 hours

---

## Total Estimated Effort

| Milestone | Hours |
|-----------|-------|
| M1: Institution Kernel | 8 |
| M2: Campaigns & Programs | 6 |
| M3: Four-Tier Memory | 6 |
| M4: Governance Framework | 5 |
| M5: Economic Ledger | 4 |
| M6: Discovery & Claims | 5 |
| M7: Validation & Telemetry | 8 |
| **Total** | **42 hours** |

---

## Invariants

### Invariant 1: Ledger Conservation
```
Total Income - Total Expenses = Current Balance + Commitments + Reserves
```

### Invariant 2: Claim Graph Acyclicity
No circular dependencies in claim graph.

### Invariant 3: Discovery Portfolio Consistency
All discoveries in portfolio exist in `state.discoveries`.

### Invariant 4: Lifecycle Event Completeness
Every institutional action emits corresponding lifecycle event.

### Invariant 5: Memory Tier Integrity
Operational memory contains only current tick events.

---

## Next Steps

After Phase 12.1 completion:

**Phase 12.2: Discovery Exchange**
- Cross-institution discovery sharing
- Citation network expansion
- Trust and provenance tracking
- Discovery marketplace

The Research Institution runtime provides the foundation for all Phase 12+ subsystems.

---

**Plan Version**: 2.0  
**Last Updated**: June 13, 2026  
**Architectural Review**: COMPLETE  
**Ready for Implementation**: YES
