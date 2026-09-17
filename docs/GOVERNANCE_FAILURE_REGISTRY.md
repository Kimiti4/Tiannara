# Failure Registry

**Version**: 1.0.0  
**Status**: 📋 Constitutional Registry  
**Purpose**: Canonical definition of all governance validation failure modes  
**Authority**: `GOVERNANCE_VALIDATION_CONSTITUTION.md` Section 3  
**Amendment Process**: RFC → Review Board → Governance Council

---

## Overview

This registry defines all failure modes that campaigns can reference. Campaigns never define failures inline - they reference entries from this registry.

This mirrors `ConstitutionalInvariantRegistry` from Phase 13.

---

## Failure Mode Index

| ID | Name | Severity | Repair Strategy | Freeze Required | Owner |
|----|------|----------|-----------------|-----------------|-------|
| FAIL-001 | Replay Mismatch | Critical | `:freeze_and_audit` | ✅ Yes | Governance Council |
| FAIL-002 | Field Divergence | Critical | `:freeze_and_audit` | ✅ Yes | Governance Council |
| FAIL-003 | Hash Chain Broken | Critical | `:freeze_and_audit` | ✅ Yes | Governance Council |
| FAIL-004 | State Inconsistency | Critical | `:freeze_and_audit` | ✅ Yes | Governance Council |
| FAIL-005 | Unauthorized Action Succeeded | Critical | `:immediate_freeze` | ✅ Yes | Governance Council |
| FAIL-006 | Authorized Action Rejected | Warning | `:tune_fitness_function` | ❌ No | Review Board |
| FAIL-007 | Role Confusion | Critical | `:immediate_freeze` | ✅ Yes | Governance Council |
| FAIL-008 | Capability Leak | Critical | `:quarantine_and_repair` | ✅ Yes | Review Board |
| FAIL-009 | Orphan Capability | Critical | `:quarantine_and_repair` | ✅ Yes | Review Board |
| FAIL-010 | Broken Lineage | Critical | `:fix_provenance_chain` | ✅ Yes | Review Board |
| FAIL-011 | Missing Appointment | Critical | `:emergency_restore` | ✅ Yes | Governance Council |
| FAIL-012 | Role Not Found | Critical | `:emergency_restore` | ✅ Yes | Governance Council |
| FAIL-013 | Institution Disappeared | Critical | `:emergency_restore` | ✅ Yes | Governance Council |
| FAIL-014 | History Gap | Critical | `:emergency_restore` | ✅ Yes | Governance Council |
| FAIL-015 | Invalid Transition | Critical | `:emergency_restore` | ✅ Yes | Governance Council |
| FAIL-016 | Record Loss | Critical | `:emergency_restore` | ✅ Yes | Governance Council |
| FAIL-017 | Mutation Undetected | Critical | `:critical_alert` | ✅ Yes | Observatory |
| FAIL-018 | Fingerprint Unchanged | Critical | `:critical_alert` | ✅ Yes | Observatory |
| FAIL-019 | Replay Succeeded on Mutated State | Critical | `:critical_alert` | ✅ Yes | Observatory |
| FAIL-020 | Gate Bypassed | Critical | `:critical_alert` | ✅ Yes | Observatory |
| FAIL-021 | Invalid Hash | Critical | `:invalidate_and_regenerate` | ✅ Yes | Review Board |
| FAIL-022 | Broken Signature | Critical | `:invalidate_and_regenerate` | ✅ Yes | Review Board |
| FAIL-023 | Timestamp Mismatch | Warning | `:recalculate_costs` | ❌ No | Review Board |
| FAIL-024 | Version Inconsistency | Warning | `:recalculate_costs` | ❌ No | Review Board |
| FAIL-025 | Terminated at Cache | Critical | `:fix_provenance_chain` | ✅ Yes | Review Board |
| FAIL-026 | Terminated at Dashboard | Critical | `:fix_provenance_chain` | ✅ Yes | Review Board |
| FAIL-027 | Incomplete Chain | Critical | `:fix_provenance_chain` | ✅ Yes | Review Board |
| FAIL-028 | Circular Reference | Critical | `:fix_provenance_chain` | ✅ Yes | Review Board |
| FAIL-029 | Reconstruction Mismatch | Critical | `:rebuild_archaeology` | ✅ Yes | Review Board |
| FAIL-030 | Missing History | Critical | `:rebuild_archaeology` | ✅ Yes | Review Board |
| FAIL-031 | Divergent State | Critical | `:rebuild_archaeology` | ✅ Yes | Review Board |
| FAIL-032 | Incomplete Chain (Archaeology) | Critical | `:rebuild_archaeology` | ✅ Yes | Review Board |
| FAIL-033 | Unbounded Growth | Warning | `:optimize_governance` | ❌ No | Governance Council |
| FAIL-034 | Oscillation | Warning | `:tune_fitness_function` | ❌ No | Governance Council |
| FAIL-035 | No Stabilization | Warning | `:optimize_governance` | ❌ No | Governance Council |
| FAIL-036 | Premature Decrease | Warning | `:optimize_governance` | ❌ No | Governance Council |
| FAIL-037 | Random Oscillation | Warning | `:tune_fitness_function` | ❌ No | Governance Council |
| FAIL-038 | No Improvement | Warning | `:tune_fitness_function` | ❌ No | Governance Council |
| FAIL-039 | Regression Accepted | Warning | `:tune_fitness_function` | ❌ No | Governance Council |
| FAIL-040 | Plateau Not Reached | Warning | `:tune_fitness_function` | ❌ No | Governance Council |
| FAIL-041 | Cost Mismatch | Warning | `:recalculate_costs` | ❌ No | Review Board |
| FAIL-042 | Missing Operation | Warning | `:recalculate_costs` | ❌ No | Review Board |
| FAIL-043 | Double Counting | Warning | `:recalculate_costs` | ❌ No | Review Board |
| FAIL-044 | Rounding Error | Warning | `:recalculate_costs` | ❌ No | Review Board |
| FAIL-045 | Timeout Exceeded | Warning | `:optimize_performance` | ❌ No | Observatory |
| FAIL-046 | Memory Overflow | Warning | `:optimize_performance` | ❌ No | Observatory |
| FAIL-047 | CPU Saturation | Warning | `:optimize_performance` | ❌ No | Observatory |
| FAIL-048 | Degraded Performance | Warning | `:optimize_performance` | ❌ No | Observatory |

---

## Failure Mode Specifications

### FAIL-001: Replay Mismatch

```yaml
failure_id: FAIL-001
name: Replay Mismatch
description: >
  Deterministic replay produced different state than captured state.
  Indicates non-determinism in replay engine or ledger corruption.

severity: :critical
repair_strategy: :freeze_and_audit
freeze_required: true
owner: Governance Council

documentation: /docs/failures/FAIL-001-replay-mismatch.md

detection:
  adapter: ReplayAdapter
  condition: "captured_state != replayed_state"
  threshold: "any divergence"

response:
  immediate_action: :freeze_all_operations
  investigation: :audit_replay_engine
  recovery: :restore_from_last_valid_state
  notification: :alert_governance_council

related_failures:
  - FAIL-002  # Field Divergence
  - FAIL-003  # Hash Chain Broken
  - FAIL-004  # State Inconsistency
```

---

### FAIL-005: Unauthorized Action Succeeded

```yaml
failure_id: FAIL-005
name: Unauthorized Action Succeeded
description: >
  An action was executed without proper authorization.
  Indicates broken role-based access controls or capability leak.

severity: :critical
repair_strategy: :immediate_freeze
freeze_required: true
owner: Governance Council

documentation: /docs/failures/FAIL-005-unauthorized-action.md

detection:
  adapter: GraphAdapter
  condition: "action_executed AND NOT authorized"
  threshold: "any violation"

response:
  immediate_action: :emergency_freeze
  investigation: :audit_authority_matrix
  recovery: :revoke_compromised_capabilities
  notification: :alert_governance_council_immediately

related_failures:
  - FAIL-007  # Role Confusion
  - FAIL-008  # Capability Leak
```

---

### FAIL-009: Orphan Capability

```yaml
failure_id: FAIL-009
name: Orphan Capability
description: >
  A capability exists without valid lineage to appointment → role → institution → ledger.
  Indicates broken provenance chain or incomplete cleanup.

severity: :critical
repair_strategy: :quarantine_and_repair
freeze_required: true
owner: Review Board

documentation: /docs/failures/FAIL-009-orphan-capability.md

detection:
  adapter: GraphAdapter
  condition: "capability EXISTS AND lineage_chain BROKEN"
  threshold: "any orphan"

response:
  immediate_action: :quarantine_orphan_capability
  investigation: :trace_lineage_break
  recovery: :repair_or_remove_capability
  notification: :alert_review_board

related_failures:
  - FAIL-010  # Broken Lineage
  - FAIL-011  # Missing Appointment
```

---

### FAIL-013: Institution Disappeared

```yaml
failure_id: FAIL-013
name: Institution Disappeared
description: >
  An institution that existed in historical state no longer appears in current state.
  Violates institution conservation law (INV-031).

severity: :critical
repair_strategy: :emergency_restore
freeze_required: true
owner: Governance Council

documentation: /docs/failures/FAIL-013-institution-disappeared.md

detection:
  adapter: LedgerAdapter
  condition: "institution_in_history AND NOT institution_in_current_state"
  threshold: "any disappearance"

response:
  immediate_action: :emergency_freeze
  investigation: :audit_ledger_integrity
  recovery: :restore_from_ledger_events
  notification: :alert_governance_council_emergency

related_failures:
  - FAIL-014  # History Gap
  - FAIL-016  # Record Loss

constitutional_invariant: INV-031
```

---

### FAIL-017: Mutation Undetected

```yaml
failure_id: FAIL-017
name: Mutation Undetected
description: >
  A component was mutated but watchdog mechanisms failed to detect it.
  Indicates broken drift detection or fingerprint computation.

severity: :critical
repair_strategy: :critical_alert
freeze_required: true
owner: Observatory

documentation: /docs/failures/FAIL-017-mutation-undetected.md

detection:
  adapter: FingerprintAdapter
  condition: "component_mutated AND fingerprint_unchanged"
  threshold: "any undetected mutation"

response:
  immediate_action: :critical_alert
  investigation: :audit_watchdog_mechanisms
  recovery: :recompute_all_fingerprints
  notification: :alert_observatory_immediately

related_failures:
  - FAIL-018  # Fingerprint Unchanged
  - FAIL-019  # Replay Succeeded on Mutated State
  - FAIL-020  # Gate Bypassed
```

---

### FAIL-025: Terminated at Cache

```yaml
failure_id: FAIL-025
name: Terminated at Cache
description: >
  Provenance chain for a metric terminated at cached value instead of ledger.
  Violates provenance integrity requirement.

severity: :critical
repair_strategy: :fix_provenance_chain
freeze_required: true
owner: Review Board

documentation: /docs/failures/FAIL-025-terminated-at-cache.md

detection:
  adapter: ArchaeologyAdapter
  condition: "provenance_chain TERMINATES_AT cache OR dashboard"
  threshold: "any improper termination"

response:
  immediate_action: :flag_metric_invalid
  investigation: :trace_provenance_chain
  recovery: :rebuild_provenance_from_ledger
  notification: :alert_review_board

related_failures:
  - FAIL-026  # Terminated at Dashboard
  - FAIL-027  # Incomplete Chain

constitutional_invariant: INV-033
```

---

### FAIL-033: Unbounded Growth

```yaml
failure_id: FAIL-033
name: Unbounded Growth
description: >
  Entropy increased indefinitely without stabilization or decrease.
  Indicates governance complexity spiraling out of control.

severity: :warning
repair_strategy: :optimize_governance
freeze_required: false
owner: Governance Council

documentation: /docs/failures/FAIL-033-unbounded-growth.md

detection:
  adapter: EntropyAdapter
  condition: "entropy_trend == :increasing AND duration > threshold"
  threshold: "100 consecutive increases"

response:
  immediate_action: :flag_entropy_critical
  investigation: :analyze_complexity_sources
  recovery: :initiate_simplification_protocol
  notification: :alert_governance_council_warning

related_failures:
  - FAIL-034  # Oscillation
  - FAIL-035  # No Stabilization
```

---

### FAIL-045: Timeout Exceeded

```yaml
failure_id: FAIL-045
name: Timeout Exceeded
description: >
  Campaign execution exceeded maximum allowed time.
  Indicates performance degradation or infinite loop.

severity: :warning
repair_strategy: :optimize_performance
freeze_required: false
owner: Observatory

documentation: /docs/failures/FAIL-045-timeout-exceeded.md

detection:
  adapter: PerformanceMonitor
  condition: "execution_time > max_allowed_time"
  threshold: "configurable per campaign"

response:
  immediate_action: :terminate_campaign
  investigation: :profile_performance_bottleneck
  recovery: :optimize_or_scale_resources
  notification: :alert_observatory_warning

related_failures:
  - FAIL-046  # Memory Overflow
  - FAIL-047  # CPU Saturation
```

---

## Usage in Campaign Registry

Campaigns reference failures by ID, not by defining them inline:

```yaml
campaign_id: GV-001
failure_modes:
  - FAIL-001  # Replay Mismatch
  - FAIL-002  # Field Divergence
  - FAIL-003  # Hash Chain Broken
  - FAIL-004  # State Inconsistency
```

The runtime looks up failure details from this registry.

---

## Version History

| Version | Date | Changes | Amended By |
|---------|------|---------|------------|
| 1.0.0 | 2026-06-13 | Initial failure registry | Governance Council |

---

**Signed**: Tiannara Constitutional Architecture Team  
**Date**: June 13, 2026  
**Authority**: Governance Council Ratification Required
