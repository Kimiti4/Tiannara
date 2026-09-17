# Phase 14.1 — RFC Lifecycle Specification

**Date**: July 3, 2026  
**Phase**: 14.1.0 (Architecture Review)  
**Status**: 🔒 PENDING FREEZE  

---

## Overview

This document defines the complete lifecycle state machine for RFCs and Proposals in Tiannara's constitutional governance system. Every transition is explicit, auditable, and replayable.

---

## RFC State Machine

### States

```
DRAFT → SUBMITTED → UNDER_REVIEW → SIMULATING → 
INSTITUTIONAL_REVIEW → RATIFICATION_VOTE → 
APPROVED → MIGRATING → DEPLOYED → REPLAY_VERIFIED → FROZEN
```

### Rejection Paths

Any state can transition to **REJECTED** if validation fails.

### State Definitions

| State | Description | Owner | Duration |
|-------|-------------|-------|----------|
| **DRAFT** | Proposal being prepared by proposer | Proposer | Unlimited |
| **SUBMITTED** | Proposal submitted for review | RFCRegistry | < 1 day |
| **UNDER_REVIEW** | Assigned to review boards | ReviewBoard | 1-7 days |
| **SIMULATING** | Running 8 mandatory simulations | GovernanceValidationLaboratory | 1-24 hours |
| **INSTITUTIONAL_REVIEW** | Human institutional oversight | InstitutionGraph | 1-14 days |
| **RATIFICATION_VOTE** | Institutional voting period | InstitutionGraph | 1-7 days |
| **APPROVED** | Ratified, awaiting migration | MigrationPlanner | < 1 day |
| **MIGRATING** | Deployment in progress | MigrationPlanner | Minutes-hours |
| **DEPLOYED** | Migration executed | MigrationPlanner | < 1 hour |
| **REPLAY_VERIFIED** | Post-deployment replay passed | ProposalReplayEngine | < 1 hour |
| **FROZEN** | Certified and immutable | PureArtifactGenerator | Permanent |
| **REJECTED** | Failed validation/ratification | RFCRegistry | Permanent |

---

## Detailed State Transitions

### 1. DRAFT → SUBMITTED

**Trigger**: Proposer calls `RFCRegistry.submit_proposal/2`

**Preconditions**:
- ✅ Proposal has valid ProposalGenome
- ✅ All required fields populated
- ✅ Proposer has `can_propose` capability
- ✅ RFC title and description non-empty

**Actions**:
1. Generate immutable `rfc_id` = SHA-256(proposal_genome_json)
2. Create initial ledger event: `proposal_submitted`
3. Set status = `:submitted`
4. Assign to default review boards
5. Emit telemetry: `{:rfc_submitted, rfc_id}`

**Postconditions**:
- RFC exists in registry
- Ledger event recorded
- Review boards notified

**Failure Modes**:
- Invalid genome → REJECTED
- Missing capabilities → REJECTED
- Duplicate RFC ID → ERROR (should not happen with SHA-256)

---

### 2. SUBMITTED → UNDER_REVIEW

**Trigger**: Automatic (RFCRegistry scheduler)

**Preconditions**:
- ✅ Status = `:submitted`
- ✅ Review boards available

**Actions**:
1. Assign to 2+ review boards based on affected domains
2. Create ledger event: `review_assigned`
3. Set status = `:under_review`
4. Notify reviewers

**Postconditions**:
- Review boards assigned
- Reviewers have 7 days to respond

**Duration**: Automatic within 24 hours

---

### 3. UNDER_REVIEW → SIMULATING

**Trigger**: All review boards submit decisions

**Preconditions**:
- ✅ All assigned review boards responded
- ✅ At least quorum approved (configurable per domain)
- ✅ No rejections without appeal

**Actions**:
1. Aggregate review decisions
2. If quorum met → proceed to simulation
3. Create ledger event: `reviews_complete`
4. Set status = `:simulating`
5. Queue simulations in GovernanceValidationLaboratory

**Postconditions**:
- Simulations begin execution
- Evidence artifacts will be generated

**Failure Modes**:
- Quorum not met → REJECTED
- Any rejection without override → REJECTED

---

### 4. SIMULATING → INSTITUTIONAL_REVIEW

**Trigger**: All 8 simulations pass

**Preconditions**:
- ✅ Structural test: PASS
- ✅ Safety test: PASS
- ✅ Governance test: PASS
- ✅ Scientific test: PASS
- ✅ Economic test: PASS
- ✅ Performance test: PASS
- ✅ Migration test: PASS
- ✅ Replay test: PASS

**Actions**:
1. Collect all simulation certificates
2. Generate SimulationCertificate
3. Create ledger event: `simulations_complete`
4. Set status = `:institutional_review`
5. Notify institutions for final review

**Postconditions**:
- All simulation evidence archived
- Institutions have 14 days for final review

**Failure Modes**:
- Any simulation FAIL → REJECTED immediately
- Simulation timeout → REJECTED

---

### 5. INSTITUTIONAL_REVIEW → RATIFICATION_VOTE

**Trigger**: Institutional review quorum approves

**Preconditions**:
- ✅ Minimum 2 institutions reviewed
- ✅ Majority approved
- ✅ No vetoes (if veto power enabled)

**Actions**:
1. Tally institutional reviews
2. If quorum met → schedule ratification vote
3. Create ledger event: `institutional_review_complete`
4. Set status = `:ratification_vote`
5. Open voting period (1-7 days)

**Postconditions**:
- Voting period active
- All institutions can vote

**Failure Modes**:
- Insufficient approvals → REJECTED
- Veto exercised → REJECTED

---

### 6. RATIFICATION_VOTE → APPROVED

**Trigger**: Voting period ends with supermajority/unanimous

**Preconditions**:
- ✅ Voting period complete
- ✅ Required threshold met (configurable):
  - Standard proposals: 66% supermajority
  - Constitutional amendments: 100% unanimous
  - Kernel changes: 100% unanimous + safety review

**Actions**:
1. Tally votes
2. If threshold met → approve
3. Create ledger event: `ratification_approved`
4. Set status = `:approved`
5. Generate RatificationCertificate
6. Prepare migration plan

**Postconditions**:
- Proposal approved
- Migration planning begins

**Failure Modes**:
- Threshold not met → REJECTED
- Tie vote → REJECTED (must resubmit with modifications)

---

### 7. APPROVED → MIGRATING

**Trigger**: Migration plan ready and verified

**Preconditions**:
- ✅ Migration plan generated
- ✅ Pre-migration checks pass
- ✅ Rollback plan defined (if reversible)
- ✅ Estimated downtime acceptable

**Actions**:
1. Execute pre-migration backup (content-addressed)
2. Create ledger event: `migration_started`
3. Set status = `:migrating`
4. Apply migration steps atomically
5. Monitor deployment health

**Postconditions**:
- Migration executing
- System may have temporary downtime

**Failure Modes**:
- Pre-migration check fail → ROLLBACK to APPROVED
- Migration error → ROLLBACK automatically

---

### 8. MIGRATING → DEPLOYED

**Trigger**: Migration steps complete successfully

**Preconditions**:
- ✅ All migration steps executed
- ✅ Post-migration verification passes
- ✅ System health checks green

**Actions**:
1. Run post-migration verification
2. Create ledger event: `migration_complete`
3. Set status = `:deployed`
4. Generate MigrationCertificate
5. Archive pre-migration state

**Postconditions**:
- New constitution deployed
- Old state preserved in archaeology

**Failure Modes**:
- Verification fail → ROLLBACK to pre-migration state
- Health check fail → ROLLBACK

---

### 9. DEPLOYED → REPLAY_VERIFIED

**Trigger**: Replay engine verifies deterministic reconstruction

**Preconditions**:
- ✅ Proposal replay successful
- ✅ Reconstructed state matches deployed state
- ✅ Certificate hashes match

**Actions**:
1. Run ProposalReplayEngine with seed
2. Compare reconstructed vs deployed state
3. If match → generate ReplayCertificate
4. Create ledger event: `replay_verified`
5. Set status = `:replay_verified`

**Postconditions**:
- Deterministic reproducibility confirmed
- Ready for final certification

**Failure Modes**:
- Replay mismatch → FLAGGED for investigation
- Hash mismatch → FLAGGED for investigation

---

### 10. REPLAY_VERIFIED → FROZEN

**Trigger**: All certificates generated and verified

**Preconditions**:
- ✅ ProposalCertificate generated
- ✅ SimulationCertificate generated
- ✅ ReviewCertificate generated
- ✅ RatificationCertificate generated
- ✅ MigrationCertificate generated
- ✅ ReplayCertificate generated
- ✅ Final aggregate certificate hash computed

**Actions**:
1. Generate final RFC_CERTIFICATE.json
2. Save separated payload/signature structure
3. Create ledger event: `rfc_frozen`
4. Set status = `:frozen`
5. Archive complete proposal lifecycle
6. Update RFC registry: `archived = true`

**Postconditions**:
- RFC permanently frozen
- Cannot be modified
- Can only be superseded by new RFC

**Failure Modes**:
- Certificate generation fail → ERROR (must fix and retry)

---

## Rejection Transitions

### Any State → REJECTED

**Triggers**:
- Simulation failure
- Review rejection (without override)
- Ratification failure
- Migration failure (after rollback)
- Replay failure (after investigation)
- Manual rejection by authorized institution

**Actions**:
1. Record rejection reason in ledger
2. Create ledger event: `proposal_rejected`
3. Set status = `:rejected`
4. Generate rejection certificate (for archaeology)
5. Archive all work done so far

**Postconditions**:
- Proposal permanently rejected
- Cannot be revived
- Must create new proposal with different ID

---

## Supersession Mechanism

### FROZEN → SUPERSEDED (by new RFC)

**Trigger**: New RFC explicitly supersedes this one

**Preconditions**:
- ✅ Current RFC is FROZEN
- ✅ New RFC references this RFC in `supersedes` field
- ✅ New RFC reaches FROZEN state

**Actions**:
1. Update current RFC: `superseded_by = new_rfc_id`
2. Create ledger event: `rfc_superseded`
3. Link to new RFC in registry
4. Preserve old RFC in archaeology (immutable)

**Postconditions**:
- Old RFC marked as superseded
- New RFC becomes canonical
- Both preserved in archaeology

---

## Timeouts and Expirations

### State-Specific Timeouts

| State | Timeout | Action on Timeout |
|-------|---------|-------------------|
| UNDER_REVIEW | 7 days | Auto-reject if no reviews |
| SIMULATING | 24 hours | Auto-reject if simulations stall |
| INSTITUTIONAL_REVIEW | 14 days | Auto-reject if no response |
| RATIFICATION_VOTE | 7 days | Auto-reject if insufficient votes |
| MIGRATING | 1 hour | Auto-rollback if stuck |
| DEPLOYED | 1 hour | Flag if replay not started |

### Timeout Handling

When timeout occurs:
1. Create ledger event: `state_timeout`
2. Record timeout reason
3. Transition to REJECTED (or ROLLBACK for MIGRATING)
4. Notify proposer

---

## Ledger Events Summary

### Event Types

| Event Type | Fields | Purpose |
|------------|--------|---------|
| `proposal_submitted` | rfc_id, proposer_id, genome_hash | Track submission |
| `review_assigned` | rfc_id, review_board_ids | Track assignment |
| `review_submitted` | rfc_id, board_id, decision, rationale | Record review |
| `reviews_complete` | rfc_id, quorum_met, approval_count | Summarize reviews |
| `simulation_started` | rfc_id, simulation_type | Track simulation |
| `simulation_complete` | rfc_id, simulation_type, result, cert_hash | Record result |
| `simulations_complete` | rfc_id, all_passed, cert_hashes | Summarize simulations |
| `institutional_review_complete` | rfc_id, institution_ids, decisions | Record institutional review |
| `vote_cast` | rfc_id, institution_id, voter_id, vote | Record individual vote |
| `ratification_complete` | rfc_id, total_votes, yes_votes, result | Summarize votes |
| `migration_started` | rfc_id, migration_plan_hash | Track migration start |
| `migration_step_executed` | rfc_id, step_number, result | Track each step |
| `migration_complete` | rfc_id, success, rollback_available | Record completion |
| `replay_started` | rfc_id, seed, base_time | Track replay start |
| `replay_complete` | rfc_id, match, reconstructed_hash | Record replay result |
| `rfc_frozen` | rfc_id, final_cert_hash | Mark as frozen |
| `rfc_superseded` | rfc_id, superseded_by | Track supersession |
| `proposal_rejected` | rfc_id, reason, failed_stage | Record rejection |
| `state_timeout` | rfc_id, state, timeout_duration | Record timeout |

### Event Chain Integrity

Every event includes:
- `event_id`: SHA-256(event_content + timestamp)
- `previous_hash`: Hash of previous event (blockchain-style)
- `event_hash`: SHA-256 of this event's content
- `signature`: Digital signature of actor/institution

This creates an immutable, tamper-evident chain.

---

## State Query API

### Get RFC State

```elixir
RFCRegistry.get_rfc_state(rfc_id)
# Returns: %{status, created_at, updated_at, current_proposal_id}
```

### Get Proposal Lifecycle

```elixir
ProposalLedger.get_lifecycle(proposal_id)
# Returns: [events] in chronological order
```

### Get Current Stage

```elixir
RFCRegistry.current_stage(rfc_id)
# Returns: :draft | :under_review | :simulating | ...
```

### Get Time in State

```elixir
RFCRegistry.time_in_state(rfc_id)
# Returns: %{state, duration_ms, timeout_remaining_ms}
```

---

## Metrics and Observability

### Telemetry Events

```elixir
[:rfc, :submitted]
[:rfc, :review_started]
[:rfc, :simulation_started]
[:rfc, :vote_opened]
[:rfc, :migration_started]
[:rfc, :frozen]
[:rfc, :rejected]
[:rfc, :timeout]
```

### Key Metrics

- **RFC throughput**: RFCs submitted per day
- **Approval rate**: % of RFCs that reach FROZEN
- **Average time to freeze**: Days from SUBMITTED to FROZEN
- **Rejection reasons**: Distribution of failure modes
- **Simulation pass rate**: % passing all 8 simulations
- **Ratification success rate**: % achieving quorum
- **Migration success rate**: % deploying without rollback

---

## Conclusion

This lifecycle specification defines every state, transition, precondition, action, postcondition, and failure mode for RFC governance. The state machine is:

✅ **Complete** — All paths covered  
✅ **Deterministic** — Same inputs → same transitions  
✅ **Auditable** — Every transition logged to ledger  
✅ **Replayable** — Full lifecycle reconstructable from events  
✅ **Safe** — Multiple validation gates prevent bad proposals  

**Next Step**: Freeze this lifecycle specification before implementing state machine logic.
