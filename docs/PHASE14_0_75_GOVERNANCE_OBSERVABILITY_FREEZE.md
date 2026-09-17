# Phase 14.0.75 — Governance Observability Freeze

**Status**: ✅ Complete  
**Date**: June 13, 2026  
**Version**: 1.0  

---

## Executive Summary

Phase 14.0.75 establishes **governance observability** as a constitutional primitive, making governance itself obey the same rigor as scientific execution. Before proposals can be submitted (Phase 14.1), we must ensure that:

- **Governance has a canonical ledger** - All events are immutable and replayable
- **State derives from ledger** - No independent state computation
- **Replay is deterministic** - State reconstructs exactly from events
- **Provenance is complete** - Every capability traces to appointments
- **Conservation laws hold** - Nothing disappears, only transitions states
- **Authority is separated** - Observatory never deploys, Deployment never ratifies

This phase transforms governance from "a collection of permissions" into "a constitutional institution with identity, lifecycle, provenance, conservation, replay, and archaeology."

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│              Constitutional Kernel                   │
│         (Immutable Layer - Phase 14.0)               │
└──────────────────┬──────────────────────────────────┘
                   │
    ┌──────────────┴──────────────┐
    │                             │
┌───▼────┐                  ┌────▼──────┐
│Scientific│                  │Governance │
│   OS     │                  │    OS     │
└─────────┘                  └────┬──────┘
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
              ┌─────▼─────┐             ┌──────▼──────┐
              │  Roles    │             │Institutions │
              │  (8 std)  │             │  (5 std)    │
              └───────────┘             └─────────────┘
                    │                           │
                    └───────────┬───────────────┘
                                │
                        ┌───────▼────────┐
                        │  Appointments  │
                        │  (Immutable)   │
                        └───────┬────────┘
                                │
                    ┌───────────▼────────────┐
                    │  Governance Ledger     │ ← INV-031, INV-032
                    │  (Canonical Source)    │
                    └───────────┬────────────┘
                                │
                    ┌───────────▼────────────┐
                    │  GovernanceState       │ ← Single source of truth
                    │  (Derived from Ledger) │
                    └───────────┬────────────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                 │
      ┌───────▼──────┐  ┌─────▼──────┐  ┌──────▼────────┐
      │ ReplayEngine │  │Provenance  │  │ CapabilityGraph│
      │  (INV-034)   │  │ (INV-033)  │  │  (Evolvable)  │
      └──────────────┘  └────────────┘  └───────────────┘
              │
      ┌───────▼────────┐
      │ InstitutionGraph│
      │ (Relationships)│
      └────────────────┘
```

### Key Principles

1. **Ledger-Centric Design** - GovernanceLedger is the canonical owner, not mutable state
2. **Deterministic Replay** - State reconstructs exactly from ledger + seed
3. **Complete Provenance** - Every metric answers "Explain why this exists?"
4. **Conservation Laws** - Institutions and appointments never disappear (INV-031, INV-032)
5. **Authority Separation** - Strict boundaries between institutions (INV-035)
6. **Evolvable Capabilities** - Capability graph enables evolution without role modification
7. **Graph-Based Relationships** - Institutional archaeology through graph traversal

---

## Module Inventory

### 1. GovernanceLedger (516 lines)

**File**: `lib/tiannara/os/governance/governance_ledger.ex`

**Purpose**: Immutable append-only ledger for all governance events. This is the **canonical source of truth** for institutional state.

**Event Types**:
- **Institutional Events**: `:institution_created`, `:institution_merged`, `:institution_split`, `:institution_retired`, `:institution_updated`
- **Role Events**: `:role_granted`, `:role_revoked`, `:role_updated`
- **Appointment Events**: `:appointment_made`, `:appointment_renewed`, `:appointment_expired`, `:appointment_removed`
- **Capability Events**: `:capability_granted`, `:capability_revoked`, `:capability_graph_updated`

**Key Features**:
- Hash chain integrity verification (SHA-256)
- Event filtering by type/institution/appointment
- Deterministic state reconstruction via replay
- GenServer-based storage (production will use persistent storage)

**API**:
```elixir
# Append event (ONLY way to modify governance state)
{:ok, event} = GovernanceLedger.append_event(:institution_created, %{
  institution_id: "inst_governance_council",
  name: "Governance Council",
  domains: [:replay, :ledger],
  capabilities: [:can_ratify]
})

# Get all events
events = GovernanceLedger.get_events()

# Reconstruct current state
state = GovernanceLedger.reconstruct_state()

# Verify integrity
:valid = GovernanceLedger.verify_integrity()
```

**Conservation Laws Enforced**:
- **INV-031**: Institution Conservation - No institution disappears
- **INV-032**: Appointment Conservation - All appointments immutable

---

### 2. GovernanceState (305 lines)

**File**: `lib/tiannara/os/governance/governance_state.ex`

**Purpose**: Single source of truth for entire governance system state. All governance metrics derive from this snapshot—nothing computes independently.

**State Components**:
- `institutions` - Current institutional composition
- `roles` - Active role assignments
- `appointments` - Current appointments (active/expired/removed)
- `capabilities` - Capability graph structure
- `active_proposals` - Proposals in various stages
- `pending_reviews/deployments/rollbacks` - Pending actions
- `budget` - Governance budget allocation
- `fitness` - Constitutional fitness score (0.8525 baseline)
- `entropy` - Constitutional entropy measurement (0.38 baseline)
- `health` - Overall governance health score

**Health Formula**:
```
Health = 0.30 × Fitness + 0.25 × (1 - Entropy) + 0.20 × Replay Quality +
         0.15 × Auditability + 0.10 × Coverage

Threshold: ≥ 0.7 healthy, < 0.6 critical
```

**API**:
```elixir
# Capture current state from ledger replay
state = GovernanceState.capture_state()

# Build state from specific events (for testing)
state = GovernanceState.from_ledger(events)

# Get institution details
inst = GovernanceState.get_institution(state, "gov-council-001")

# Check member capability
has_cap? = GovernanceState.member_has_capability?(state, "member-123", :can_review)

# Compute health
health = GovernanceState.compute_health(fitness, entropy, reconstructed)

# Compare states
diff = GovernanceState.diff(old_state, new_state)
```

---

### 3. GovernanceReplayEngine (338 lines)

**File**: `lib/tiannara/os/governance/governance_replay_engine.ex`

**Purpose**: Deterministic reconstruction of governance state from ledger events. Implements **INV-034 (Institution Replay)**.

**Replay Modes**:
- `:full` - Reconstruct complete state from genesis
- `:incremental` - Apply events from specific sequence number
- `:point_in_time` - Reconstruct state at specific timestamp
- `:verification` - Compare replay against captured state

**Key Features**:
- Full/incremental/point-in-time replay
- Verification against captured state (determinism check)
- Authority separation validation (INV-035)
- Replay statistics and audit log export

**API**:
```elixir
# Full replay from genesis
{:ok, state} = GovernanceReplayEngine.replay_full()

# Replay to specific timestamp
{:ok, historical_state} = GovernanceReplayEngine.replay_at_timestamp(target_time)

# Verify determinism
:match = GovernanceReplayEngine.verify_replay(expected_state, actual_state)

# Verify authority separation
:valid = GovernanceReplayEngine.verify_authority_separation(state)

# Get replay stats
stats = GovernanceReplayEngine.get_replay_stats()
```

**Invariant Enforcement**:
- **INV-034**: Institution Replay - State reconstructs exactly
- **INV-035**: Authority Separation - Observatory never deploys, etc.

---

### 4. InstitutionalProvenance (365 lines)

**File**: `lib/tiannara/os/governance/institutional_provenance.ex`

**Purpose**: Full explainability chain for all governance decisions. Every metric, capability, and authority must answer: "Explain why this exists?"

**Provenance Chains**:

**Capability Provenance (INV-033)**:
```
Why can Institution X deploy?
↓
Role granted to member
↓
Appointment made by Governance Council
↓
Institution created with :can_deploy capability
↓
Ledger event: institution_created
```

**Authority Provenance**:
```
Why did Review Board reject Proposal Y?
↓
Review decision recorded
↓
Reviewers appointed by Governance Council
↓
Review Board has :can_review capability in :science domain
↓
Ledger event: appointment_made
```

**API**:
```elixir
# Explain capability
{:ok, provenance} = InstitutionalProvenance.explain_capability("inst_id", :can_deploy)

# Explain authority
{:ok, provenance} = InstitutionalProvenance.explain_authority("member_id", :can_review, :science)

# Trace appointment history
{:ok, provenance} = InstitutionalProvenance.explain_appointment("appt_id")

# Get institution history
history = InstitutionalProvenance.trace_institution_history("inst_id")

# Verify provenance integrity
:valid = InstitutionalProvenance.verify_provenance_integrity()

# Export audit report
report = InstitutionalProvenance.export_provenance_report()
```

**Invariant Enforcement**:
- **INV-033**: Capability Provenance - Every capability derives from appointment

---

### 5. CapabilityGraph (441 lines)

**File**: `lib/tiannara/os/governance/capability_graph.ex`

**Purpose**: Graph-based capability structure for institutional governance. Instead of hardcoding capabilities in roles, this module maintains a graph where capabilities are nodes that can evolve independently.

**Graph Structure**:
```
Capability Nodes:
  :can_review ──┐
  :can_deploy ──┼── Role: Deployment Officer
  :can_rollback ─┘
  
  :can_ratify ────────── Role: Governance Council Member
  :can_observe ───────── Role: Observatory (read-only)
```

**Evolution Pattern**:
When a capability needs to change:
1. Update capability node definition
2. All roles referencing that node automatically inherit the change
3. No need to modify individual role definitions

**Standard Capabilities (29 total)**:
- **Governance**: `:can_review`, `:can_ratify`, `:can_propose`, `:can_appoint_institutional_members`, `:can_remove_institutional_members`, `:can_amend_meta_constitution`, `:can_approve_budget`, `:can_recommend_approval`, `:can_recommend_rejection`, `:can_request_revision`
- **Operational**: `:can_deploy`, `:can_rollback`, `:can_migrate`, `:can_schedule_migration`, `:can_verify_deployment`, `:can_report_deployment_status`
- **Observational**: `:can_observe`, `:can_audit`, `:can_measure`, `:can_report`, `:can_alert`, `:can_publish_dashboards`
- **Scientific**: `:can_simulate`, `:can_validate_theory`, `:can_assess_evidence`, `:can_certify_methodology`, `:can_reject_pseudoscience`, `:can_require_reproducibility`, `:can_request_simulation`

**API**:
```elixir
# Initialize standard graph
graph = CapabilityGraph.init_standard_graph()

# Add new capability
{:ok, updated_graph} = CapabilityGraph.add_capability(graph, :can_new_cap, %{
  name: "New Capability",
  description: "...",
  category: :governance
})

# Assign capability to role
{:ok, updated_graph} = CapabilityGraph.assign_capability_to_role(graph, :can_review, "role_architect")

# Get role capabilities
caps = CapabilityGraph.get_role_capabilities(graph, "role_architect")

# Get graph stats
stats = CapabilityGraph.get_stats(graph)
```

---

### 6. InstitutionGraph (440 lines)

**File**: `lib/tiannara/os/governance/institution_graph.ex`

**Purpose**: Graph-based tracking of institutional relationships and interactions. Instead of document references, this module stores institutional relationships as graph edges, enabling archaeology through graph traversal.

**Graph Structure**:
```
Nodes: Institutions (Governance Council, Review Board, etc.)

Edges:
  Governance Council ──appoints──→ Deployment Authority
  Governance Council ──appoints──→ Review Board
  Review Board ──reviews──→ Proposals
  Deployment Authority ──executes──→ Migrations
  Observatory ──monitors──→ All Institutions
```

**Archaeology Through Traversal**:
Example: "Why can Deployment Authority deploy?"
```
Deployment Authority
←appointed_by─ Governance Council
←ratified─ Proposal #42
←reviewed_by─ Review Board
←submitted_by─ Architect Role
```

**Standard Relationships (10 types)**:
`:appoints`, `:oversees`, `:reviews`, `:reports_to`, `:depends_on`, `:coordinates_with`, `:delegates_to`, `:audits`, `:monitors`, `:executes`

**API**:
```elixir
# Initialize standard graph
graph = InstitutionGraph.init_standard_graph()

# Add relationship
{:ok, updated_graph} = InstitutionGraph.add_edge(
  graph,
  "gov-council-001",
  :appoints,
  "review-board-001",
  %{description: "Governance Council appoints Review Board"}
)

# Traverse graph
reachable = InstitutionGraph.traverse_from(graph, "gov-council-001", :appoints, max_depth: 2)

# Get relationship history
history = InstitutionGraph.get_relationship_history(graph, "deploy-auth-001")

# Find appointers
appointers = InstitutionGraph.find_appointers(graph, "deploy-auth-001")

# Get graph stats
stats = InstitutionGraph.get_stats(graph)
```

---

## Constitutional Invariants (INV-031 through INV-035)

Five new invariants registered in [ConstitutionalInvariantRegistry](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/kernel/constitutional_invariant_registry.ex):

### INV-031: Institution Conservation

**Definition**: No institution disappears from the governance ledger. Institutions can only transition states: active → expired → archived. All institutional events are permanently recorded for replay and archaeology.

**Severity**: Critical  
**Action**: Freeze adaptation on violation  
**Validator**: `validate_institution_conservation/1`

---

### INV-032: Appointment Conservation

**Definition**: All appointments are immutable events in the governance ledger. Appointment lineage is preserved: creation → renewals → removal/expiration. No appointment record can be deleted or modified after creation.

**Severity**: Critical  
**Action**: Freeze adaptation on violation  
**Validator**: `validate_appointment_conservation/1`

---

### INV-033: Capability Provenance

**Definition**: Every capability held by an institution must derive from a valid appointment. Capability chains must trace back to ledger events without gaps. No capability exists without provenance through appointment lineage.

**Severity**: High  
**Action**: Raise violation  
**Validator**: `validate_capability_provenance/1`

---

### INV-034: Institution Replay

**Definition**: Given GovernanceLedger + Seed + Manifest, institutional state must reconstruct exactly. Replay must produce identical state as captured state at any point in time. Deterministic reconstruction ensures immutable institutional history.

**Severity**: Critical  
**Action**: Freeze adaptation on violation  
**Validator**: `validate_institution_replay/1`

---

### INV-035: Authority Separation

**Definition**: 
- Observatory may never deploy
- Deployment Authority may never ratify
- Review Board may never appoint

Each institution's capabilities are bounded by constitutional mandate.

**Severity**: Critical  
**Action**: Freeze adaptation on violation  
**Validator**: `validate_authority_separation/1`

---

## Acceptance Criteria

✅ **GovernanceLedger implemented** as canonical source of truth for all governance events  
✅ **GovernanceState implemented** as single source of truth (all metrics derive from it)  
✅ **GovernanceReplayEngine implemented** with full/incremental/point-in-time replay modes  
✅ **InstitutionalProvenance implemented** with complete explainability chains  
✅ **CapabilityGraph implemented** for evolvable capabilities (29 standard capabilities)  
✅ **InstitutionGraph implemented** for relationship tracking (10 relationship types)  
✅ **INV-031 through INV-035 registered** in ConstitutionalInvariantRegistry  
✅ **Hash chain integrity** verified for GovernanceLedger  
✅ **Deterministic replay** verified (replay matches captured state)  
✅ **Authority separation** enforced (Observatory cannot deploy, etc.)  
✅ **Conservation laws** documented and validated  
✅ **Provenance chains** traceable for all capabilities and authorities  

---

## Integration Points

### With Phase 14.0.5 (Institution Definition)

- **ConstitutionalRole** modules reference capabilities from **CapabilityGraph**
- **ConstitutionalInstitution** modules have relationships tracked in **InstitutionGraph**
- **InstitutionalAppointment** events are recorded in **GovernanceLedger**
- **CapabilityChecker** verifies authorization using **GovernanceState**

### With Phase 14.1 (RFC & Proposal System)

- Proposals will be submitted by actors authorized via **CapabilityChecker**
- Proposal reviews will be recorded as events in **GovernanceLedger**
- Review decisions will be traceable via **InstitutionalProvenance**
- Proposal routing will use **InstitutionGraph** relationships

### With Phase 13 (Constitutional Execution)

- Governance invariants (INV-031 to INV-035) execute alongside scientific invariants (INV-001 to INV-010)
- **GovernanceReplayEngine** mirrors **GenerationHistory** replay for science
- **GovernanceLedger** parallels **ScientificCapitalLedger** for capital accounting

---

## File Locations

- `lib/tiannara/os/governance/governance_ledger.ex` - Canonical event ledger (516 lines)
- `lib/tiannara/os/governance/governance_state.ex` - Single source of truth (305 lines)
- `lib/tiannara/os/governance/governance_replay_engine.ex` - Deterministic replay (338 lines)
- `lib/tiannara/os/governance/institutional_provenance.ex` - Explainability chains (365 lines)
- `lib/tiannara/os/governance/capability_graph.ex` - Evolvable capabilities (441 lines)
- `lib/tiannara/os/governance/institution_graph.ex` - Relationship tracking (440 lines)
- `lib/tiannara/os/kernel/constitutional_invariant_registry.ex` - Updated with INV-031 to INV-035
- `docs/PHASE14_0_75_GOVERNANCE_OBSERVABILITY_FREEZE.md` - This document

---

## Verification Commands

```bash
# Compile all governance modules
mix compile

# Start GovernanceLedger
iex -S mix
iex> {:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link()

# Record institutional events
iex> TiannaraOS.Governance.GovernanceLedger.append_event(:institution_created, %{
...>   institution_id: "test-inst-001",
...>   name: "Test Institution",
...>   domains: [:science],
...>   capabilities: [:can_review]
...> })

# Reconstruct state
iex> state = TiannaraOS.Governance.GovernanceLedger.reconstruct_state()

# Verify ledger integrity
iex> :valid = TiannaraOS.Governance.GovernanceLedger.verify_integrity()

# Capture governance state
iex> gov_state = TiannaraOS.Governance.GovernanceState.capture_state()

# Verify replay determinism
iex> {:ok, replayed_state} = TiannaraOS.Governance.GovernanceReplayEngine.replay_full()
iex> :match = TiannaraOS.Governance.GovernanceReplayEngine.verify_replay(gov_state, replayed_state)

# Verify authority separation
iex> :valid = TiannaraOS.Governance.GovernanceReplayEngine.verify_authority_separation(gov_state)

# Explain capability provenance
iex> {:ok, provenance} = TiannaraOS.Governance.InstitutionalProvenance.explain_capability("gov-council-001", :can_ratify)
iex> IO.inspect(provenance.chain)

# Get capability graph stats
iex> cap_graph = TiannaraOS.Governance.CapabilityGraph.init_standard_graph()
iex> TiannaraOS.Governance.CapabilityGraph.get_stats(cap_graph)

# Get institution graph stats
iex> inst_graph = TiannaraOS.Governance.InstitutionGraph.init_standard_graph()
iex> TiannaraOS.Governance.InstitutionGraph.get_stats(inst_graph)

# Verify all invariants
iex> context = %{
...>   governance_ledger: TiannaraOS.Governance.GovernanceLedger.get_events(),
...>   governance_state: gov_state,
...>   capability_graph: cap_graph
...> }
iex> TiannaraOS.Kernel.ConstitutionalInvariantRegistry.execute(:inv_031_institution_conservation, context)
iex> TiannaraOS.Kernel.ConstitutionalInvariantRegistry.execute(:inv_032_appointment_conservation, context)
iex> TiannaraOS.Kernel.ConstitutionalInvariantRegistry.execute(:inv_033_capability_provenance, context)
iex> TiannaraOS.Kernel.ConstitutionalInvariantRegistry.execute(:inv_034_institution_replay, context)
iex> TiannaraOS.Kernel.ConstitutionalInvariantRegistry.execute(:inv_035_authority_separation, context)
```

---

## Next Steps

1. **Phase 14.1**: Implement RFC & Proposal System with institutional authorization
   - Only actors with `:can_propose` capability can submit RFCs
   - RFC routing uses **InstitutionGraph** relationships
   - Proposal reviews recorded in **GovernanceLedger**
   - Review decisions traceable via **InstitutionalProvenance**

2. **Phase 14.2**: Implement constitutional test suites before simulation
   - Automated tests verify proposal compliance with invariants
   - Tests check authority separation (INV-035)
   - Tests verify capability provenance (INV-033)

3. **Phase 14.3**: Implement split simulation (Safety → Performance)
   - Safety simulation runs first (critical path)
   - Performance simulation runs second (optimization)
   - Both simulations recorded in **GovernanceLedger**

---

## Total Implementation

- **Code**: 2,405 lines across 6 new modules
- **Documentation**: This file (~650 lines)
- **Invariants**: 5 new constitutional invariants (INV-031 through INV-035)
- **Capabilities**: 29 standard capabilities defined in CapabilityGraph
- **Relationships**: 10 standard relationship types in InstitutionGraph
- **Events**: 15 event types in GovernanceLedger

---

**Phase 14.0.75 Status**: ✅ **COMPLETE**

The governance observability layer is now frozen with the same constitutional guarantees as the scientific execution layer established in Phase 13. Governance has:

- A canonical **GovernanceLedger** (immutable, replayable)
- A single **GovernanceState** (derived from ledger, not computed independently)
- Deterministic **GovernanceReplayEngine** (reconstructs state exactly)
- Complete **InstitutionalProvenance** (every metric explainable)
- Evolvable **CapabilityGraph** (capabilities evolve without role changes)
- Graph-based **InstitutionGraph** (relationships enable archaeology)
- Five new **Constitutional Invariants** (INV-031 through INV-035)

The foundation is now in place for Phase 14.1 (RFC & Proposal System) with full institutional authorization, governance ledger integration, and provenance tracking.
