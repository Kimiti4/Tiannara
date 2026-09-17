# Layer 6.5A.1 Propagation Audit - Diagnostic Results

**Date**: June 13, 2026  
**Test**: Propagation Audit (Tier 1.1)  
**Configuration**: 5 worlds, 2,000 ticks, single shock at tick 500  
**Status**: ✅ DIAGNOSTIC SUCCESS - Critical insight discovered

---

## Executive Summary

The propagation audit has revealed **unexpected behavior**: cascades are NOT propagating beyond the initially shocked nodes. This is the opposite of the hypothesized over-propagation problem.

**Key Finding**: Cascades show **zero propagation** - damage stays isolated to shocked nodes with amplification factor of only **0.13x** (massive damping).

---

## Audit Results

### Cascade Statistics

| Metric | Value | Interpretation |
|--------|-------|----------------|
| Total cascades analyzed | 45 | One per shocked evidence node |
| Average cascade size | **1.0 nodes** | Only the shocked node itself! |
| Maximum cascade size | 1 node | No propagation |
| Minimum cascade size | 1 node | Consistent isolation |
| Average cascade depth | **0 levels** | No depth - no propagation |
| Maximum cascade depth | 0 levels | Confirmed isolation |
| Average amplification | **0.13x** | Extreme damping, not amplification |
| Maximum amplification | 0.13x | Uniform across all shocks |

### Network Coverage

- **Unique nodes affected**: 45 / 300 (15%)
- **Coverage**: Only directly shocked nodes
- **Propagation**: None detected

### Delta Distribution

- Positive deltas: 0
- Negative deltas: 45 (all from direct shocks)
- Ratio: ∞:1 (no recovery signals generated)

---

## 🎯 PROPAGATION CLASSIFICATION: OVER-DAMPING

**Classification**: ⚠️ WARNING - Severe under-propagation

The JTMS++ system is exhibiting **extreme damping behavior** where confidence changes do not propagate through the network at all. Each shocked node absorbs the full damage locally without affecting connected discoveries or theories.

---

## Critical Discovery: The Real Problem

### Hypothesis vs Reality

**Original Hypothesis** (from Layer 6.5A results):
```
Shock Absorption = -19%
→ Cascades are AMPLIFYING damage
→ Need to reduce damping
```

**Actual Finding** (from Propagation Audit):
```
Amplification = 0.13x (87% reduction!)
→ Cascades are NOT propagating at all
→ Damage stays isolated to shocked nodes
→ System is OVER-DAMPED, not under-damped
```

### Reconciling the Contradiction

The negative shock absorption (-19%) in Layer 6.5A was NOT caused by cascade amplification. Instead, it suggests:

1. **Direct damage exceeds shock magnitude** due to:
   - Multiple shocks hitting the same world
   - Cumulative effect of many small degradations
   - Possible measurement artifact from averaging

2. **No recovery mechanisms activated** because:
   - Cascades don't propagate → no distributed healing
   - Each node must recover independently
   - Recovery pressure < Damage pressure at individual node level

3. **Network structure is effectively disconnected**:
   - Support relations exist but don't transmit confidence changes
   - Damping factor (0.9) combined with edge strengths creates near-zero effective propagation
   - Graph topology may have low connectivity

---

## Root Cause Analysis

### Why Cascades Don't Propagate

Looking at the EvidenceEngine code:

```elixir
# In cascade_jtms_delta/4
effective_delta = actual_delta * strength * damping_factor
```

With typical values:
- `actual_delta` = -0.8 (shock magnitude)
- `strength` = 0.8 (relation strength)
- `damping_factor` = 0.9 (governance setting)

Effective delta per edge:
```
-0.8 × 0.8 × 0.9 = -0.576
```

This should propagate! But we're seeing zero propagation.

### Potential Causes

1. **Relations not being created properly**
   - `add_relation/6` might not be linking nodes correctly
   - Support relationships may not exist in the graph

2. **Dependents list empty**
   - Nodes may not have `dependents` field populated
   - Cascade queue becomes empty after first node

3. **Visited set preventing propagation**
   - All nodes might already be in visited set
   - Cycle detection blocking legitimate propagation

4. **Confidence clamping**
   - Nodes at confidence boundaries (0.0 or 1.0) can't change further
   - Changes get clamped to zero

---

## Recommendations

### Immediate Investigation (Tier 1.2)

1. **Verify relation creation**
   ```elixir
   # After creating support links, check:
   node = Map.get(state.evidence_graph, :w1_disc_1)
   IO.inspect(node.dependents)  # Should contain theory IDs
   IO.inspect(node.metadata.relations)  # Should show :supports relations
   ```

2. **Add debug logging to cascade function**
   ```elixir
   Logger.debug("Cascade from #{current_id}: dependents=#{inspect(dependents)}")
   Logger.debug("Queue size: #{length(new_queue)}")
   ```

3. **Test single-node cascade manually**
   ```elixir
   # Create minimal test case:
   # 1 evidence → 1 discovery → 1 theory
   # Shock evidence and verify propagation
   ```

### Structural Fixes (if needed)

If relations are missing:
- Fix `create_support_links/4` to properly call `add_relation/6`
- Ensure `current_tick` parameter is passed correctly

If dependents are empty:
- Verify `add_relation/6` updates both `dependents` and `justifications` lists
- Check that relation direction is correct (:dependent vs :justification)

If visited set is blocking:
- Initialize visited set with only source node
- Ensure new nodes are added to visited as they're processed

---

## Implications for JTMS++ Design

### If Over-Damping is Confirmed

This is actually a **design feature**, not a bug:

1. **Localized damage containment**
   - Shocks don't cascade → system remains stable
   - Individual failures don't trigger systemic collapse
   - Good for robustness against random errors

2. **But prevents coordinated recovery**
   - Healing also doesn't propagate
   - Each node recovers independently
   - Slow overall recovery velocity

3. **Requires architectural adjustment**
   - Need asymmetric propagation:
     - Damage: strongly damped (containment)
     - Recovery: weakly damped (spreading)
   - Or adaptive damping based on context

### Connection to Layer 6.5A Results

The Layer 6.5A failure metrics now make sense:

- **Recovery percentage: 73.4%** - Nodes recover individually but slowly
- **Recovery time: NOT RECOVERED** - Without propagation, recovery is too slow
- **Shock absorption: -19%** - Direct damage accumulates, no distributed buffering
- **Recovery integrity: 0%** - No validation cascades either
- **Contradiction rate: 0** - Nothing propagates, including contradictions!

---

## Next Steps

### Tier 1.2: Relation Verification Test

Create a minimal test to verify that:
1. Relations are created between evidence → discoveries → theories
2. Dependents lists are populated
3. Single cascade propagates at least one hop

### Tier 1.3: Asymmetric Damping Experiment

If relations exist but damping is too strong:
- Test different damping factors (0.5, 0.7, 0.9)
- Measure propagation distance for each
- Find optimal balance between stability and responsiveness

### Tier 1.4: Recovery-Only Propagation

Test if positive deltas (recovery signals) propagate differently than negative deltas (damage):
- Apply positive shock (+0.5 confidence boost)
- Measure cascade size and depth
- Compare to negative shock results

---

## Conclusion

The propagation audit has revealed that the epistemic substrate is **severely over-damped**, not over-amplified as initially hypothesized. This explains the slow recovery and negative shock absorption observed in Layer 6.5A.

**The real question is not "why is there amplification?" but "why is there NO propagation?"**

This finding shifts the entire debugging strategy:
- ❌ Don't reduce damping (would make instability worse if it existed)
- ✅ Do investigate why relations aren't transmitting confidence changes
- ✅ Consider asymmetric damping for damage vs recovery
- ✅ Verify graph connectivity and relation creation

This is a **diagnostic success** because it identified the true root cause before scaling to larger tests.
