# Run 16 Integration Guide — Technological Ecology Instrumentation

**Date:** June 24, 2026  
**Objective:** Integrate lock-free ecology tracking and profiling into Tiannara simulation  
**Status:** Implementation Phase  

---

## Executive Summary

Run 16 instruments the Tiannara simulation to characterize **technological ecology** — the birth/death dynamics, half-life, diversity, and lineage turnover of capability species. This is the final scientific characterization before advancing to Phase 7 (OED - Ontological Evolution).

### Key Architectural Decision

**Lock-free ETS + Telemetry** instead of centralized GenServer aggregation:
- Worker processes update shared ETS tables concurrently via `write_concurrency: true`
- No message passing bottlenecks at 1.5M+ capability nodes
- Profiling data accumulates in ETS without blocking simulation tick

---

## Modules Created

### 1. Tiannara.Ecology (`lib/tiannara/ecology.ex`)

**Purpose:** Track capability births, deaths, half-life, Shannon diversity, lineage turnover

**ETS Tables:**
- `:eco_lineages` — Lineage sizes (lineage_id → count)
- `:eco_births` — Individual lifespans (cap_id → {birth_tick, lineage_id})
- `:eco_stats` — Aggregated counters (total births, deaths, lifespan sums)

**Worker API (called from capability graph):**
```elixir
Tiannara.Ecology.record_birth(cap_id, lineage_id, tick)
Tiannara.Ecology.record_death(cap_id, tick)
Tiannara.Ecology.tick()
```

**Supervisor API (called every 5k ticks):**
```elixir
Tiannara.Ecology.print_ecology_report()
```

**Output Example:**
```
================================================================================
🌍 TECHNOLOGICAL ECOLOGY @ Tick 50000
================================================================================

📊 Population Dynamics:
   Birth Rate:            1234.56 / 1k ticks
   Extinction Rate:       987.65 / 1k ticks
   Net Growth:            246.91 / 1k ticks

🧬 Evolutionary Health:
   Average Half-Life:     15234.7 ticks
   Shannon Diversity:     3.456
   Lineage Turnover:      0.234

🌐 Ecosystem State:
   Total Active Species:  1234567
   Extinct Species:       345678
   Survival Rate:         78.1%

🎯 Technology Health:
   ✅ Stable ecosystem with healthy turnover
   ✅ High lineage diversity maintained
   ✅ Competitive replacement occurring
================================================================================
```

---

### 2. Tiannara.Profiling (`lib/tiannara/profiling.ex`)

**Purpose:** Aggregate timing data from worker processes without centralized bottleneck

**ETS Table:**
- `:profiler_stats` — Accumulated durations and call counts per phase ({phase, :duration} → microseconds, {phase, :count} → integer)

**Telemetry Attachment:**
```elixir
:telemetry.attach("tiannara-profiler", [:tiannara, :profile, :_], &handle_event/4, nil)
```

**Worker API (wrap timed operations):**
```elixir
result = Tiannara.Profiling.profile(:portfolio_valuation, fn ->
  valuate_all_portfolios(state)
end)
```

**Supervisor API (periodic reports):**
```elixir
Tiannara.Profiling.print_economic_profile()      # Every 5k ticks
Tiannara.Profiling.print_registration_profile()  # Every 10k ticks
```

**Output Example (Economic Profile):**
```
================================================================================
📊 Economic Profile
================================================================================
   Portfolio Valuation          35.2%  (15234.56ms / 5000 calls) ← DOMINANT
   Resource Allocation          28.7%  (12345.67ms / 5000 calls)
   Need Matching                18.4%  (7890.12ms / 5000 calls)
   Mortality Selection          12.3%  (5234.89ms / 5000 calls)
   Capacity Calculation          5.4%  (2345.67ms / 5000 calls)

   Total Time: 43050.91ms
   Dominant Bottleneck: Portfolio valuation
================================================================================
```

**Output Example (Registration Profile):**
```
================================================================================
📊 Registration Profile
================================================================================
   Mutation                     42.1%  (3456.78ms / 10000 calls) ← DOMINANT
   Synthesis                    23.5%  (1923.45ms / 10000 calls)
   Node Creation                18.9%  (1545.67ms / 10000 calls)
   Fitness Updates               9.8%  (801.23ms / 10000 calls)
   Dependency Linking            5.7%  (467.89ms / 10000 calls)

   Total Time: 8195.02ms
   Dominant Bottleneck: Mutation
================================================================================
```

---

## Integration Steps

### Step 1: Initialize Modules at Startup

Add to your application supervisor or campaign runner:

```elixir
def start_campaign do
  # Initialize lock-free instrumentation
  Tiannara.Ecology.init_tables()
  Tiannara.Profiling.init_profiler()
  
  # ... rest of campaign setup
end
```

---

### Step 2: Add Ecology Tick Counter

In `CivilizationScheduler.run_simulation/3`, inside the tick loop:

```elixir
Enum.reduce(1..max_ticks, initial_state, fn tick, acc_state ->
  # Increment ecology tick counter (every tick)
  Tiannara.Ecology.tick()
  
  # ... rest of simulation logic
end)
```

---

### Step 3: Instrument Capability Registration

Find where capabilities are created (likely in `CapabilityRegistry` or discovery registration):

```elixir
def register_capability(discovery, state, tick) do
  # Existing logic to create capability node
  cap_id = generate_capability_id()
  lineage_id = determine_lineage(parent_capabilities)
  
  # Record birth for ecology tracking
  Tiannara.Ecology.record_birth(cap_id, lineage_id, tick)
  
  # ... rest of registration logic
  %{state | capability_registry: updated_registry}
end
```

Find where capabilities are removed/extinguished:

```elixir
def extinguish_capability(cap_id, state, tick) do
  # Record death for ecology tracking
  Tiannara.Ecology.record_death(cap_id, tick)
  
  # ... rest of extinction logic
  %{state | capability_registry: updated_registry}
end
```

---

### Step 4: Wrap Economic Phases with Profiling

In `CivilizationScheduler.process_economic_tick/2` or similar:

```elixir
def process_economic_tick(state, tick) do
  # Portfolio Valuation
  state = Tiannara.Profiling.profile(:portfolio_valuation, fn ->
    valuate_all_portfolios(state)
  end)
  
  # Resource Allocation
  state = Tiannara.Profiling.profile(:resource_allocation, fn ->
    allocate_resources(state)
  end)
  
  # Need Matching
  state = Tiannara.Profiling.profile(:need_matching, fn ->
    match_capabilities_to_needs(state)
  end)
  
  # Mortality Selection
  state = Tiannara.Profiling.profile(:mortality_selection, fn ->
    enforce_scarcity(state, tick)
  end)
  
  # Capacity Calculation
  state = Tiannara.Profiling.profile(:capacity_calculation, fn ->
    calculate_carrying_capacity(state)
  end)
  
  state
end
```

---

### Step 5: Wrap Registration Pipeline with Profiling

In capability registration/mutation logic:

```elixir
def mutate_capability(parent_cap) do
  Tiannara.Profiling.profile(:mutation, fn ->
    generate_mutation(parent_cap)
  end)
end

def synthesize_capability(parent_caps) do
  Tiannara.Profiling.profile(:synthesis, fn ->
    combine_capabilities(parent_caps)
  end)
end

def create_capability_node(mutation_result) do
  Tiannara.Profiling.profile(:node_creation, fn ->
    CapabilityNode.create(mutation_result)
  end)
end

def update_fitness_scores(state) do
  Tiannara.Profiling.profile(:fitness_updates, fn ->
    recalculate_all_fitness(state)
  end)
end

def link_dependencies(new_cap, parent_caps) do
  Tiannara.Profiling.profile(:dependency_linking, fn ->
    create_dependency_edges(new_cap, parent_caps)
  end)
end
```

---

### Step 6: Schedule Periodic Reports

In `CivilizationScheduler.run_simulation/3`, add reporting hooks:

```elixir
Enum.reduce(1..max_ticks, initial_state, fn tick, acc_state ->
  # ... simulation logic ...
  
  # Ecology report every 5k ticks
  acc_state =
    if rem(tick, 5_000) == 0 do
      Tiannara.Ecology.print_ecology_report()
      Tiannara.Profiling.print_economic_profile()
      acc_state
    else
      acc_state
    end
  
  # Registration profile every 10k ticks
  acc_state =
    if rem(tick, 10_000) == 0 do
      Tiannara.Profiling.print_registration_profile()
      acc_state
    else
      acc_state
    end
  
  acc_state
end)
```

---

## Testing Checklist

Before running full 100k-tick simulation:

### Compilation Test
```bash
mix compile
```

Expected output:
```
Compiling 2 files (ecology.ex, profiling.ex)
Generated tiannara app
```

### Unit Test (ETS initialization)
```elixir
# In iex -S mix
iex> Tiannara.Ecology.init_tables()
:ok

iex> :ets.info(:eco_lineages)[:name]
:eco_lineages

iex> :ets.info(:eco_births)[:write_concurrency]
true

iex> Tiannara.Profiling.init_profiler()
:ok

iex> :ets.info(:profiler_stats)[:name]
:profiler_stats
```

### Integration Test (single tick)
```elixir
# In iex -S mix
iex> Tiannara.Ecology.init_tables()
:ok

iex> Tiannara.Ecology.record_birth("cap_1", "lineage_A", 1)
:ok

iex> Tiannara.Ecology.tick()
1

iex> Tiannara.Ecology.record_death("cap_1", 100)
:ok

iex> Tiannara.Ecology.print_ecology_report()
# Should print report with 1 birth, 1 death, half-life = 99
```

### Profiling Test
```elixir
# In iex -S mix
iex> Tiannara.Profiling.init_profiler()
:ok

iex> Tiannara.Profiling.profile(:test_phase, fn ->
...>   :timer.sleep(100)
...>   :ok
...> end)
:ok

iex> Tiannara.Profiling.print_economic_profile()
# Should show test_phase with ~100ms duration
```

---

## Expected Results

### Question 1: Economic Bottleneck Breakdown

Run 16 will reveal which sub-component consumes the 47.5% economic runtime:

| Component | Expected % | Interpretation |
|-----------|-----------|----------------|
| Portfolio Valuation | 30-40% | Asset/capability valuation expensive? |
| Resource Allocation | 20-30% | Budget distribution complex? |
| Need Matching | 15-25% | Market matching algorithm heavy? |
| Mortality Selection | 10-20% | Survival ranking costly? |
| Capacity Calculation | 5-10% | Carrying capacity updates cheap |

**If Portfolio Valuation dominates:** Optimize asset scoring algorithms  
**If Need Matching dominates:** Simplify demand-supply matching  
**If Mortality Selection dominates:** Streamline fitness comparisons  

---

### Question 2: Registration Pipeline Breakdown

Run 16 will reveal which sub-component consumes the ~20% registration runtime:

| Component | Expected % | Interpretation |
|-----------|-----------|----------------|
| Mutation | 35-45% | Generating mutations expensive? |
| Synthesis | 20-30% | Combining capabilities complex? |
| Node Creation | 15-25% | Creating nodes costly? |
| Fitness Updates | 10-20% | Recalculating fitness heavy? |
| Dependency Linking | 5-15% | Graph traversal cheap |

**If Mutation dominates:** Optimize random variation generation  
**If Synthesis dominates:** Simplify capability combination logic  
**If Fitness Updates dominates:** Cache fitness calculations  

---

### Question 3: Technological Half-Life

Run 16 will measure average capability lifespan:

| Half-Life Range | Ecosystem State | Action Required |
|----------------|----------------|-----------------|
| < 1,000 ticks | Chaotic | Excessive churn, technologies don't persist |
| 12,000-18,000 ticks | Healthy | Balanced turnover, optimal innovation rate |
| > 50,000 ticks | Stagnant | Technologies persist too long, low innovation |

**Target:** 12-18k ticks indicates healthy technological middle class

---

### Question 4: Shannon Diversity

Run 16 will measure entropy of lineage distribution:

| Shannon Entropy | Diversity State | Interpretation |
|----------------|----------------|----------------|
| < 1.5 | Low | Risk of monoculture, limited variety |
| 1.5-3.0 | Moderate | Some specialization emerging |
| 3.0-5.0 | High | Healthy technological diversity |
| > 5.0 | Very High | Extreme specialization, many niches |

**Target:** > 3.0 indicates diverse ecosystem with multiple thriving lineages

---

### Question 5: Lineage Turnover

Run 16 will measure extinction rate relative to active lineages:

| Turnover Rate | Replacement State | Interpretation |
|--------------|------------------|----------------|
| < 0.05 | Stagnant | Old lineages persist, little replacement |
| 0.05-0.20 | Stable | Healthy competitive replacement |
| 0.20-0.50 | Dynamic | Rapid lineage succession |
| > 0.50 | Unstable | Excessive extinction pressure |

**Target:** 0.05-0.20 indicates stable ecosystem with gradual replacement

---

## Strategic Significance

### What Run 16 Proves

If Run 16 outputs:
- **Half-life:** 12-18k ticks
- **Shannon Diversity:** > 3.0
- **Lineage Turnover:** 0.05-0.20
- **Birth Rate ≈ Extinction Rate** (net growth near zero)

Then we have proven: **Technological Ecology Exists**

This means Tiannara's capability graph behaves like a real biological ecosystem with:
- Birth/death dynamics
- Competitive exclusion
- Niche specialization
- Sustainable turnover

---

### What Comes Next (Phase 7 - OED)

Only after ecological laws are characterized should we activate:

**OED (Ontological Emergence Dynamics):**
- **ACM (Adversarial Crucible Matrix):** Generate candidate realities with extreme physics
- **OAVL (Ontological Adversarial Validation Layer):** Validate candidate ontologies
- **Quarantine:** Contain dangerous ontological transitions
- **Rollback:** Recover from failed reality shifts

**Why wait?** ACM and OAVL will evolve ontologies *inside* an ecosystem whose physical laws we've already mathematically characterized. Without Run 16's ecological baseline, we wouldn't know whether ontology changes stabilize or destabilize the system.

---

## Troubleshooting

### Issue: ETS table already exists

**Error:** `{:error, {:already_exists, :eco_lineages}}`

**Solution:** Delete tables before re-running:
```elixir
:ets.delete(:eco_lineages)
:ets.delete(:eco_births)
:ets.delete(:eco_stats)
:ets.delete(:profiler_stats)
```

---

### Issue: No profiling data collected

**Symptom:** Report shows "No profiling data collected yet"

**Cause:** `profile/2` wrapper not called around target functions

**Solution:** Verify all economic/registration phases wrapped with `Tiannara.Profiling.profile/2`

---

### Issue: Half-life = 0

**Symptom:** Report shows "Average Half-Life: 0.0 ticks"

**Cause:** No deaths recorded yet (simulation too young) or `record_death/2` not called

**Solution:** 
1. Wait until tick > 1000 for first extinctions
2. Verify capability extinction logic calls `Tiannara.Ecology.record_death/2`

---

### Issue: Shannon Entropy calculation slow

**Symptom:** `print_ecology_report()` takes > 1 second

**Cause:** `:ets.match(:eco_lineages, {'$1', '$2'})` scans entire table

**Solution:** Acceptable overhead for 5k-tick interval. If problematic, sample subset:
```elixir
# Sample 10% of lineages for entropy calculation
all_lineages = :ets.match(:eco_lineages, {'$1', '$2'})
sample = Enum.take(all_lineages, div(length(all_lineages), 10))
```

---

## Performance Impact

### Overhead Estimates

| Component | Cost per Call | Frequency | Total Overhead |
|-----------|--------------|-----------|----------------|
| `Ecology.tick()` | ~1 μs | Every tick | 100ms @ 100k ticks |
| `Ecology.record_birth/3` | ~5 μs | ~1M times | 5 seconds |
| `Ecology.record_death/2` | ~10 μs | ~500k times | 5 seconds |
| `Profiling.profile/2` | ~2 μs | ~50k times | 100ms |
| `print_ecology_report()` | ~500ms | Every 5k ticks | 10 seconds |
| `print_economic_profile()` | ~200ms | Every 5k ticks | 4 seconds |
| `print_registration_profile()` | ~200ms | Every 10k ticks | 2 seconds |

**Total overhead:** ~27 seconds over 100k ticks (~0.03% of runtime)

**Conclusion:** Negligible performance impact due to lock-free ETS design

---

## Next Steps

1. ✅ Modules created (ecology.ex, profiling.ex)
2. ✅ Campaign script created (run_run16_ecology_campaign.exs)
3. ⏳ Integrate into CivilizationScheduler
4. ⏳ Add ecology calls to capability registration/extinction
5. ⏳ Wrap economic phases with profiling
6. ⏳ Test compilation
7. ⏳ Execute Run 16 (100k ticks)
8. ⏳ Analyze ecological metrics
9. ⏳ Document findings
10. ⏳ Proceed to Phase 7 (OED) if ecology validated

---

## References

- **Run 15 Report:** `docs/run15_technological_evolution_validation.md`
- **Run 16 Plan:** `docs/run16_technological_ecology_campaign.md`
- **OED Architecture:** `tiannara_runtime/lib/tiannara/oed/`
- **Phase 6.5D Validation:** `run_layer6_5d_campaign.exs`
