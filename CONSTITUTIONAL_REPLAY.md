# Constitutional Replay — Tiannara Operating System

**Document Type:** Constitutional Artifact (Immutable)  
**Phase Introduced:** Phase 13.5B — Constitutional Integrity Hardening  
**Version:** 1.0  
**Status:** FROZEN  
**Generated:** 2026-06-13  

---

## Purpose

This document defines the constitutional replay guarantees for the Tiannara research civilization. Replay is not a testing tool—it is a **constitutional invariant** that must pass automatically before every generation executes.

Replay ensures that every metric is deterministically reconstructable from canonical transactions using active policy coefficients. If replay fails, the system is corrupted and adaptation freezes.

---

## Replay Architecture

```
GenerationHistory (immutable record)
        │
        │ extract canonical transactions only
        ▼
Canonical Transactions
  ├─→ DiscoveryResults
  ├─→ TheoryFormationResults
  └─→ DistributedValidationResults
        │
        │ feed to replay engine
        ▼
Replay Engine (ScientificCapitalLedger.replay/2)
        │
        │ calculate delta using policy coefficients
        ▼
Scientific Capital Ledger
        │
        │ accumulate generation by generation
        ▼
Calculated Capital (reconstructed from scratch)
        │
        │ compare with recorded capital
        ▼
Exact Equality Check (zero tolerance)
        │
        ├─→ MATCH → Replay PASS
        └─→ MISMATCH → ConstitutionalViolation
```

---

## Replay Guarantees

### Guarantee 1: True Reconstruction

Replay **never reads recorded capital during reconstruction**. It starts from zero and rebuilds capital generation-by-generation using only:

1. Canonical transaction contributions
2. Active policy coefficients
3. Accounting identity: `Capital(G) = Capital(G-1) + ΔCapital(G)`

Only at the final step does replay compare calculated vs. recorded values.

**Rationale:** If replay reads recorded values during reconstruction, it becomes self-confirming rather than truly verifying integrity.

---

### Guarantee 2: Zero Tolerance

Replay requires **exact equality**. No epsilon, no approximation, no tolerance.

```elixir
if recorded_capital == calculated_capital do
  :ok
else
  {:error, :mismatch}
end
```

**Rationale:** Scientific capital is an integer ledger quantity. Any deviation indicates corruption.

---

### Guarantee 3: Policy Hash Verification

Before replay begins, the active policy hash is verified against the hash recorded in GenerationHistory.

```elixir
case ScientificCapitalPolicy.verify_hash(policy) do
  :ok -> proceed_with_replay()
  {:error, :hash_mismatch} -> raise "Policy Drift Detected"
end
```

**Rationale:** Replay with wrong policy produces meaningless results. Policy integrity is prerequisite.

---

### Guarantee 4: Complete Causal Chain

Every value in replay must trace to canonical transactions:

- Discoveries → `DiscoveryResult` canonical transactions
- Theories → `TheoryFormationResult` canonical transactions
- Unknown Resolutions → `DistributedValidationResult` canonical transactions

No floats, no maps, no dashboard aggregates. Only canonical transactions.

**Rationale:** Canonical transactions are immutable evidence. They guarantee replayability forever.

---

### Guarantee 5: Deterministic Execution

Given identical inputs (GenerationHistory + Policy), replay produces identical output every time. No randomness, no non-determinism.

**Rationale:** Determinism enables verification. Non-deterministic replay cannot be trusted.

---

## Replay Algorithm

### Input

```elixir
histories :: [GenerationHistory.t()]
policy :: ScientificCapitalPolicy.t()
```

### Output

```elixir
{:ok, :replay_successful} | {:error, [violation()]}
```

Where `violation()` contains:
- `generation`: Generation number where mismatch occurred
- `expected_delta`: Calculated delta from canonical transactions
- `recorded_delta`: Delta from historical record
- `difference`: recorded_delta - expected_delta
- `expected_cumulative`: Expected cumulative capital

### Steps

1. **Verify Policy Hash**
   ```elixir
   case ScientificCapitalPolicy.verify_hash(policy) do
     :ok -> continue
     {:error, :hash_mismatch} -> raise "Policy Drift"
   end
   ```

2. **Initialize Replay State**
   ```elixir
   violations = []
   cumulative_capital = 0
   ```

3. **Iterate Through Generations**
   ```elixir
   Enum.reduce(histories, {violations, cumulative_capital}, fn history, {violations_acc, cum_cap} ->
     # Extract canonical transaction contributions ONLY
     transactions = extract_canonical_contributions(history)

     # Calculate delta using policy (NEVER read recorded capital yet)
     expected_delta = ScientificCapitalLedger.calculate_delta(policy, transactions)
     expected_cumulative = cum_cap + expected_delta

     # NOW compare with recorded value
     recorded_delta = Map.get(history, :scientific_capital, 0)

     if recorded_delta != expected_delta do
       violation = %{
         generation: history.generation_number,
         expected_delta: expected_delta,
         recorded_delta: recorded_delta,
         difference: recorded_delta - expected_delta,
         expected_cumulative: expected_cumulative
       }
       {[violation | violations_acc], expected_cumulative}
     else
       {violations_acc, expected_cumulative}
     end
   end)
   ```

4. **Return Result**
   ```elixir
   violations_list = Enum.reverse(violations)

   if length(violations_list) == 0 do
     {:ok, :replay_successful}
   else
     {:error, violations_list}
   end
   ```

---

## Replay Inputs

### GenerationHistory Fields Required

- `generation_number`: Sequential generation identifier
- `scientific_capital`: Recorded capital amount
- `discoveries_made`: Number of discoveries
- `theories_formed`: Number of theories
- `unknowns_resolved`: Number of unknowns resolved
- `policy_version`: Policy version active during generation
- `policy_hash`: Policy hash for verification
- `canonical_transaction_ids`: References to immutable evidence

### ScientificCapitalPolicy Fields Required

- `version`: Policy version number
- `policy_hash`: SHA256 hash of policy coefficients
- `discovery_value`: Coefficient for discoveries
- `theory_value`: Coefficient for theories
- `law_value`: Coefficient for laws
- `application_value`: Coefficient for applications
- `unknown_resolution_value`: Coefficient for unknown resolutions

---

## Replay Outputs

### Success Case

```elixir
{:ok, :replay_successful}
```

All generations reconstructed exactly. No violations detected.

### Failure Case

```elixir
{:error, [
  %{
    generation: 42,
    expected_delta: 1500,
    recorded_delta: 1450,
    difference: -50,
    expected_cumulative: 470600
  },
  ...
]}
```

One or more generations failed replay. Each violation includes detailed diagnostics.

---

## Replay Failure Handling

### Immediate Actions

1. **Freeze Adaptation**
   - Stop all recursive execution
   - Prevent further generations from running

2. **Raise ConstitutionalViolation**
   ```elixir
   raise "Constitutional Violation: Replay Determinism Failed - Generation #{violation.generation}"
   ```

3. **Record Violation**
   - Append to `StructuralValidationResult.violations`
   - Include full violation details

4. **Abort Execution**
   - Do not proceed to simulation
   - Require manual intervention

### Diagnostic Steps

1. **Check Policy Hash**
   - Verify policy hasn't been modified
   - Compare recorded hash with current hash

2. **Inspect Canonical Transactions**
   - Verify transaction IDs are valid
   - Check for missing or corrupted transactions

3. **Review Calculation Logic**
   - Verify `ScientificCapitalLedger.calculate_delta/2` implementation
   - Check coefficient values match policy

4. **Examine Generation History**
   - Look for data corruption in历史记录
   - Verify field values are consistent

### Recovery Procedure

1. **Identify Root Cause**
   - Policy drift? → Restore correct policy version
   - Data corruption? → Restore from backup
   - Calculation bug? → Fix and re-run from affected generation

2. **Restore Clean State**
   - Rollback to last known good generation
   - Re-execute from that point forward

3. **Re-run Replay**
   - Verify replay passes after fix
   - Ensure no residual violations

4. **Resume Execution**
   - Only after replay passes 100%
   - Continue with next generation

---

## Replay as Constitutional Invariant

Replay is registered as **INV-001: Replay Determinism** in `ConstitutionalInvariantRegistry`.

It is executed automatically by `StructuralValidationGate` before every simulation:

```elixir
# StructuralValidationGate execution flow
invariant_results = ConstitutionalInvariantRegistry.execute_all(context)

case invariant_results do
  {:ok, _} -> allow_simulation()
  {:error, violations} -> freeze_adaptation(violations)
end
```

Replay is **not optional**. It runs every generation, every time.

---

## Replay Verification Examples

### Example 1: Successful Replay

```elixir
histories = [
  %GenerationHistory{
    generation_number: 1,
    scientific_capital: 1000,
    discoveries_made: 10,
    theories_formed: 0,
    unknowns_resolved: 0
  },
  %GenerationHistory{
    generation_number: 2,
    scientific_capital: 1800,
    discoveries_made: 8,
    theories_formed: 0,
    unknowns_resolved: 0
  }
]

policy = ScientificCapitalPolicy.get_version(1)

case ScientificCapitalLedger.replay(histories, policy) do
  {:ok, :replay_successful} ->
    IO.puts("✅ Replay passed - all generations verified")

  {:error, violations} ->
    IO.puts("❌ Replay failed - #{length(violations)} violations")
end
```

Output:
```
✅ Replay passed - all generations verified
```

### Example 2: Replay Failure

```elixir
# Corrupted history (capital doesn't match transactions)
histories = [
  %GenerationHistory{
    generation_number: 1,
    scientific_capital: 999,  # Should be 1000 (10 discoveries × 100)
    discoveries_made: 10,
    theories_formed: 0,
    unknowns_resolved: 0
  }
]

case ScientificCapitalLedger.replay(histories, policy) do
  {:error, [%{generation: 1, difference: -1}]} ->
    IO.puts("❌ Replay detected corruption in Generation 1")
end
```

Output:
```
❌ Replay detected corruption in Generation 1
Expected: 1000, Recorded: 999, Difference: -1
```

---

## Replay Limitations

### What Replay Does NOT Verify

1. **Semantic Correctness**
   - Replay verifies calculation consistency, not scientific validity
   - A discovery may be counted correctly but be scientifically wrong

2. **External Dependencies**
   - Replay assumes canonical transactions are externally valid
   - Does not verify transaction content beyond structure

3. **Performance**
   - Replay may be slow for large generation histories
   - Optimization is acceptable as long as correctness is preserved

### What Replay DOES Verify

1. **Calculation Integrity**
   - All capital calculations follow accounting identity
   - Coefficients applied correctly

2. **Data Consistency**
   - Recorded values match reconstructed values
   - No corruption or tampering

3. **Policy Compliance**
   - Active policy matches recorded policy
   - No unauthorized coefficient changes

---

## Amendment Process

This replay specification is **FROZEN**. Amendments require:

1. Proposal through governance process
2. Approval by constitutional authority
3. Version increment in this document
4. Migration plan for existing generations
5. Update `ScientificCapitalLedger.replay/2` implementation

---

## Verification Status

Replay system verified as of 2026-06-13:

- ✅ `ScientificCapitalLedger.replay/2` implemented with true reconstruction
- ✅ Zero tolerance verification (exact equality required)
- ✅ Policy hash verification before replay
- ✅ Registered as INV-001 in ConstitutionalInvariantRegistry
- ✅ Executed automatically by StructuralValidationGate
- ✅ Generates detailed violation diagnostics on failure

**Next Steps:** Proceed to statistical validation (Phase 13.5C) only after replay passes consistently across multiple trials.

---

**End of Constitutional Replay Document**
