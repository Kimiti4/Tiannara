# Constitutional Invariants — Tiannara Operating System

**Document Type:** Constitutional Artifact (Immutable)  
**Phase Introduced:** Phase 13.5B — Constitutional Integrity Hardening  
**Version:** 1.0  
**Status:** FROZEN  
**Generated:** 2026-06-13  

---

## Purpose

This document defines all executable constitutional invariants that govern the Tiannara research civilization. Every invariant is an executable object registered in `ConstitutionalInvariantRegistry`. No validator anywhere in the system may hardcode invariant logic—all validation must delegate to the registry.

These invariants are **immutable laws** of the Tiannara constitution. They cannot be violated without raising a `ConstitutionalViolation` and freezing adaptation.

---

## Invariant Registry Architecture

```
ConstitutionalInvariantRegistry (single source of truth)
        │
        │ provides invariant definitions
        ▼
StructuralValidationGate (executes all invariants)
        │
        │ enforces pass/fail policy
        ▼
ConstitutionalExecutor (mandatory entry point)
        │
        │ blocks execution if any invariant fails
        ▼
RecursiveCivilizationRunner (simulation)
```

---

## INV-001: Replay Determinism

**Title:** Replay Determinism  
**Definition:** Every generation's scientific capital must be exactly reconstructable from canonical transactions using the active policy coefficients. Any deviation indicates corruption or tampering.  
**Canonical Inputs:**
- `GenerationHistory` (list)
- `ScientificCapitalPolicy` (active policy version)
- `ScientificCapitalLedger.replay/2`

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:replay_determinism, context)
```

Executes `ScientificCapitalLedger.replay(histories, policy)` and verifies exact equality for all generations. Zero tolerance—no epsilon, no approximation.

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Replay Determinism Violation")`, abort execution.  
**Severity:** CRITICAL  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** If replay fails, historical records cannot be trusted. This invariant ensures that every metric is deterministically derivable from immutable evidence.

---

## INV-002: Budget Conservation

**Title:** Budget Conservation  
**Definition:** Total credits spent across all generations must not exceed initial budget allocation. Credits are conserved—they can only be transferred or spent, never created or destroyed.  
**Canonical Inputs:**
- `GenerationHistory` (list)
- Initial budget amount

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:budget_conservation, context)
```

Verifies: `Σ(credits_spent) ≤ initial_budget`

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Budget Conservation Violation")`, abort execution.  
**Severity:** CRITICAL  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** Economic integrity requires conservation laws. If credits can be created ex nihilo, the economic model is broken.

---

## INV-003: Scientific Capital Conservation

**Title:** Scientific Capital Conservation  
**Definition:** Scientific capital follows accounting identity: `Capital(G) = Capital(G-1) + ΔCapital(G)`. Capital at generation G must equal previous capital plus delta calculated from canonical transactions.  
**Canonical Inputs:**
- `GenerationHistory` (list)
- `ScientificCapitalPolicy` (active policy)
- `ScientificCapitalLedger.calculate_delta/2`

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:scientific_capital_conservation, context)
```

For each generation G:
1. Calculate expected delta from canonical transactions
2. Verify: `recorded_capital(G) == recorded_capital(G-1) + expected_delta`

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Scientific Capital Conservation Violation")`, abort execution.  
**Severity:** CRITICAL  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** Scientific capital is a constitutional ledger quantity following conservation laws. Violations indicate calculation errors or data corruption.

---

## INV-004: Research Debt Conservation

**Title:** Research Debt Conservation  
**Definition:** Research debt evolves according to: `Debt(G) = Debt(G-1) + NewUnknowns - ResolvedUnknowns`. Debt cannot become negative.  
**Canonical Inputs:**
- `GenerationHistory` (list)
- Unknown resolution counts per generation

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:research_debt_conservation, context)
```

For each generation G:
1. Track new unknowns introduced
2. Track unknowns resolved
3. Verify: `debt(G) == debt(G-1) + new_unknowns - resolved_unknowns`
4. Verify: `debt(G) ≥ 0`

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Research Debt Conservation Violation")`, abort execution.  
**Severity:** HIGH  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** Research debt represents outstanding questions. It must be tracked accurately to measure civilizational progress.

---

## INV-005: Temporal Separation

**Title:** Temporal Separation  
**Definition:** No generation may use information from future generations. Causal graph must be acyclic with edges only from past to present.  
**Canonical Inputs:**
- `CausalGraph` (dependency structure)
- `GenerationHistory` (list with timestamps)

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:temporal_separation, context)
```

Verifies:
1. All causal edges go from lower generation numbers to higher
2. No cycles exist in causal graph
3. No timestamp from generation G appears in generation G-n (n > 0)

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Temporal Separation Violation - Future Leakage Detected")`, abort execution.  
**Severity:** CRITICAL  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** Temporal causality is fundamental to scientific method. Future leakage invalidates all results.

---

## INV-006: Reward Leakage

**Title:** Reward Leakage Prevention  
**Definition:** Every reward granted must trace to canonical transaction evidence. No reward may be granted without corresponding discovery, theory formation, or unknown resolution.  
**Canonical Inputs:**
- `GenerationHistory` (list)
- Canonical transaction IDs
- Reward amounts

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:reward_leakage, context)
```

For each reward:
1. Identify reward type (discovery, theory, unknown resolution)
2. Find corresponding canonical transaction
3. Verify transaction exists and is valid
4. Verify reward amount matches policy coefficient

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Reward Leakage - Unjustified Reward Detected")`, abort execution.  
**Severity:** HIGH  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** Rewards must be earned through genuine scientific contribution. Leakage corrupts incentive structure.

---

## INV-007: Seed Independence

**Title:** Seed Independence  
**Definition:** Multi-seed trials must produce statistically consistent results. Variation between seeds should be within expected bounds, indicating results are not RNG artifacts.  
**Canonical Inputs:**
- `MultiSeedTrialResults` (list of trial outcomes per seed)
- Statistical significance threshold (default: p < 0.05)

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:seed_independence, context)
```

Performs:
1. Calculate mean and variance across seeds
2. Perform ANOVA or chi-squared test
3. Verify p-value exceeds significance threshold
4. Flag seeds producing outlier results

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Seed Independence Violation - Results May Be RNG Artifacts")`, abort execution.  
**Severity:** MEDIUM  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** Scientific results must be reproducible across different random seeds. Seed dependence indicates fragility.

---

## INV-008: Metric Independence

**Title:** Metric Independence  
**Definition:** No metric may be circularly defined in terms of itself or metrics that depend on it. Metric dependency graph must be acyclic.  
**Canonical Inputs:**
- `MetricDependencyGraph` (defines how metrics are computed)

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:metric_independence, context)
```

Verifies:
1. Build directed graph of metric dependencies
2. Detect cycles using topological sort
3. Ensure no metric depends on itself (directly or indirectly)

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Metric Independence Violation - Circular Dependency Detected")`, abort execution.  
**Severity:** HIGH  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** Circular metrics create self-confirming illusions of progress. Independence ensures genuine measurement.

---

## INV-009: Lifecycle Completeness

**Title:** Lifecycle Completeness  
**Definition:** Every generation must execute all required stages (Stage 1-5) in correct order. Missing stages constitute incomplete lifecycle.  
**Canonical Inputs:**
- `GenerationHistory` (with stage completion flags)
- Required stage list: [:stage1, :stage2, :stage3, :stage4, :stage5]

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:lifecycle_completeness, context)
```

For each generation:
1. Check all 5 stages executed
2. Verify execution order: Stage1 → Stage2 → Stage3 → Stage4 → Stage5
3. Calculate lifecycle completeness percentage

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Lifecycle Completeness Violation - Missing Stages")`, abort execution.  
**Severity:** HIGH  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** Partial execution produces incomplete scientific output. All stages are required for valid generation.

---

## INV-010: Rollback Completeness

**Title:** Rollback Completeness  
**Definition:** When rollback occurs, system state must fully revert to previous generation. Partial rollbacks leave corrupted state.  
**Canonical Inputs:**
- `GenerationHistory` (list with rollback flags)
- Rollback frequency threshold (default: < 10%)

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:rollback_completeness, context)
```

Verifies:
1. Rollback frequency below threshold
2. After rollback, state matches pre-adaptation state exactly
3. No residual effects from rejected adaptations

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Rollback Completeness Violation - Incomplete Reversion")`, abort execution.  
**Severity:** MEDIUM  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** Incomplete rollbacks leave system in inconsistent state. Full reversion is required for stability.

---

## INV-011: Policy Hash Integrity

**Title:** Policy Hash Integrity  
**Definition:** Active policy hash must match hash recorded in GenerationHistory. Any mismatch indicates policy drift or tampering.  
**Canonical Inputs:**
- `GenerationHistory.policy_hash`
- `ScientificCapitalPolicy.policy_hash`

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:policy_hash_integrity, context)
```

Verifies: `recorded_policy_hash == current_policy_hash`

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Policy Hash Integrity Violation - Policy Drift Detected")`, abort execution.  
**Severity:** CRITICAL  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** Policy changes must be governance-controlled. Unauthorized modifications invalidate all calculations.

---

## INV-012: Definition Hash Integrity

**Title:** Definition Hash Integrity  
**Definition:** ScientificCapitalDefinition hash must remain constant across generations unless explicitly updated through governance process.  
**Canonical Inputs:**
- `GenerationHistory.definition_hash`
- Current definition hash (computed)

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:definition_hash_integrity, context)
```

Verifies: `recorded_definition_hash == computed_definition_hash`

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Definition Hash Integrity Violation - Definition Changed Without Governance")`, abort execution.  
**Severity:** CRITICAL  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** What counts as scientific capital is constitutionally defined. Changes require governance approval.

---

## INV-013: Ledger Hash Integrity

**Title:** Ledger Hash Integrity  
**Definition:** ScientificCapitalLedger implementation hash must remain constant. Calculation logic cannot change without governance approval.  
**Canonical Inputs:**
- `GenerationHistory.ledger_hash`
- Current ledger hash (computed)

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:ledger_hash_integrity, context)
```

Verifies: `recorded_ledger_hash == computed_ledger_hash`

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Ledger Hash Integrity Violation - Ledger Implementation Changed")`, abort execution.  
**Severity:** CRITICAL  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** How capital is calculated is constitutionally fixed. Implementation changes invalidate historical replay.

---

## INV-014: Constitution Hash Consistency

**Title:** Constitution Hash Consistency  
**Definition:** Combined constitution hash (Definition + Policy + Ledger + Invariant Registry) must be consistent across all components.  
**Canonical Inputs:**
- `GenerationHistory.constitution_hash`
- Computed constitution hash

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:constitution_hash_consistency, context)
```

Computes: `SHA256(definition_hash + policy_hash + ledger_hash + invariant_hash)`  
Verifies: `computed_constitution_hash == recorded_constitution_hash`

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Constitution Hash Consistency Violation - Constitutional Artifacts Inconsistent")`, abort execution.  
**Severity:** CRITICAL  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** The constitution is a unified whole. Inconsistencies indicate partial updates or corruption.

---

## INV-015: Metric Provenance Completeness

**Title:** Metric Provenance Completeness  
**Definition:** Every metric must have complete causal chain terminating at ResearchEpisode. Orphaned metrics violate constitutional explainability.  
**Canonical Inputs:**
- `GenerationHistory`
- `MetricProvenanceResolver.explain_metric/2`

**Validation Method:**
```elixir
ConstitutionalInvariantRegistry.execute(:metric_provenance_completeness, context)
```

For each metric:
1. Call `MetricProvenanceResolver.explain_metric(metric, history)`
2. Verify provenance chain reaches ResearchEpisode
3. Verify all intermediate steps reference canonical transactions

**Failure Action:** Freeze adaptation, raise `ConstitutionalViolation(reason: "Metric Provenance Completeness Violation - Orphaned Metric Detected")`, abort execution.  
**Severity:** HIGH  
**Version:** 1.0  
**Introduced In Phase:** Phase 13.5B  

**Rationale:** Every metric must be explainable through immutable evidence. Opaque calculations are constitutionally forbidden.

---

## Execution Protocol

All invariants are executed through `ConstitutionalInvariantRegistry.execute/2`:

```elixir
case ConstitutionalInvariantRegistry.execute(:replay_determinism, context) do
  {:ok, result} -> proceed()
  {:error, violation} -> handle_violation(violation)
end
```

No module may implement invariant logic locally. All validation delegates to the registry.

---

## Amendment Process

These invariants are **FROZEN**. Amendments require:

1. Proposal through governance process
2. Approval by constitutional authority
3. Version increment in registry
4. Migration plan for existing generations
5. Update this document with new version

---

## Verification Status

All invariants verified as of 2026-06-13:

- ✅ INV-001 through INV-015 registered in ConstitutionalInvariantRegistry
- ✅ All invariants executable via registry API
- ✅ StructuralValidationGate executes all invariants before simulation
- ✅ ConstitutionalExecutor enforces mandatory invariant validation

**Next Steps:** Proceed to statistical validation (Phase 13.5C) only after all invariants pass consistently.

---

**End of Constitutional Invariants Document**
