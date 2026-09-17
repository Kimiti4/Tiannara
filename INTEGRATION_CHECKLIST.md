# Quick Integration Checklist - Tiannara Meta-Governance Systems

## Phase 2 Integration (Next Immediate Steps)

### Step 1: Add to Application Supervision Tree

```elixir
# file: lib/tiannara/application.ex
# Add these to children list in order:

children = [
  # ... existing children ...

  # Meta-governance foundation (START FIRST)
  Tiannara.MSG.Supervisor,           # Must start before all stabilizers
  Tiannara.IRD.Supervisor,           # Depends on MSG

  # Meaning & continuity preservation
  Tiannara.OMCS.ContinuityIndex,     # Lightweight, independent
  Tiannara.EUF.Supervisor,           # Observer consensus tracking

  # Constitution enforcement
  Tiannara.Constitution.Enforcer,    # Validation layer

  # Existing stabilizers (wire to MSG/IRD)
  # Tiannara.Stabilization.HSV,
  # Tiannara.Stabilization.CTL,
  # ... etc
]
```

### Step 2: Wire MSG Callbacks into Stabilizers

For each stabilizer (HSV, CTL, NDE, OSL, RRG, TWP):

```elixir
# Before stabilizer fires intervention:
Tiannara.MSG.propose_intervention(module_name, action, intensity)

# Example in HSV:
def handle_cast({:trigger_horizon_spawn, intensity}, state) do
  # Notify MSG
  Tiannara.MSG.propose_intervention(:hsv, :spawn_horizon, intensity)

  # Check IRD clearance
  case Tiannara.IRD.propose_intervention(:hsv, :spawn_horizon, intensity) do
    {:approved, _cost} ->
      # Continue with spawn
      spawn_horizon(state)
    {:denied, _cost} ->
      Logger.info("HSV: Intervention deferred by IRD")
  end
end
```

### Step 3: Wire OMCS into Reintegration System

```elixir
# In reintegration module:
def reintegrate_civilization(civ_id, civ_state) do
  # Before reintegration: create anchor
  anchor_id = Tiannara.OMCS.ContinuityIndex.create_continuity_anchor(civ_id, "pre_reintegration")

  # Perform reintegration
  result = do_reintegration(civ_id, civ_state)

  # After reintegration: verify continuity
  case Tiannara.OMCS.ContinuityIndex.verify_identity_continuity(civ_id) do
    {:ok, %{continuity_score: score}} when score > 0.8 ->
      Logger.info("✅ OMCS: Reintegration successful (score: #{Float.round(score, 3)})")
      {:ok, result}
    {:ok, report} ->
      Logger.warning("⚠️  OMCS: Low continuity score: #{inspect(report)}")
      {:partial, result}
    {:error, reason} ->
      Logger.error("❌ OMCS: Continuity verification failed: #{reason}")
      {:error, reason}
  end
end
```

### Step 4: Wire EUF into Observer Systems

```elixir
# When observer generates theory:
def register_observer_theory(observer_id, theory_id, theory_spec) do
  # Register ontology (if new)
  ontology_id = theory_spec.ontology_id
  case Tiannara.EUF.Supervisor.register_ontology(ontology_id, theory_spec.concepts) do
    :ok -> :ok
    {:already_registered, _} -> :ok
  end

  # Track observer confidence
  Enum.each(theory_spec.concepts, fn concept ->
    confidence = observer_id.confidence_in(concept)
    Tiannara.EUF.Supervisor.record_observer_belief(observer_id, concept, confidence)
  end)
end

# When observer consensus diverges:
def detect_observer_disagreement(concept_id, observer_votes) do
  confidences = Enum.map(observer_votes, fn {_observer, conf} -> conf end)
  variance = calculate_variance(confidences)

  if variance > 0.3 do
    severity = variance
    Tiannara.EUF.Supervisor.detect_contradiction(
      concept_id,
      "consensus_divergence",
      severity
    )
  end
end
```

### Step 5: Wrap State Changes with Constitution Validation

```elixir
# In critical state change points:
def apply_critical_operation(operation, state) do
  # Perform operation
  new_state = perform_op(operation, state)

  # Validate against constitutional laws
  case Tiannara.Constitution.Enforcer.validate_state(new_state) do
    :valid ->
      {:ok, new_state}

    {:critical_violation, violations} ->
      Logger.error("❌ CONSTITUTION VIOLATION: #{inspect(violations)}")
      {:rollback, state}  # Rollback to previous state

    {:valid, violations} ->
      Logger.warning("⚠️  Constitutional violations detected (non-critical)")
      {:partial, new_state}
  end
end
```

### Step 6: Start REL, Temporal Decay, RSME (Phase 2 Completion)

```elixir
# In application.ex children (after core meta-governance):
Tiannara.REL.EconomyManager,       # Resource allocation
Tiannara.TemporalDecay.HistoryManager,  # History management
Tiannara.RSME.Supervisor,          # Runtime self-modeling
```

## Testing During Integration

### Quick Validation Tests

```bash
# Test MSG overregulation detection
iex> Tiannara.MSG.propose_intervention(:hsv, :spawn, 0.8)
iex> Tiannara.MSG.propose_intervention(:ctl, :freeze, 0.7)
iex> Tiannara.MSG.propose_intervention(:nde, :novelty, 0.9)
iex> score = Tiannara.MSG.get_overregulation_score()
# Should see warning if score > 0.75

# Test IRD interference detection
iex> Tiannara.IRD.propose_intervention(:hsv, :spawn, 10.0)
iex> Tiannara.IRD.propose_intervention(:ctl, :freeze, 10.0)
iex> Tiannara.IRD.propose_intervention(:nde, :novelty, 10.0)
iex> interference = Tiannara.IRD.get_interference_matrix()
# Should detect high interference and trigger quiescence

# Test OMCS continuity
iex> Tiannara.OMCS.ContinuityIndex.register_civilization("civ1", initial_state)
iex> Tiannara.OMCS.ContinuityIndex.record_semantic_state("civ1", new_state)
iex> {:ok, report} = Tiannara.OMCS.ContinuityIndex.verify_identity_continuity("civ1")
# Should show high continuity_score initially

# Test EUF ontology confidence
iex> Tiannara.EUF.Supervisor.register_ontology("ont1", concepts)
iex> Tiannara.EUF.Supervisor.record_observer_belief("obs1", "concept1", 0.9)
iex> Tiannara.EUF.Supervisor.record_observer_belief("obs2", "concept1", 0.1)
iex> {:ok, conf} = Tiannara.EUF.Supervisor.get_ontology_confidence("ont1")
# Should show low confidence due to disagreement

# Test Constitution enforcement
iex> state = %{total_energy: -100, total_intensity: 50, budget_max: 100}
iex> Tiannara.Constitution.Enforcer.validate_state(state)
# Should return {:critical_violation, [...]} due to negative energy
```

## Monitoring & Observability

### Key Metrics to Track

```elixir
# MSG Health
metrics = Tiannara.MSG.get_health_metrics()
# => %{overregulation_score, immune_intensity, adaptive_activity, frequency, max_correction_loop}

# IRD Status
budget = Tiannara.IRD.get_budget_remaining()
interference = Tiannara.IRD.get_interference_matrix()

# OMCS Continuity
{:ok, report} = Tiannara.OMCS.ContinuityIndex.verify_identity_continuity(civ_id)
# => %{continuity_score, entropy, history_depth, hash_chain_valid}

# EUF Confidence
{:ok, conf} = Tiannara.EUF.Supervisor.get_ontology_confidence(ont_id)
# => %{epistemic_confidence, observer_count, concept_count}

# RSME Risk
{:ok, risk} = Tiannara.RSME.predict_collapse_risk()
# => %{collapse_risk, severity, time_to_collapse_estimate}
```

### Suggested Monitoring Dashboard

```
┌─ Tiannara Meta-Governance ────────────────────────┐
│                                                   │
│ MSG Overregulation Score: 0.23 [████░░░░]        │
│ IRD Interference Level:   0.15 [██░░░░░░]        │
│ OMCS Continuity Score:    0.91 [██████████]      │
│ EUF Ontology Confidence:  0.78 [███████░░]       │
│ RSME Collapse Risk:       0.12 [██░░░░░░]        │
│                                                   │
│ Violations: 0 | Warnings: 2 | Optimizations: 7  │
└───────────────────────────────────────────────────┘
```

## Common Integration Issues & Fixes

### Issue: MSG reports overregulation on startup

**Cause**: Multiple stabilizers triggering simultaneously during boot
**Fix**: Stagger stabilizer initialization with delays:

```elixir
Process.send_after(self(), :start_hsv, 100)
Process.send_after(self(), :start_ctl, 200)
# etc
```

### Issue: IRD hitting budget limits

**Cause**: Operations too expensive or budget_max too low
**Fix**:

- Reduce operation costs in REL: `REL.adjust_market_price(:branch_spawn, 5.0)`
- Or increase budget: Modify `config.budget_max` in IRD.Supervisor init

### Issue: OMCS shows low continuity after fold

**Cause**: Semantic state not properly tracked during fold
**Fix**: Ensure `record_semantic_state` called before AND after fold:

```elixir
OMCS.record_semantic_state(civ_id, pre_fold_state)
perform_fold(civ_id)
OMCS.record_semantic_state(civ_id, post_fold_state)
```

### Issue: Constitution violations blocking all operations

**Cause**: Strict enforcement mode enabled
**Fix**: Adjust constitution validation to non-blocking for non-critical violations:

```elixir
case Tiannara.Constitution.Enforcer.validate_state(state) do
  {:critical_violation, _} -> {:error, :blocked}
  {:valid, _} -> {:ok, state}  # Proceed even with warnings
  _partial -> {:ok, state}
end
```

## Success Criteria

✅ All systems compile without errors
✅ Application starts with all meta-governance supervisors active
✅ MSG reports overregulation < 0.5 under normal load
✅ No MSG warnings in first 10 minutes of operation
✅ IRD budget balance positive
✅ OMCS continuity score > 0.8 after reintegration
✅ EUF detects observer consensus divergence > 0.3
✅ Constitution violations = 0
✅ RSME predicts collapse risk < 0.3 under normal conditions

---

**Ready to integrate!** Start with Step 1 and work through in sequence.
