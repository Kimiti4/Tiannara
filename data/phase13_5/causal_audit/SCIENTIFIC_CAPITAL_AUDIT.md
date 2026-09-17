# Scientific Capital Audit - Phase 13.5A.3 Part 1

**Date**: 2026-06-30T18:30:00Z
**Purpose**: Identify all assignments to scientific_capital and classify constitutional validity
**Auditor**: TiannaraOS.CausalValidator

---

## Executive Summary

Scientific Capital is currently implemented as a **computed score with stochastic variation**, not as a **conserved constitutional quantity**. This violates fundamental accounting principles and makes it unsuitable as a primary outcome variable for statistical validation.

---

## Assignment Inventory

### Assignment 1: Direct Calculation with Random Variation

**Location**: `lib/tiannara/os/recursive_civilization_runner.ex:350`

**Function**: `collect_generation_metrics/3`

**Code**:
```elixir
base_capital = data.theories_formed * 100 + data.unknowns_resolved * 50 + adaptations_adopted * 200

# Add seed-driven variation (±10%)
variation_factor = 0.9 + (:rand.uniform() * 0.2)  # Range: 0.9 to 1.1
scientific_capital = Float.round(base_capital * variation_factor, 2)
```

**Inputs**:
- `data.theories_formed` (integer) - Count of theories formed in generation G
- `data.unknowns_resolved` (integer) - Count of unknowns resolved in generation G
- `adaptations_adopted` (integer) - Count of adaptations adopted in generation G
- `:rand.uniform()` (float) - Random number generator

**Classification**: ❌ **INVALID**

**Violations**:
1. **Stochastic variation applied directly to capital** - The `variation_factor` multiplier introduces randomness that is not derived from canonical transactions
2. **Capital can decrease arbitrarily** - When `variation_factor < 1.0`, capital decreases even if discoveries/theories increased
3. **Not reproducible from history** - Cannot reconstruct capital from GenerationHistory alone because random factor is lost
4. **Violates conservation law** - `Capital(G+1) != Capital(G) + Validated Discoveries + Validated Theories` due to random factor

**Root Cause**: Attempting to create seed-driven variation by applying randomness to the final metric instead of to the underlying episode production process.

---

### Assignment 2: Cumulative Accumulation Across Generations

**Location**: `lib/tiannara/os/recursive_civilization_runner.ex:200`

**Function**: `execute/2` (main execution loop)

**Code**:
```elixir
updated_state = %{
  adapted_state |
  scientific_capital: adapted_state.scientific_capital + history.scientific_capital,
  ...
}
```

**Inputs**:
- `adapted_state.scientific_capital` (float) - Cumulative capital from previous generations
- `history.scientific_capital` (float) - Per-generation capital from current generation

**Classification**: ⚠️ **QUESTIONABLE**

**Analysis**:
This accumulates scientific capital across generations, treating it as a running total rather than a per-generation conserved quantity.

**Issues**:
1. **Ambiguous semantics** - Is scientific capital meant to be cumulative (like total wealth) or per-generation (like annual GDP)?
2. **Conservation equation unclear** - If cumulative, then `Capital(G) = Σ(Capital_per_gen)` but this doesn't match the conservation audit expectation
3. **Makes conservation verification difficult** - The CausalValidator expects per-generation conservation, not cumulative tracking

**Recommendation**: Clarify whether scientific capital should be:
- **Option A**: Per-generation conserved quantity (like annual scientific production)
- **Option B**: Cumulative conserved quantity (like total accumulated knowledge)

Based on constitutional principles, **Option B** appears more appropriate - scientific capital should represent the civilization's total accumulated validated knowledge, which naturally grows over time.

---

## Constitutional Violations Summary

| Violation Type | Count | Severity |
|----------------|-------|----------|
| Stochastic variation on capital | 1 | 🔴 Critical |
| Arbitrary capital decrease | 1 | 🔴 Critical |
| Non-reproducible from history | 1 | 🟡 High |
| Conservation law violation | 1 | 🔴 Critical |
| Ambiguous accumulation semantics | 1 | 🟡 High |

**Total Violations**: 5
**Critical Violations**: 3
**High Severity**: 2

---

## Required Fixes

### Fix 1: Remove Stochastic Variation

**Current**:
```elixir
variation_factor = 0.9 + (:rand.uniform() * 0.2)
scientific_capital = Float.round(base_capital * variation_factor, 2)
```

**Should Be**:
```elixir
scientific_capital = base_capital  # No variation factor
```

**Rationale**: Randomness belongs in episode generation, theory formation, and validation - NOT in capital calculation. Capital must be deterministic given the same canonical transactions.

---

### Fix 2: Define Fixed Constitutional Coefficients

**Current**:
```elixir
base_capital = data.theories_formed * 100 + data.unknowns_resolved * 50 + adaptations_adopted * 200
```

**Should Be** (constitutional constants):
```elixir
@discovery_value 100      # Each validated discovery contributes 100 capital
@theory_value 40          # Each validated theory contributes 40 capital
@law_value 150            # Each validated law contributes 150 capital
@application_value 25     # Each operational application contributes 25 capital

scientific_capital = 
  discoveries_made * @discovery_value +
  theories_formed * @theory_value +
  laws_validated * @law_value +
  applications_deployed * @application_value
```

**Rationale**: Coefficients become frozen constitutional constants, never dependent on generation, seed, adaptation mode, or simulation state.

---

### Fix 3: Clarify Accumulation Semantics

**Decision Needed**: Should scientific capital be:
- **Per-generation**: Reset each generation, represents scientific production rate
- **Cumulative**: Grows monotonically, represents total accumulated knowledge

**Recommendation**: **Cumulative** - This aligns with the concept of "scientific capital" as accumulated knowledge stock, analogous to financial capital or physical energy.

If cumulative, the conservation equation becomes:
```
Capital(G) = Capital(G-1) + ΔCapital(G)
where ΔCapital(G) = discoveries*100 + theories*40 + laws*150 + applications*25
```

---

### Fix 4: Ensure Reproducibility

Every increase in scientific capital must reference specific canonical transaction IDs so that:
```
Replay(GenerationHistory[1..G]) == Recorded_Capital(G)
```

This requires storing transaction provenance alongside capital values.

---

## Next Steps

1. **Freeze constitutional definition** with fixed coefficients (Part 2)
2. **Remove all illegal influences** (variation_factor, random_bonus, etc.) (Part 3)
3. **Move variation to episode production** where randomness belongs (Part 4)
4. **Implement ScientificCapitalValidator** to enforce conservation (Part 6)
5. **Historical replay verification** to prove reproducibility (Part 7)

---

**Audit Conducted By**: TiannaraOS.CausalValidator
**Constitutional Compliance**: ❌ FAIL - Multiple critical violations detected
**Next Phase**: Phase 13.5A.3 Part 2 - Freeze Constitutional Definition
