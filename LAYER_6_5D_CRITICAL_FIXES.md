# Layer 6.5D Critical Fixes Checklist

**Priority Order**: Fix these BEFORE integration testing

---

## 🔴 CRITICAL (Block Integration)

### 1. Fix ResearchProgram Struct - Add `generation` Field

**File**: `lib/tiannara/os/research_program.ex`  
**Line**: ~37 (after `child_program_ids`)  
**Issue**: File save failing - may need manual edit or IDE restart

**Required Change**:
```elixir
# ADD THIS LINE after child_program_ids:
generation: 1,           # integer() - evolutionary generation (1 = founding, 2+ = descendants)
```

**Why Critical**: Without this field, can't track evolution velocity or measure generational adaptation.

**Status**: ⚠️ **BLOCKED** - File save operations failing

---

### 2. Fix State Struct - Add Layer 6.5D Fields

**File**: `lib/tiannara/os/state.ex`  
**Location**: In defstruct block

**Required Changes**:
```elixir
# ADD THESE FIELDS to State struct:
program_graveyard: %{},      # Institutional memory (InstitutionalMemory)
species_registry: %{},       # Species tracking (SpeciationEngine)
world_epistemic_physics: %{}, # World physics profiles (WorldEpistemicPhysics)
```

**Why Critical**: Without these fields, modules have nowhere to store their data.

**Status**: ⏳ **NOT STARTED**

---

## 🟡 HIGH PRIORITY (Required for Core Functionality)

### 3. Integrate ResourceEcology Into Simulation Loop

**File**: `test/tiannara/os/layer6_5d_institutional_evolution_test.exs` (to be created)  
**Location**: In simulation loop, every tick

**Required Integration**:
```elixir
# Add to simulation loop:
state = state.research_programs
  |> Map.values()
  |> Enum.reduce(state, fn prog, acc_state ->
    if prog.status == :active do
      updated_prog = ResourceEcology.apply_resource_economics(prog, acc_state)
      
      if updated_prog.status == :suspended do
        # Record death in graveyard
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
        
        new_programs = Map.put(acc_state.research_programs, prog.id, updated_prog)
        %{acc_state | 
          research_programs: new_programs,
          program_graveyard: graveyard,
          species_registry: species_registry
        }
      else
        new_programs = Map.put(acc_state.research_programs, prog.id, updated_prog)
        %{acc_state | research_programs: new_programs}
      end
    else
      acc_state
    end
  end)
```

**Why High Priority**: Without this, programs don't consume resources or die from economic failure.

**Status**: ⏳ **NOT STARTED**

---

### 4. Integrate SpeciationEngine Into Program Creation

**File**: Test initialization code  
**Location**: When creating programs

**Required Integration**:
```elixir
# When creating each program:
{species_id, updated_registry} = SpeciationEngine.classify_species(
  program,
  state.species_registry
)

program = %ResearchProgram{
  program |
  metadata: Map.put(program.metadata, :species_id, species_id),
  started_at_tick: current_tick  # For lifespan tracking
}

state = %{
  state |
  research_programs: Map.put(state.research_programs, program.id, program),
  species_registry: updated_registry
}
```

**Why High Priority**: Without this, can't track speciation events or measure ecosystem diversity.

**Status**: ⏳ **NOT STARTED**

---

### 5. Add Lineage Tracking Fields

**File**: `lib/tiannara/os/research_program.ex`  
**Location**: In defstruct block

**Required Changes**:
```elixir
# ADD THESE FIELDS:
started_at_tick: nil,      # integer() | nil - when program was created
fitness_history: [],       # [float()] - ROI over time
total_resource_consumption: 0.0,  # float() - accumulated consumption
```

**Why High Priority**: Needed for accurate lifespan calculation and evolutionary analysis.

**Status**: ⏳ **NOT STARTED**

---

## 🟢 MEDIUM PRIORITY (Enhancements, Can Wait)

### 6. Implement Fitness History Tracking

**File**: `lib/tiannara/os/institutional_memory.ex`  
**Function**: `get_fitness_history/1` (line 207)

**Current Stub**:
```elixir
defp get_fitness_history(_program) do
  []
end
```

**Fix**: Track fitness in ResearchProgram struct and return it here.

**Status**: ⏳ **CAN WAIT** - Not blocking core evolution

---

### 7. Implement Total Consumption Accumulation

**File**: `lib/tiannara/os/institutional_memory.ex`  
**Function**: `calculate_total_consumption/1` (line 213)

**Current Stub**:
```elixir
defp calculate_total_consumption(_program) do
  0.0
end
```

**Fix**: Accumulate consumption in ResearchProgram struct each tick.

**Status**: ⏳ **CAN WAIT** - Not blocking core evolution

---

### 8. Implement Accurate Lifespan Calculation

**File**: `lib/tiannara/os/institutional_memory.ex`  
**Function**: `calculate_lifespan/2` (line 219)

**Current Stub**:
```elixir
defp calculate_lifespan(program, current_tick) do
  trunc(program.metrics.candidates_produced / 0.1)  # Rough estimate
end
```

**Fix**: Use `current_tick - program.started_at_tick` once field is added.

**Status**: ⏳ **CAN WAIT** - Depends on fix #5

---

### 9. Implement Ancestor Counting

**File**: `lib/tiannara/os/institutional_memory.ex`  
**Function**: `count_ancestors/1` (line 231)

**Current Stub**:
```elixir
defp count_ancestors(_program) do
  0
end
```

**Fix**: Traverse parent chain recursively or maintain counter field.

**Status**: ⏳ **CAN WAIT** - Nice-to-have for lineage analysis

---

## ⏳ FUTURE (Phase 2+)

### 10. Implement Environmental Drift

**File**: New module or add to WorldEpistemicPhysics  
**Concept**: Worlds evolve epistemic physics based on research progress

**Not Started**: Implement after Layer 6.5D core mechanics validated.

---

## Summary by Priority

| Priority | Count | Estimated Time | Blocks Testing? |
|----------|-------|----------------|-----------------|
| 🔴 CRITICAL | 2 | 30 min | YES |
| 🟡 HIGH | 3 | 3-4 hours | YES |
| 🟢 MEDIUM | 4 | 1-2 hours | NO |
| ⏳ FUTURE | 1 | 1-2 hours | NO |

**Total time to working Layer 6.5D**: ~6-8 hours (once file save issue resolved)

---

## Immediate Next Steps

1. **Resolve file save issue** for ResearchProgram struct
2. **Add `generation` field** to ResearchProgram
3. **Add graveyard/species/physics fields** to State struct
4. **Create Layer 6.5D test suite** with integrated simulation loop
5. **Run test** and validate institutional evolution occurs

---

**End of Critical Fixes Checklist**
