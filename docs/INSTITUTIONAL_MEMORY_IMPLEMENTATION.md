# Institutional Memory System - Implementation Guide

## Overview

The Institutional Memory system transforms Tiannara from "blind evolution" into **cumulative cultural learning**. Instead of each generation rediscovering what kills them, civilizations accumulate wisdom from their graveyard and use it to guide future reproduction.

**This is the difference between evolving organisms and evolving civilizations.**

---

## Architecture

### Core Flow

```
Program Death → Graveyard Record → Pattern Analysis → Wisdom Extraction → Mutation Guidance
     ↑                                                                              ↓
     └────────────── Next Generation Avoids Ancestral Mistakes ─────────────────────┘
```

### Components

1. **InstitutionalMemory Module** (`lib/tiannara/os/institutional_memory.ex`)
   - Extracts wisdom from graveyard
   - Analyzes failure patterns
   - Identifies successful strategies
   - Detects domain saturation

2. **ReproductionEngine Module** (`lib/tiannara/os/reproduction_engine.ex`)
   - Probabilistic reproduction (sigmoid curve)
   - Wisdom-guided mutation
   - Lineage tracking
   - Budget inheritance

3. **Integration Point**: `InstitutionalMemory.apply_wisdom_to_mutation/3`
   - Called during child program spawning
   - Adjusts mutation direction based on ancestral lessons
   - Weighted by confidence level

---

## Key Features

### 1. Failure Pattern Analysis

Identifies trait combinations that lead to death:

```elixir
# Example: High exploration without validation is fatal
failed_traits = %{
  high_exploration_low_validation_fatal: true,
  low_risk_tolerance_slow_death: true,
  low_exploration_stagnation: true
}
```

**Analysis Methods:**
- Group deaths by cause (resource exhaustion, stagnation, competition)
- Calculate average traits of failed programs
- Identify dangerous trait combinations

### 2. Success Pattern Analysis

Identifies traits correlated with long life:

```elixir
successful_traits = %{
  survival_genome: %{
    exploration_rate: 0.5,
    validation_priority: 0.6,
    cross_domain_synthesis: 0.7,
    anomaly_sensitivity: 0.6,
    risk_tolerance: 0.6
  },
  avg_lifespan: 5234,
  avg_asset_count: 3.2
}
```

**Analysis Methods:**
- Find top 20% longest-lived programs
- Calculate average genome of survivors
- Track asset accumulation patterns

### 3. Domain Saturation Detection

Identifies oversaturated and underserved research domains:

```elixir
domain_saturation = %{
  energy: %{count: 45, proportion: 0.45, status: :oversaturated},
  medicine: %{count: 12, proportion: 0.12, status: :balanced},
  materials: %{count: 3, proportion: 0.03, status: :underserved}
}
```

**Implications:**
- Oversaturated domains → lower ROI for new discoveries
- Underserved domains → higher opportunity for breakthroughs

### 4. Wisdom-Guided Mutation

Adjusts mutation direction based on confidence-weighted lessons:

```elixir
mutated_genome = InstitutionalMemory.apply_wisdom_to_mutation(
  parent_genome,
  wisdom,
  mutation_rate
)
```

**Mechanism:**
1. Apply base Gaussian mutation
2. Adjust away from failed trait regions (if confidence > threshold)
3. Move toward successful trait patterns (weighted by confidence)
4. Bound all values to [0, 1]

**Confidence Scaling:**
- < 3 deaths: confidence = 0.0 (no guidance)
- 3-50 deaths: confidence = deaths / 50 (growing confidence)
- > 50 deaths: confidence = 1.0 (maximum confidence)

---

## Usage Examples

### Extracting Wisdom

```elixir
# Get wisdom for a specific world
wisdom = InstitutionalMemory.extract_wisdom(state, :w1_medicine)

# Returns:
%{
  failed_traits: %{high_exploration_low_validation_fatal: true},
  successful_traits: %{survival_genome: %{...}},
  domain_saturation: %{energy: :oversaturated},
  lesson_count: 47,
  confidence: 0.94
}
```

### Applying Wisdom to Reproduction

```elixir
# In ReproductionEngine.mutate_and_spawn/4:

# Extract wisdom before spawning child
wisdom = InstitutionalMemory.extract_wisdom(state, parent.world_id)

# Apply wisdom-guided mutation
mutated_genome = InstitutionalMemory.apply_wisdom_to_mutation(
  parent.strategy_genome,
  wisdom,
  0.2  # Base mutation rate
)

# Spawn child with mutated genome
child = %ResearchProgram{
  id: child_id,
  strategy_genome: mutated_genome,
  # ... other fields
}
```

### Summarizing Wisdom

```elixir
summary = InstitutionalMemory.summarize_wisdom(wisdom)
IO.puts(summary)

# Output:
# === Institutional Memory Summary ===
# Lessons learned: 47
# Confidence: 94.0%
#
# Failed Traits:
#   - high_exploration_low_validation_fatal: true
#   - low_risk_tolerance_slow_death: true
#
# Successful Traits:
#   Survival Genome: %{exploration_rate: 0.5, ...}
#   Avg Lifespan: 5234 ticks
#
# Domain Saturation:
#   - energy: 45 discoveries (45.0%) [oversaturated]
#   - medicine: 12 discoveries (12.0%) [balanced]
```

---

## Testing

### Run Unit Tests

```bash
mix test test/tiannara/os/institutional_memory_test.exs --trace
```

### Test Coverage

1. **Wisdom Extraction**
   - Empty wisdom with insufficient data
   - Failed trait identification
   - Successful trait recognition
   - Domain saturation analysis

2. **Mutation Application**
   - Adjustment away from fatal strategies
   - Movement toward successful patterns
   - Confidence-weighted influence
   - Value bounding [0, 1]

3. **Integration**
   - Full reproduction cycle
   - Parent-child trait comparison
   - Wisdom summary formatting

---

## Integration with Existing Systems

### ResearchProgram Struct Updates

Add these fields if not already present:

```elixir
defstruct [
  # ... existing fields ...
  parent_program_id: nil,      # atom() | nil - Parent program ID
  child_program_ids: [],       # [atom()] - List of child program IDs
  generation: 1,               # integer() - Generational depth
  metadata: %{}                # map() - Includes created_at_tick, current_tick, etc.
]
```

### State Struct Updates

Ensure these fields exist:

```elixir
defstruct [
  # ... existing fields ...
  program_graveyard: %{},      # map() - Death records
  species_registry: %{},       # map() - Species classifications
  economy: %{tick: 0}          # map() - Economy state with tick counter
]
```

### Simulation Loop Integration

```elixir
# In main simulation loop:

Enum.reduce(1..max_ticks, initial_state, fn tick, acc_state ->
  # Step 1: Process economic tick
  state_after_economics = process_economic_tick(acc_state, tick)
  
  # Step 2: Trigger reproduction every 100 ticks
  state_after_reproduction = if rem(tick, 100) == 0 do
    ReproductionEngine.trigger_reproduction(state_after_economics)
  else
    state_after_economics
  end
  
  # Step 3: Update tick counter
  updated_economy = Map.put(state_after_reproduction.economy, :tick, tick)
  %{state_after_reproduction | economy: updated_economy}
end)
```

---

## Expected Behavior

### Without Institutional Memory

```
Generation 1: Programs explore randomly, many die from resource exhaustion
Generation 2: Offspring repeat same mistakes, similar death patterns
Generation 3: No improvement, civilization stagnates
...
Generation N: Still making same errors, no cumulative learning
```

### With Institutional Memory

```
Generation 1: Programs explore randomly, many die from resource exhaustion
Generation 2: Wisdom extracted, offspring avoid high-exploration-low-validation
Generation 3: Refined strategies emerge, longer lifespans
Generation 4: Domain specialization begins, reduced competition
...
Generation N: Optimized strategies, sustained growth, adaptive civilization
```

---

## Performance Considerations

### Computational Complexity

- **Wisdom Extraction**: O(n) where n = number of deaths in world
- **Mutation Application**: O(1) per trait (5 traits total)
- **Domain Saturation**: O(d) where d = number of discoveries

### Optimization Strategies

1. **Cache Wisdom**: Extract wisdom once per 1000 ticks, reuse for multiple reproductions
2. **Sample Deaths**: If >100 deaths, analyze random sample of 50
3. **Lazy Evaluation**: Only extract wisdom when reproduction triggers

### Memory Usage

- Graveyard grows linearly with deaths
- Consider pruning old records (>10k ticks ago) if memory becomes constraint
- Typical size: ~500 bytes per death record

---

## Tuning Parameters

### @min_deaths_for_analysis (default: 3)

Minimum deaths before extracting patterns.

- **Lower** (1-2): Faster learning but noisy patterns
- **Higher** (5-10): More reliable patterns but slower adaptation

### @wisdom_influence_weight (default: 0.4)

How much wisdom influences mutation vs random variation.

- **Lower** (0.1-0.2): More exploration, slower convergence
- **Higher** (0.6-0.8): Faster convergence, risk of premature optimization

### @reproduction_scale (default: 3000.0)

Portfolio value where reproduction probability hits ~60%.

- **Lower** (1000-2000): Earlier reproduction, faster population growth
- **Higher** (5000-10000): Later reproduction, selective pressure

### @base_mutation_rate (default: 0.2)

Standard deviation of Gaussian mutation.

- **Lower** (0.05-0.1): Conservative changes, stable lineages
- **Higher** (0.3-0.5): Radical changes, rapid diversification

---

## Debugging Tips

### Check Wisdom Extraction

```elixir
wisdom = InstitutionalMemory.extract_wisdom(state, :w1)
IO.inspect(wisdom.confidence, label: "Confidence")
IO.inspect(wisdom.lesson_count, label: "Lessons")
IO.inspect(wisdom.failed_traits, label: "Failed Traits")
```

### Verify Mutation Guidance

```elixir
parent_genome = %{exploration_rate: 0.9, validation_priority: 0.1, ...}
wisdom = %{failed_traits: %{high_exploration_low_validation_fatal: true}, confidence: 0.8}

mutated = InstitutionalMemory.apply_wisdom_to_mutation(parent_genome, wisdom, 0.2)

IO.puts("Parent exploration: #{parent_genome.exploration_rate}")
IO.puts("Child exploration:  #{mutated.exploration_rate}")
IO.puts("Adjusted: #{mutated.exploration_rate < parent_genome.exploration_rate}")
```

### Monitor Reproduction Events

```elixir
# Enable debug output in ReproductionEngine
IO.puts("🧬 Reproduction: #{prog_id} → #{child_id}")
IO.puts("   Portfolio: #{Float.round(portfolio_value, 0)}")
IO.puts("   Probability: #{Float.round(reproduction_prob * 100, 1)}%")
IO.puts("   Wisdom applied: #{wisdom.confidence > 0.1}")
```

---

## Common Issues

### Issue 1: No Wisdom Extracted

**Symptom**: `confidence == 0.0` even after many deaths

**Cause**: Less than 3 deaths in target world

**Solution**: Wait for more deaths or lower `@min_deaths_for_analysis`

### Issue 2: Mutation Not Guided

**Symptom**: Child traits identical to parent despite wisdom

**Cause**: Wisdom confidence too low (< 0.1)

**Solution**: Accumulate more deaths or increase `@wisdom_influence_weight`

### Issue 3: All Programs Die Quickly

**Symptom**: No multi-generational lineages

**Cause**: Mutation rate too high, wisdom not stabilizing strategies

**Solution**: Reduce `@base_mutation_rate` to 0.1-0.15

### Issue 4: No Diversification

**Symptom**: All programs converge to same genome

**Cause**: Wisdom influence too strong, suppressing variation

**Solution**: Reduce `@wisdom_influence_weight` to 0.2-0.3

---

## Future Enhancements

### Phase 1: Cross-World Wisdom Sharing

Allow institutions to learn from deaths in other worlds:

```elixir
wisdom = InstitutionalMemory.extract_cross_world_wisdom(state, [:w1, :w2, :w3])
```

### Phase 2: Temporal Wisdom Decay

Older lessons lose relevance as environment changes:

```elixir
weighted_wisdom = InstitutionalMemory.apply_temporal_decay(wisdom, current_tick)
```

### Phase 3: Contrarian Strategies

Occasionally spawn programs that deliberately violate wisdom:

```elixir
if :rand.uniform() < 0.05 do
  # 5% chance of contrarian mutation
  mutate_against_wisdom(parent_genome, wisdom)
else
  mutate_with_wisdom(parent_genome, wisdom)
end
```

### Phase 4: Meta-Learning

Institutions learn which types of wisdom are most predictive:

```elixir
meta_wisdom = %{
  exploration_warnings_accuracy: 0.85,
  validation_warnings_accuracy: 0.72,
  synthesis_recommendations_accuracy: 0.91
}
```

---

## Success Metrics

Track these metrics to validate institutional memory effectiveness:

1. **Generational Depth**: Max generation should increase over time
2. **Lifespan Improvement**: Average lifespan of later generations > earlier generations
3. **Trait Convergence**: Variance in successful genomes decreases over time
4. **Extinction Rate**: Should decrease as wisdom accumulates
5. **AFG (Adaptive Fitness Gradient)**: Should remain positive

---

## References

- Layer 6.5D Specification: `docs/layer6_5D.md`
- Reproduction Engine: `lib/tiannara/os/reproduction_engine.ex`
- Speciation Detector: `lib/tiannara/os/speciation_detector.ex`
- Test Suite: `test/tiannara/os/institutional_memory_test.exs`
