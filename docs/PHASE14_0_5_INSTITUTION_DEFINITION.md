# Phase 14.0.5 — Institution Definition

**Status**: ✅ Complete  
**Date**: June 13, 2026  
**Version**: 1.0  

---

## Executive Summary

Phase 14.0.5 establishes **constitutional roles and institutions** as first-class entities in Tiannara's governance architecture. Before any proposal can be submitted, we must define:

- **Who is allowed to submit proposals?** (Constitutional Roles)
- **What authority do they possess?** (Capabilities)
- **Which institution governs which domain?** (Institutions)
- **How are members appointed and removed?** (Appointments)

This separation of power from responsibility prevents privilege creep and ensures that no single actor has universal authority over the constitutional system.

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
                        └────────────────┘
```

### Key Principles

1. **Capability-Based Access Control (CBAC)** - Authority derives from capabilities, not roles
2. **Separation of Power and Responsibility** - Every institution defines both independently
3. **No Universal Authority** - No role or institution possesses all capabilities
4. **Conservation of Appointments** - All appointments/removals are permanently recorded
5. **Domain-Limited Authority** - Institutions operate only within their governance domains

---

## Constitutional Roles (8 Standard Roles)

Each role is a bundle of specific capabilities with explicit responsibilities.

### 1. Architect (`role_architect`)

**Authority**: `[:can_review, :can_propose, :can_audit]`

**Responsibility**:
- Maintain architectural integrity across layers
- Prevent layer violations (Science ↔ Governance separation)
- Ensure kernel immutability is preserved
- Review proposals for architectural consistency

**Appointment**: Appointed by Governance Council based on technical expertise  
**Term**: 365 days  
**Removal Conditions**:
- Repeated architectural violations
- Failure to detect layer violations
- Voluntary resignation

---

### 2. Scientist (`role_scientist`)

**Authority**: `[:can_propose, :can_simulate, :can_observe]`

**Responsibility**:
- Ensure scientific validity of proposals
- Validate simulation methodology
- Assess statistical significance
- Verify evidence quality

**Appointment**: Appointed by Review Board based on scientific credentials  
**Term**: 365 days  
**Removal Conditions**:
- Approval of scientifically invalid proposals
- Methodological errors in simulations
- Voluntary resignation

---

### 3. Auditor (`role_auditor`)

**Authority**: `[:can_audit, :can_observe, :can_review]`

**Responsibility**:
- Verify compliance with constitutional invariants
- Detect drift in governance processes
- Audit trail completeness
- Report violations to Governance Council

**Appointment**: Appointed by Observatory Council based on audit expertise  
**Term**: 365 days  
**Removal Conditions**:
- Failure to detect invariant violations
- Incomplete audit trails
- Voluntary resignation

---

### 4. Safety Officer (`role_safety_officer`)

**Authority**: `[:can_review, :can_rollback]`

**Responsibility**:
- Assess risks of proposed changes
- Ensure rollback viability before deployment
- Monitor deployment safety metrics
- Trigger rollback on safety violations

**Appointment**: Appointed by Deployment Authority based on risk assessment expertise  
**Term**: 365 days  
**Removal Conditions**:
- Approval of unsafe deployments
- Failure to verify rollback paths
- Voluntary resignation

---

### 5. Deployment Officer (`role_deployment_officer`)

**Authority**: `[:can_deploy, :can_migrate]`

**Responsibility**:
- Execute migrations at generation boundaries only
- Verify deployment prerequisites
- Monitor deployment success metrics
- Coordinate with Safety Officer on rollback readiness

**Appointment**: Appointed by Deployment Authority based on operational expertise  
**Term**: 365 days  
**Removal Conditions**:
- Deployment outside generation boundary
- Failure to verify prerequisites
- Voluntary resignation

---

### 6. Replay Officer (`role_replay_officer`)

**Authority**: `[:can_observe, :can_audit]`

**Responsibility**:
- Maintain replay integrity across constitutional versions
- Verify deterministic reconstruction of historical states
- Monitor replay success rates
- Report replay failures to Observatory Council

**Appointment**: Appointed by Observatory Council based on reproducibility expertise  
**Term**: 365 days  
**Removal Conditions**:
- Failure to detect replay divergence
- Incomplete replay verification
- Voluntary resignation

---

### 7. Migration Officer (`role_migration_officer`)

**Authority**: `[:can_migrate, :can_rollback]`

**Responsibility**:
- Plan and validate migration paths
- Estimate migration complexity and downtime
- Create rollback checkpoints
- Verify migration compatibility

**Appointment**: Appointed by Deployment Authority based on migration expertise  
**Term**: 365 days  
**Removal Conditions**:
- Failed migration planning
- Inadequate rollback preparation
- Voluntary resignation

---

### 8. Governance Council Member (`role_governance_council_member`)

**Authority**: `[:can_ratify, :can_review]`

**Responsibility**:
- Vote on proposal ratifications
- Ensure quorum requirements are met
- Apply decision rules correctly (unanimous/supermajority/majority)
- Represent institutional interests in governance decisions

**Appointment**: Elected by institutions based on governance experience  
**Term**: 730 days  
**Removal Conditions**:
- Violation of decision rules
- Failure to maintain quorum
- Loss of institutional support
- Voluntary resignation

---

## Capability Set (9 Total Capabilities)

All roles draw from this fixed capability set:

| Capability | Description | Granted To Roles |
|------------|-------------|------------------|
| `:can_review` | Review proposals and evidence | Architect, Auditor, Safety Officer, Governance Council Member |
| `:can_deploy` | Execute migrations | Deployment Officer |
| `:can_rollback` | Trigger rollbacks | Safety Officer, Migration Officer |
| `:can_ratify` | Vote on ratifications | Governance Council Member |
| `:can_observe` | Observe governance state (read-only) | Scientist, Auditor, Replay Officer |
| `:can_simulate` | Run simulations | Scientist |
| `:can_propose` | Submit proposals | Architect, Scientist |
| `:can_migrate` | Plan migrations | Deployment Officer, Migration Officer |
| `:can_audit` | Audit compliance | Architect, Auditor, Replay Officer |

**Invariant**: No role may possess all 9 capabilities (prevents universal authority).

---

## Constitutional Institutions (5 Standard Institutions)

Each institution is a collection of roles working together within defined governance domains.

### 1. Governance Council (`gov-council-001`)

**Description**: Highest decision-making body for constitutional amendments and institutional appointments.

**Governance Domains**: All 7 domains (`:replay`, `:ledger`, `:science`, `:migration`, `:execution`, `:documentation`, `:observability`)

**Authority Capabilities**:
- `:can_ratify` - Approve constitutional amendments
- `:can_appoint_institutional_members` - Appoint/remove members
- `:can_remove_institutional_members` - Remove institutional members
- `:can_amend_meta_constitution` - Modify meta-constitutional rules
- `:can_approve_budget` - Approve governance budgets

**Responsibilities**:
- Maintain constitutional integrity across all domains
- Ensure institutional balance of power
- Approve major constitutional amendments
- Oversee institutional performance
- Resolve inter-institutional disputes

**Quorum Size**: 5 members  
**Appointment Term**: 12 months  
**Status**: Active

---

### 2. Review Board (`review-board-001`)

**Description**: Evaluates constitutional amendment proposals and provides evidence-based recommendations.

**Governance Domains**: `:science`, `:migration`, `:execution`, `:replay`

**Authority Capabilities**:
- `:can_review` - Review proposals
- `:can_request_simulation` - Request additional simulations
- `:can_recommend_approval` - Recommend approval to Governance Council
- `:can_recommend_rejection` - Recommend rejection
- `:can_request_revision` - Request proposal revisions

**Responsibilities**:
- Assess scientific validity of proposals
- Evaluate migration risks and rollback plans
- Verify simulation results
- Ensure proposals meet constitutional standards
- Provide transparent reasoning for recommendations

**Quorum Size**: 3 members  
**Appointment Term**: 6 months  
**Status**: Active

---

### 3. Deployment Authority (`deploy-auth-001`)

**Description**: Executes approved constitutional migrations at generation boundaries.

**Governance Domains**: `:migration`, `:execution`, `:replay`

**Authority Capabilities**:
- `:can_deploy` - Execute migrations
- `:can_rollback` - Perform rollbacks
- `:can_schedule_migration` - Schedule deployment timing
- `:can_verify_deployment` - Verify deployment success
- `:can_report_deployment_status` - Report outcomes to Observatory

**Responsibilities**:
- Execute migrations safely at generation boundaries
- Minimize deployment downtime
- Maintain replay integrity during migrations
- Execute rollbacks when required
- Report deployment outcomes to Observatory

**Quorum Size**: 2 members  
**Appointment Term**: 6 months  
**Status**: Active

---

### 4. Observatory (`observatory-001`)

**Description**: Monitors system health and governance metrics **without governance authority**.

**Governance Domains**: All 7 domains (observational access only)

**Authority Capabilities**:
- `:can_observe` - Observe system state
- `:can_measure` - Measure metrics
- `:can_report` - Publish reports
- `:can_alert` - Trigger alerts on anomalies
- `:can_publish_dashboards` - Update observatory dashboards

**Responsibilities**:
- Monitor constitutional fitness and entropy
- Track governance metrics and latency
- Detect anomalies and drift
- Maintain six specialized dashboards
- Publish transparent reports without governance bias

**Quorum Size**: 1 member  
**Appointment Term**: 12 months  
**Status**: Active

**Critical Constraint**: The Observatory has **NO governance powers**. It cannot ratify, deploy, or appoint. It only observes and reports.

---

### 5. Scientific Council (`sci-council-001`)

**Description**: Validates scientific merit and methodological rigor independent of governance.

**Governance Domains**: `:science`, `:documentation`

**Authority Capabilities**:
- `:can_validate_theory` - Validate scientific theories
- `:can_assess_evidence` - Assess evidence quality
- `:can_certify_methodology` - Certify research methods
- `:can_reject_pseudoscience` - Reject pseudoscientific claims
- `:can_require_reproducibility` - Require reproducible results

**Responsibilities**:
- Validate scientific theories and hypotheses
- Assess quality of empirical evidence
- Certify research methodologies
- Prevent pseudoscientific contamination
- Ensure all science is reproducible

**Quorum Size**: 3 members  
**Appointment Term**: 12 months  
**Status**: Active

**Note**: The Scientific Council operates **separately from governance**. It validates scientific merit but does not participate in constitutional ratification.

---

## Governance Domains (7 Domains)

Each institution operates within specific governance domains:

| Domain | Description | Responsible Institutions |
|--------|-------------|-------------------------|
| `:replay` | Replay integrity and verification | Review Board, Deployment Authority, Observatory |
| `:ledger` | Scientific capital and accounting | Governance Council, Observatory |
| `:science` | Scientific methodology and validity | Review Board, Scientific Council, Observatory |
| `:migration` | Migration planning and execution | Review Board, Deployment Authority, Observatory |
| `:execution` | Runtime execution and safety | Review Board, Deployment Authority, Observatory |
| `:documentation` | Documentation and knowledge preservation | Governance Council, Scientific Council, Observatory |
| `:observability` | Monitoring and metrics | Governance Council, Observatory |

---

## Authorization Model

### Capability-Based Access Control (CBAC)

Instead of checking roles directly, the system verifies:

1. **Institution has domain authority** - Is the action within the institution's governance domain?
2. **Institution has capability** - Does the institution possess the required capability?
3. **Actor is member** - Is the requesting actor a member of the institution?
4. **Quorum is met** - Are enough members present for the decision?

### Example Authorization Flow

```elixir
# Actor wants to review a proposal in the science domain
actor_id = "member-123"
institution = ConstitutionalInstitution.define_review_board()
capability = :can_review
domain = :science

# Step 1: Check domain authority
ConstitutionalInstitution.has_domain_authority?(institution, domain)
# => true (Review Board has :science domain)

# Step 2: Check capability
ConstitutionalInstitution.has_capability?(institution, capability)
# => true (Review Board has :can_review)

# Step 3: Verify actor membership
CapabilityChecker.verify_actor_authorization(actor_id, institution, capability, domain)
# => :ok (if actor is member) or {:error, reason}

# Step 4: Check quorum (for decisions)
CapabilityChecker.check_quorum(institution, present_count)
# => :ok (if present_count >= 3) or {:error, "Quorum not met"}
```

### Collective Authorization

Some actions require multiple institutions to act together:

```elixir
institutions = [
  ConstitutionalInstitution.define_review_board(),
  ConstitutionalInstitution.define_deployment_authority()
]

required_caps = [:can_review, :can_deploy]
domain = :migration

CapabilityChecker.collective_authorization?(institutions, required_caps, domain)
# => :ok (if combined capabilities cover requirements)
```

---

## Appointment Lifecycle

### 1. Nomination

An authorized institution nominates a candidate for a role.

```elixir
attrs = %{
  member_id: "person-456",
  institution_id: "review-board-001",
  role_id: "role_scientist",
  appointed_by: "gov-council-001",
  term_end: DateTime.add(DateTime.utc_now(), 180, :day)
}

{:ok, appointment} = InstitutionalAppointment.create_appointment(attrs)
```

### 2. Review

The Review Board assesses candidate qualifications.

### 3. Ratification

The Governance Council votes on the appointment (requires quorum of 5).

### 4. Activation

If ratified, the member is added to the institution with the assigned role.

### 5. Term Monitoring

The Observatory tracks term expiration and alerts when renewal is needed.

### 6. Renewal/Removal

At term end, the process repeats for renewal, or a removal event is recorded.

---

## Conservation Laws

### INV-031: Appointment Conservation

**Law**: No appointment ever disappears.

All appointment and removal events are permanently recorded in the Governance Ledger. This enables:
- Deterministic reconstruction of institutional state at any point in time
- Governance archaeology (tracing why someone was appointed/removed)
- Audit trails for institutional accountability

### INV-032: Role Assignment Conservation

**Law**: No role assignment vanishes without trace.

Every role assignment and revocation is recorded with:
- Who made the assignment
- When it occurred
- Why it was made (metadata)
- When/if it was revoked

### INV-033: Institutional Membership Conservation

**Law**: Institutional membership changes are immutable events.

Adding or removing a member creates an immutable ledger entry that cannot be deleted or modified.

---

## Module Inventory

### Created Modules

1. **`TiannaraOS.Governance.ConstitutionalRole`** (322 lines)
   - Defines 8 standard roles with capabilities and responsibilities
   - Validates role definitions (no universal authority)
   - Provides role lookup and capability checking

2. **`TiannaraOS.Governance.ConstitutionalInstitution`** (305 lines)
   - Defines 5 standard institutions with domains and authorities
   - Manages institutional membership
   - Verifies quorum requirements

3. **`TiannaraOS.Governance.CapabilityChecker`** (181 lines)
   - Implements capability-based access control
   - Verifies authorization for governance actions
   - Supports collective authorization across institutions

4. **`TiannaraOS.Governance.InstitutionalAppointment`** (270 lines)
   - Records appointment and removal events
   - Tracks term limits and expirations
   - Converts appointments to governance ledger events

### Integration Points

- **Governance Ledger** (Phase 14.0.75): All appointments/removals recorded as immutable events
- **GovernanceState** (Phase 14.0.75): Current institutional composition captured in state snapshots
- **Capability Checker**: Used by all governance modules to authorize actions

---

## Acceptance Criteria

✅ **8 constitutional roles defined** with explicit capabilities and responsibilities  
✅ **5 standard institutions defined** with governance domains and authorities  
✅ **9 total capabilities** defined (no role has all 9)  
✅ **Capability-based access control** implemented and tested  
✅ **Appointment lifecycle** documented with conservation laws  
✅ **Quorum requirements** enforced for each institution  
✅ **Domain-limited authority** prevents cross-domain overreach  
✅ **Separation of power and responsibility** enforced for all institutions  
✅ **Observatory has NO governance powers** (observation only)  
✅ **Scientific Council operates separately** from constitutional governance  

---

## Next Steps

1. **Phase 14.0.75**: Implement Governance Observability Freeze
   - GovernanceState as single source of truth
   - GovernanceLedger for immutable event recording
   - GovernanceReplayEngine for deterministic reconstruction
   - ProposalGenome for structured proposal representation
   - InstitutionalReputation tracking

2. **Phase 14.1**: Implement RFC & Proposal System
   - Integrate institutional authorization into proposal submission
   - Only actors with `:can_propose` capability in authorized institutions can submit
   - Proposals tagged with governance domains for routing

---

## File Locations

- `lib/tiannara/os/governance/constitutional_role.ex` - Role definitions
- `lib/tiannara/os/governance/constitutional_institution.ex` - Institution definitions
- `lib/tiannara/os/governance/capability_checker.ex` - Authorization logic
- `lib/tiannara/os/governance/institutional_appointment.ex` - Appointment records
- `docs/PHASE14_0_5_INSTITUTION_DEFINITION.md` - This document

---

## Verification Commands

```bash
# Compile all governance modules
mix compile

# Verify role definitions
iex -S mix
iex> TiannaraOS.Governance.ConstitutionalRole.get_standard_roles() |> length()
# Should return: 8

# Verify institution definitions
iex> TiannaraOS.Governance.ConstitutionalInstitution.standard_institutions() |> length()
# Should return: 5

# Test authorization
iex> inst = TiannaraOS.Governance.ConstitutionalInstitution.define_review_board()
iex> TiannaraOS.Governance.CapabilityChecker.authorize?(inst, :can_review, :science)
# Should return: :ok

iex> TiannaraOS.Governance.CapabilityChecker.authorize?(inst, :can_deploy, :migration)
# Should return: {:error, "Institution 'Review Board' lacks capability :can_deploy"}

# Validate no universal authority
iex> roles = TiannaraOS.Governance.ConstitutionalRole.get_standard_roles()
iex> Enum.all?(roles, fn r -> TiannaraOS.Governance.ConstitutionalRole.validate_role(r) == :valid end)
# Should return: true
```

---

**Phase 14.0.5 Status**: ✅ **COMPLETE**

All constitutional roles and institutions are defined with explicit authority boundaries, capability bundles, and conservation laws. The foundation is now in place for Phase 14.0.75 (Governance Observability Freeze) and Phase 14.1 (RFC & Proposal System with institutional authorization).
