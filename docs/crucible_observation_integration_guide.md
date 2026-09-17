# Crucible Observation Integration Guide

**Date**: June 18, 2026  
**Purpose**: Step-by-step guide to integrate observation recording into all 5 Crucible modules  

---

## Overview

All 5 Crucible modules need to emit `%CrucibleObservation{}` records to the Observatory. This creates a unified telemetry stream for law discovery.

**Total Effort**: ~50 lines (10 per module)  
**Risk**: Low (simple function calls)  
**Priority**: HIGH (Gate A requirement)

---

## Module 1: Builder Integration

**File**: `lib/tiannara/asc/crucible/builder.ex`  
**Location**: In `build/3` function, after `register_build(build_result)`

### Add This Code

```elixir
def build(%Genome{} = genome, project_id, opts \\ []) do
  max_attempts = Keyword.get(opts, :max_attempts, 3)
  build_result = do_build(genome, project_id, max_attempts)

  # Record telemetry (SC-B4)
  record_telemetry(build_result)

  # Register in Knowledge Archive
  register_build(build_result)

  # === NEW: Record unified observation ===
  observation = Tiannara.ASC.Crucible.Observation.from_builder_result(
    build_result,
    project_id,
    genome.genome_id,
    genome.generation
  )
  Tiannara.ASC.Crucible.Observatory.record_observation(observation)
  # ========================================

  {:ok, build_result}
end
```

**Lines Added**: 7  
**What It Does**: Converts build_result to unified observation format and sends to Observatory

---

## Module 2: Validator Integration

**File**: `lib/tiannara/asc/crucible/validator.ex`  
**Location**: In `validate/3` function, after `register_validation(validation_result)`

### Add This Code

```elixir
def validate(%Genome{} = genome, artifact_path, opts \\ []) do
  start_time = System.monotonic_time(:millisecond)
  started_at = DateTime.utc_now()

  validation_result = try do
    # ... existing validation logic ...
  end

  # Record telemetry
  record_telemetry(validation_result)

  # Register in Knowledge Archive
  register_validation(validation_result)

  # === NEW: Record unified observation ===
  observation = Tiannara.ASC.Crucible.Observation.from_validator_result(
    validation_result,
    genome.project_id || "unknown",
    genome.genome_id,
    genome.generation
  )
  Tiannara.ASC.Crucible.Observatory.record_observation(observation)
  # ========================================

  {:ok, validation_result}
end
```

**Lines Added**: 8  
**What It Does**: Converts validation_result to unified observation and sends to Observatory

---

## Module 3: Breaker Integration

**File**: `lib/tiannara/asc/crucible/breaker.ex`  
**Location**: In `break/3` function, at the end before returning result

### Add This Code

```elixir
def break(%Genome{} = genome, artifact_path, opts \\ []) do
  start_time = System.monotonic_time(:millisecond)
  started_at = DateTime.utc_now()

  break_result = try do
    # ... existing break logic ...
  end

  # Record telemetry
  record_telemetry(break_result)

  # === NEW: Record unified observation ===
  observation = Tiannara.ASC.Crucible.Observation.from_breaker_result(
    break_result,
    genome.project_id || "unknown",
    genome.genome_id,
    genome.generation
  )
  Tiannara.ASC.Crucible.Observatory.record_observation(observation)
  # ========================================

  {:ok, break_result}
end
```

**Lines Added**: 8  
**What It Does**: Converts break_result to unified observation and sends to Observatory

---

## Module 4: Attacker Integration

**File**: `lib/tiannara/asc/crucible/attacker.ex`  
**Location**: In `attack/3` function, at the end before returning result

### Add This Code

```elixir
def attack(%Genome{} = genome, artifact_path, opts \\ []) do
  start_time = System.monotonic_time(:millisecond)
  started_at = DateTime.utc_now()

  attack_result = try do
    # ... existing attack logic ...
  end

  # Record telemetry
  record_telemetry(attack_result)

  # === NEW: Record unified observation ===
  observation = Tiannara.ASC.Crucible.Observation.from_attacker_result(
    attack_result,
    genome.project_id || "unknown",
    genome.genome_id,
    genome.generation
  )
  Tiannara.ASC.Crucible.Observatory.record_observation(observation)
  # ========================================

  {:ok, attack_result}
end
```

**Lines Added**: 8  
**What It Does**: Converts attack_result to unified observation and sends to Observatory

---

## Module 5: Repairer Integration

**File**: `lib/tiannara/asc/crucible/repairer.ex`  
**Location**: In `repair/3` function, at the end before returning result

### Add This Code

```elixir
def repair(failure_observation, artifact_path, opts \\ []) do
  start_time = System.monotonic_time(:millisecond)
  started_at = DateTime.utc_now()

  repair_result = try do
    # ... existing repair logic ...
  end

  # Record telemetry
  record_telemetry(repair_result)

  # === NEW: Record unified observation ===
  observation = Tiannara.ASC.Crucible.Observation.from_repairer_result(
    repair_result,
    repair_result.project_id || "unknown",
    repair_result.genome_id || "unknown",
    repair_result.generation || 0
  )
  Tiannara.ASC.Crucible.Observatory.record_observation(observation)
  # ========================================

  # === NEW: Register repair pattern if successful ===
  if repair_result.repair_successful? do
    pattern = extract_repair_pattern(repair_result)
    Tiannara.ASC.Crucible.Observatory.register_repair_pattern(pattern)
  end
  # ==================================================

  {:ok, repair_result}
end
```

**Lines Added**: 14 (includes repair pattern registration)  
**What It Does**: 
1. Converts repair_result to unified observation
2. Registers successful repairs as reusable patterns for knowledge reuse tracking (SC-R5)

---

## Helper Function for Repairer

Add this private function to Repairer module to extract repair patterns:

```elixir
defp extract_repair_pattern(repair_result) do
  %Tiannara.ASC.Crucible.RepairPattern{
    id: "pattern_#{repair_result.failure_type}_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}",
    category: repair_result.failure_type,
    failures_fixed: [repair_result.failure_id],
    success_rate: if(repair_result.repair_successful?, do: 1.0, else: 0.0),
    reuse_count: 0,
    domains_used: [repair_result.architecture_style || :unknown],
    confidence: if(repair_result.repair_successful?, do: 0.7, else: 0.3),
    created_at: DateTime.utc_now(),
    last_used_at: DateTime.utc_now()
  }
end
```

**Lines Added**: 13  
**What It Does**: Creates a RepairPattern struct from successful repairs for knowledge reuse tracking

---

## Verification Steps

After adding all integrations:

### 1. Compile Check

```bash
mix compile
```

Expected: No errors, all modules compile successfully

### 2. Quick Test

Create a test script to verify observation flow:

```elixir
# test_observation_flow.exs
alias Tiannara.ASC.Crucible.{Builder, Validator, Breaker, Attacker, Repairer, Observatory}
alias Tiannara.ASC.Interface.Genome

# Create a simple test genome
genome = %Genome{
  genome_id: "test_genome_001",
  generation: 1,
  project_id: "test_project"
}

# Test Builder observation
{:ok, build_result} = Builder.build(genome, "test_project")
IO.puts("✅ Builder observation recorded")

# Get observatory stats
{:ok, stats} = Observatory.get_survival_stats()
IO.inspect(stats, label: "Observatory Stats")

# Verify observation was recorded
if stats.total_observations > 0 do
  IO.puts("✅ Observation pipeline working!")
else
  IO.puts("❌ No observations recorded - check integration")
end
```

Run with:
```bash
mix run test_observation_flow.exs
```

### 3. Check Observatory Metrics

After running pilot campaign, verify metrics are populating:

```elixir
{:ok, metrics} = Tiannara.ASC.Crucible.Observatory.get_metrics()
IO.inspect(metrics, label: "Full Metrics")

# Should show:
# - total_observations > 0
# - observation_count_by_source with counts for :builder, :validator, etc.
# - survival_rate, failure_rate, etc. calculated
```

---

## Troubleshooting

### Issue: Compilation error "module Observation not found"

**Solution**: Ensure Observation module is compiled first:
```bash
mix clean && mix compile
```

### Issue: GenServer not started error

**Solution**: Start Observatory before running tests:
```elixir
{:ok, _pid} = Tiannara.ASC.Crucible.Observatory.start_link([])
```

Or add to application supervisor in `mix.exs`:
```elixir
children = [
  Tiannara.ASC.Crucible.Observatory,
  # ... other children
]
```

### Issue: Observations not appearing in metrics

**Solution**: Check that:
1. All 5 modules have the integration code added
2. Observatory GenServer is running
3. No errors in observation conversion functions

Debug by checking individual module outputs:
```elixir
observation = Tiannara.ASC.Crucible.Observation.from_builder_result(build_result, "proj", "gen", 1)
IO.inspect(observation, label: "Generated Observation")
```

---

## Expected Outcome

After completing all 5 integrations:

✅ Every build/validation/break/attack/repair produces a `%CrucibleObservation{}`  
✅ All observations flow to Observatory automatically  
✅ Observatory aggregates metrics in real-time  
✅ Law candidates generated when thresholds met  
✅ Unified telemetry stream ready for Alpha Campaign  

**Total Lines Added**: ~50 across 5 modules  
**Time Required**: ~1 hour  
**Risk**: Low (simple function calls, no logic changes)

---

## Next Steps After Integration

1. ✅ Complete observation integration (this document)
2. ⏸️ Add epoch finalization to Observatory (~20 lines)
3. ⏸️ Run compilation check
4. ⏸️ Launch 5-project pilot campaign
5. ⏸️ Fix any issues found
6. ⏸️ Launch full 25-project Alpha Campaign

Once integration is complete, ASC will have a **complete experimental pipeline** ready for scientific discovery.
