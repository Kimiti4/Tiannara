# Layer 6.5D Revised Implementation Plan (Economic-First Approach)

**Date**: June 13, 2026  
**Status**: 🔄 **REPRIORITIZED** based on architectural correction  
**Philosophy**: Economics before evolution, assets before metrics

---

## Executive Summary

Following your profound architectural correction, the Layer 6.5D implementation has been **reprioritized** to focus on **civilizational economics** before evolutionary mechanics.

### Key Insight

> "Evolution without economics = artificial evolution"  
> "Economics without evolution = real ecology"

The first question is not "Can institutions evolve?" but **"Can discoveries sustain institutions?"**

---

## Reprioritized Implementation Order

### ✅ COMPLETED: State Infrastructure

**File**: [`lib/tiannara/os/state.ex`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/state.ex)

Added Layer 6.5D fields:
```elixir
program_graveyard: %{},        # Institutional memory
species_registry: %{},         # Species tracking
world_epistemic_physics: %{},  # World physics profiles
institution_registry: %{}      # Institution-level tracking
```

**Status**: ✅ COMPLETE

---

### ✅ COMPLETED: Discovery Asset Economy Module

**File**: [`lib/tiannara/os/discovery_asset_economy.ex`](file://c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/discovery_asset_economy.ex) (245 lines)

**What It Does**: Closes the civilizational loop by converting discoveries into persistent assets that generate ongoing royalties.

**Key Functions**:
1. `create_discovery_asset/3` - Converts validated discovery → asset
2. `calculate_asset_royalties/2` - Calculates ongoing revenue from asset portfolio
3. `update_asset_values/1` - Revalues assets based on market dynamics
4. `revalue_asset/2` - Applies depreciation/appreciation over time

**Economic Loop**:
```
Validated Discovery
  ↓
Discovery Asset (persistent, tradeable)
  ↓
Asset Value (appreciates/depreciates)
  ↓
Royalties (ongoing revenue: 2% of asset value per tick)
  ↓
Funding (sustains institution)
  ↓
More Research (closes loop)
```

**Status**: ✅ COMPLETE

---

### ⏳ PRIORITY 1: Integrate Resource Ecology (Next)

**Goal**: Programs consume resources and die from economic failure.

**Integration Points**:

#### 1.1 Add Resource Consumption to Simulation Loop

```elixir
# In simulation loop (every tick):
state = state.research_programs
  |> Map.values()
  |> Enum.reduce(state, fn prog, acc_state ->
    if prog.status == :active do
      # Apply resource economics
      updated_prog = ResourceEcology.apply_resource_economics(prog, acc_state)
      
      new_programs = Map.put(acc_state.research_programs, prog.id, updated_prog)
      %{acc_state | research_programs: new_programs}
    else
      acc_state
    end
  end)
```

#### 1.2 Handle Program Death

```elixir
# After resource economics application:
if updated_prog.status == :suspended do
  # Record in graveyard
  graveyard = InstitutionalMemory.record_program_death(
    acc_state.program_graveyard,
    updated_prog,
    updated_prog.outcome,
    current_tick
  )
  
  # Update species registry
  species_registry = SpeciationEngine.update_species_registry(
    acc_state.species_registry,
    updated_prog,
    :death
  )
  
  %{acc_state | 
    program_graveyard: graveyard,
    species_registry: species_registry
  }
else
  acc_state
end
```

**Expected Outcome**: 15-25% program mortality from resource exhaustion.

**Estimated Time**: 1-2 hours

---

### ⏳ PRIORITY 2: Connect Discovery → Asset → Royalties Loop

**Goal**: Replace simple royalty calculation with asset-backed economy.

**Integration Points**:

#### 2.1 Create Assets for Validated Discoveries

```elixir
# When program validates discoveries:
validated_discovery_ids = program.discoveries

Enum.each(validated_discovery_ids, fn disc_id ->
  case DiscoveryAssetEconomy.create_discovery_asset(state, disc_id, program.id) do
    {:ok, new_state, _asset} -> state = new_state
    {:error, _} -> :ok  # Skip if already exists
  end
end)
```

#### 2.2 Calculate Asset-Based Royalties

```elixir
# Replace simple production calculation with:
asset_royalties = DiscoveryAssetEconomy.calculate_asset_royalties(state, program.id)

# Use asset_royalties instead of calculated production
updated_budget = %{
  program.budget |
  credits: program.budget.credits + asset_royalties.funding,
  compute: program.budget.compute + asset_royalties.compute,
  attention: program.budget.attention + asset_royalties.attention
}
```

#### 2.3 Periodic Asset Revaluation

```elixir
# Every 1000 ticks:
if rem(current_tick, 1000) == 0 do
  state = DiscoveryAssetEconomy.update_asset_values(state)
end
```

**Expected Outcome**: 
- Programs with valuable asset portfolios thrive
- Programs with poor discoveries struggle
- Economic sustainability drives selection

**Estimated Time**: 2-3 hours

---

### ⏳ PRIORITY 3: Implement Program Mortality & Inheritance

**Goal**: Dead programs transfer resources to successors; lineage continues.

**Implementation**:

#### 3.1 Resource Redistribution on Death

```elixir
defp redistribute_resources(state, dead_program) do
  # Find successful programs in same world/institution
  candidates = state.research_programs
    |> Map.values()
    |> Enum.filter(fn p ->
      p.world_id == dead_program.world_id and
      p.status == :active and
      p.metrics.roi > 0.8
    end)
  
  if length(candidates) > 0 do
    # Distribute remaining budget proportionally
    total_roi = Enum.sum(Enum.map(candidates, & &1.metrics.roi))
    
    Enum.reduce(candidates, state, fn candidate, acc_state ->
      share = candidate.metrics.roi / total_roi
      inheritance = dead_program.budget.credits * share
      
      updated_budget = %{
        candidate.budget |
        credits: candidate.budget.credits + inheritance
      }
      
      updated_candidate = %ResearchProgram{candidate | budget: updated_budget}
      new_programs = Map.put(acc_state.research_programs, candidate.id, updated_candidate)
      %{acc_state | research_programs: new_programs}
    end)
  else
    state  # No worthy inheritors
  end
end
```

#### 3.2 Spawn Descendants with Mutation

```elixir
defp spawn_descendant(state, parent_program) do
  # Mutate genome slightly
  mutated_genome = mutate_genome(parent_program.strategy_genome, mutation_rate: 0.1)
  
  # Create new program
  new_program = %ResearchProgram{
    id: generate_new_id(),
    world_id: parent_program.world_id,
    institution_id: parent_program.institution_id,
    strategy_genome: mutated_genome,
    budget: %{
      credits: parent_program.budget.credits * 0.2,  # Inherit 20%
      compute: parent_program.budget.compute * 0.2,
      attention: parent_program.budget.attention * 0.2
    },
    generation: parent_program.generation + 1,
    parent_program_id: parent_program.id,
    started_at_tick: :os.system_time(:millisecond),
    status: :active,
    metadata: parent_program.metadata
  }
  
  # Classify into species
  {species_id, updated_registry} = SpeciationEngine.classify_species(
    new_program,
    state.species_registry
  )
  
  new_program = %ResearchProgram{
    new_program |
    metadata: Map.put(new_program.metadata, :species_id, species_id)
  }
  
  # Add to state
  new_programs = Map.put(state.research_programs, new_program.id, new_program)
  %{state | 
    research_programs: new_programs,
    species_registry: updated_registry
  }
end

defp mutate_genome(genome, mutation_rate: rate) do
  %{
    exploration_rate: clamp(genome.exploration_rate + (:rand.normal() * rate)),
    validation_priority: clamp(genome.validation_priority + (:rand.normal() * rate)),
    cross_domain_synthesis: clamp(genome.cross_domain_synthesis + (:rand.normal() * rate)),
    anomaly_sensitivity: clamp(genome.anomaly_sensitivity + (:rand.normal() * rate)),
    risk_tolerance: clamp(genome.risk_tolerance + (:rand.normal() * rate))
  }
end

defp clamp(value), do: max(0.0, min(1.0, value))
```

**Expected Outcome**: 
- Lineage continuity through inheritance
- Gradual genome adaptation via mutation
- Evolution velocity measurable

**Estimated Time**: 2-3 hours

---

### ⏳ PRIORITY 4: Integrate Speciation Engine

**Goal**: Programs classified into species; track ecosystem diversity.

**Integration**: Already partially implemented in Priority 3 (descendant spawning).

**Additional Integration**:

#### 4.1 Initial Classification on Program Creation

```elixir
# When creating initial programs:
{species_id, updated_registry} = SpeciationEngine.classify_species(
  program,
  state.species_registry
)

program = %ResearchProgram{
  program |
  metadata: Map.put(program.metadata, :species_id, species_id)
}

state = %{
  state |
  research_programs: Map.put(state.research_programs, program.id, program),
  species_registry: updated_registry
}
```

#### 4.2 Track Species Diversity Metrics

```elixir
# Every 5000 ticks:
if rem(current_tick, 5000) == 0 do
  diversity = SpeciationEngine.get_species_diversity(state.species_registry)
  
  IO.puts("Species Count: #{diversity.species_count}")
  IO.puts("Shannon Entropy: #{diversity.shannon_entropy}")
  IO.puts("Dominant Species: #{inspect(diversity.dominant_species)}")
end
```

**Expected Outcome**: 4-6 coexisting species, Shannon entropy 1.6-1.9.

**Estimated Time**: 30 minutes (mostly done in Priority 3)

---

### ⏳ PRIORITY 5: Implement Environmental Drift

**Goal**: Worlds evolve epistemic physics based on research progress.

**Rationale**: Without drift, optimal strategy becomes static → convergence, not civilization.

**Implementation**:

```elixir
defmodule TiannaraOS.EnvironmentalDrift do
  @doc """
  Evolve world epistemic physics based on research progress.
  
  As discoveries accumulate, uncertainty decreases and validation becomes more important.
  """
  def evolve_world_physics(state, world_id) do
    programs_in_world = get_programs_in_world(state, world_id)
    
    # Calculate total validated discoveries
    total_validated = Enum.sum(Enum.map(programs_in_world, & &1.metrics.candidates_validated))
    
    # Reduce uncertainty based on research progress
    uncertainty_reduction = total_validated * 0.0001
    
    # Get current physics
    current_physics = Map.get(state.world_epistemic_physics, world_id)
    
    if current_physics do
      new_uncertainty = max(current_physics.uncertainty - uncertainty_reduction, 0.1)
      
      # Shift preferences as environment matures
      new_physics = %WorldEpistemicPhysics{
        current_physics |
        uncertainty: new_uncertainty,
        experiment_cost: current_physics.experiment_cost * 0.99  # Experiments get cheaper
      }
      |> WorldEpistemicPhysics.derive_preferences()
      
      # Update state
      new_physics_map = Map.put(state.world_epistemic_physics, world_id, new_physics)
      %{state | world_epistemic_physics: new_physics_map}
    else
      state
    end
  end
  
  defp get_programs_in_world(state, world_id) do
    state.research_programs
    |> Map.values()
    |> Enum.filter(& &1.world_id == world_id)
  end
end
```

**Integration**:
```elixir
# Every 10,000 ticks:
if rem(current_tick, 10_000) == 0 do
  Enum.each(world_ids, fn world_id ->
    state = EnvironmentalDrift.evolve_world_physics(state, world_id)
  end)
end
```

**Expected Outcome**: 
- Worlds transition from exploration-favoring to validation-favoring
- Programs must adapt or face extinction
- Co-evolution between programs and environments

**Estimated Time**: 1-2 hours

---

### ⏳ PRIORITY 6: Add Lineage Tracking Fields (Downgraded from Critical)

**Goal**: Track generational evolution (measurement, not behavior).

**Fields to Add** to `ResearchProgram` struct:
```elixir
generation: 1,                    # Evolutionary generation
started_at_tick: nil,             # When program was created
fitness_history: [],              # ROI over time
total_resource_consumption: 0.0   # Accumulated consumption
```

**Status**: ⚠️ **BLOCKED** by file save issue (same as before)

**Note**: Downgraded from Critical because these are observability features, not core mechanics. System can evolve before we measure it.

**Estimated Time**: 30 minutes (once file save issue resolved)

---

## Success Metrics (Revised)

### Don't Measure:
- ❌ "4-6 species" (arbitrary target)
- ❌ "Entropy 1.6-1.9" (meaningless without context)
- ❌ "20 graveyard records" (quantity ≠ quality)

### DO Measure:

#### 1. Ecological Turnover
```elixir
birth_rate ≈ death_rate
# Indicates stable ecosystem, not collapse or stagnation
```

#### 2. Adaptive Movement
```elixir
average_fitness increasing over time
# Indicates genuine adaptation, not random drift
```

#### 3. Institutional Survival
```elixir
some institutions survive >10 generations
# Indicates sustainable economic models emerging
```

#### 4. Domain Migration
```elixir
explorer_species leaves mathematics_world
explorer_species migrates into ecology_world
# Indicates programs finding their ecological niches
```

#### 5. Economic Sustainability
```elixir
asset_royalties > resource_consumption for surviving programs
# Indicates discoveries can sustain institutions
```

---

## Recommended Sprint Plan

### Sprint 1: Economic Foundation (Day 1)
**Time**: 4-5 hours

1. ✅ State fields added
2. ✅ DiscoveryAssetEconomy module created
3. ⏳ Integrate ResourceEcology into simulation loop
4. ⏳ Connect Discovery → Asset → Royalties loop
5. ⏳ Test economic viability (can discoveries sustain programs?)

**Success Criteria**: Programs with good discoveries survive; poor performers die.

---

### Sprint 2: Mortality & Inheritance (Day 2)
**Time**: 4-5 hours

1. ⏳ Implement program death handling
2. ⏳ Implement resource redistribution
3. ⏳ Implement descendant spawning with mutation
4. ⏳ Integrate speciation classification
5. ⏳ Test mortality/inheritance cycle

**Success Criteria**: Dead programs' resources transfer to successors; lineage continues.

---

### Sprint 3: Environmental Drift & Validation (Day 3)
**Time**: 4-5 hours

1. ⏳ Implement environmental drift
2. ⏳ Integrate drift into simulation loop
3. ⏳ Run 20k-tick pilot test
4. ⏳ Measure success metrics
5. ⏳ Debug issues

**Success Criteria**: Worlds evolve, programs adapt, genuine institutional evolution observed.

---

### Sprint 4: Observability Enhancements (Day 4, Optional)
**Time**: 2-3 hours

1. ⏳ Add generation field (once file save works)
2. ⏳ Implement fitness history tracking
3. ⏳ Implement ancestor counting
4. ⏳ Add detailed metrics logging

**Success Criteria**: Can measure and visualize evolution velocity.

---

## Strategic Significance

This revised approach transforms Layer 6.5D from "biological evolution simulator" into **genuine civilizational economy**:

### Before (Biological Model)
```
Programs compete → Fittest survive → Genomes propagate
```

**Limitation**: Artificial selection, no economic reality.

---

### After (Civilizational Model)
```
Discoveries → Assets → Royalties → Funding → More Research
       ↑                                          ↓
       └────────── Economic Loop ────────────────┘
```

**Result**: Real ecology where economic sustainability drives evolution.

---

## Conclusion

The reprioritized plan focuses on **economics first**, then evolution. This ensures that when evolution occurs, it's driven by genuine economic pressures, not arbitrary fitness functions.

**Next Step**: Begin Sprint 1 by integrating ResourceEcology and DiscoveryAssetEconomy into the simulation loop.

Once the economic foundation is solid, evolution will emerge naturally—not as a programmed feature, but as an emergent property of civilizational economics.

---

**End of Revised Implementation Plan**
