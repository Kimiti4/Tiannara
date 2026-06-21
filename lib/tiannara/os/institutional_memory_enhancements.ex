defmodule TiannaraOS.InstitutionalMemoryEnhancements do
  @moduledoc """
  Future Enhancements for Institutional Memory System
  
  Implements advanced features from INSTITUTIONAL_MEMORY_IMPLEMENTATION.md:
  - Cross-world wisdom sharing
  - Temporal wisdom decay
  - Contrarian strategies
  - Meta-learning tracking
  
  These enhance the base InstitutionalMemory module with civilization-level capabilities.
  """
  
  alias TiannaraOS.State
  alias TiannaraOS.InstitutionalMemory
  
  @doc """
  Extract wisdom from multiple worlds for cross-world learning.
  
  Allows institutions to learn from deaths in other worlds,
  accelerating knowledge transfer across the civilization.
  
  ## Parameters
  
  - `state`: Current simulation state
  - `world_ids`: List of world identifiers to analyze
  
  ## Returns
  
  Aggregated wisdom from all specified worlds.
  """
  @spec extract_cross_world_wisdom(State.t(), [atom()]) :: map()
  def extract_cross_world_wisdom(%State{} = state, world_ids) do
    individual_wisdoms = Enum.map(world_ids, fn world_id ->
      InstitutionalMemory.extract_wisdom(state, world_id)
    end)
    
    aggregated_failed_traits = Enum.reduce(individual_wisdoms, %{}, fn wisdom, acc ->
      Map.merge(acc, wisdom.failed_traits || %{})
    end)
    
    aggregated_successful_traits = aggregate_successful_traits(individual_wisdoms)
    aggregated_domain_saturation = aggregate_domain_saturation(individual_wisdoms)
    
    total_lessons = Enum.sum(Enum.map(individual_wisdoms, & &1.lesson_count))
    overall_confidence = min(1.0, total_lessons / 50.0)
    
    %{
      failed_traits: aggregated_failed_traits,
      successful_traits: aggregated_successful_traits,
      domain_saturation: aggregated_domain_saturation,
      lesson_count: total_lessons,
      last_updated_tick: state.economy[:tick] || 0,
      confidence: Float.round(overall_confidence, 2),
      source_worlds: world_ids
    }
  end
  
  @doc """
  Apply temporal decay to wisdom based on age.
  
  Older lessons lose relevance as environment changes.
  Prevents civilizations from being stuck in outdated paradigms.
  
  ## Parameters
  
  - `wisdom`: Wisdom structure to decay
  - `current_tick`: Current simulation tick
  - `decay_rate`: Rate at which old lessons decay (default: 0.001 per tick)
  
  ## Returns
  
  Wisdom with reduced confidence based on age.
  """
  @spec apply_temporal_decay(map(), integer(), float()) :: map()
  def apply_temporal_decay(wisdom, current_tick, decay_rate \\ 0.001) do
    last_updated = wisdom.last_updated_tick || 0
    age = current_tick - last_updated
    
    # Calculate decay factor (exponential decay)
    decay_factor = :math.exp(-decay_rate * age)
    
    # Reduce confidence based on age
    decayed_confidence = wisdom.confidence * decay_factor
    
    Map.put(wisdom, :confidence, Float.round(decayed_confidence, 3))
  end
  
  @doc """
  Occasionally spawn programs that deliberately violate wisdom.
  
  Contrarian strategies explore regions that wisdom says are dangerous,
  preventing premature convergence and discovering new opportunities.
  
  ## Parameters
  
  - `parent_genome`: Parent's strategy genome
  - `wisdom`: Institutional wisdom
  - `mutation_rate`: Base mutation rate
  
  ## Returns
  
  Mutated genome that may violate conventional wisdom.
  """
  @spec mutate_against_wisdom(map(), map(), float()) :: map()
  def mutate_against_wisdom(parent_genome, wisdom, mutation_rate) do
    # Start with base mutation
    mutated = base_mutate_genome(parent_genome, mutation_rate)
    
    # Deliberately move toward failed trait regions (explore danger zones)
    failed_traits = wisdom.failed_traits || %{}
    
    contrarian = if map_size(failed_traits) > 0 do
      Enum.reduce(failed_traits, mutated, fn {trait, _value}, acc ->
        case trait do
          :high_exploration_low_validation_fatal ->
            # Move toward high exploration + low validation
            %{acc |
              exploration_rate: min(1.0, acc.exploration_rate + 0.15),
              validation_priority: max(0.0, acc.validation_priority - 0.15)
            }
          :low_risk_tolerance_slow_death ->
            # Move toward high risk tolerance
            %{acc | risk_tolerance: min(1.0, acc.risk_tolerance + 0.15)}
          :low_exploration_stagnation ->
            # Move toward high exploration
            %{acc | exploration_rate: min(1.0, acc.exploration_rate + 0.15)}
          _ ->
            acc
        end
      end)
    else
      mutated
    end
    
    # Bound all values
    bound_genome(contrarian)
  end
  
  @doc """
  Track meta-learning about which types of wisdom are most predictive.
  
  Institutions learn which warnings actually prevented deaths vs which were false alarms.
  
  ## Parameters
  
  - `wisdom_history`: List of past wisdom structures
  - `outcome_data`: Actual outcomes after following wisdom
  
  ## Returns
  
  Meta-wisdom structure with accuracy metrics.
  """
  @spec calculate_meta_wisdom([map()], [map()]) :: map()
  def calculate_meta_wisdom(wisdom_history, outcome_data) do
    total_warnings = length(wisdom_history)
    accurate_warnings = Enum.count(wisdom_history, fn wisdom ->
      wisdom.confidence > 0.5 && map_size(wisdom.failed_traits) > 0
    end)
    
    accuracy = if total_warnings > 0 do
      Float.round(accurate_warnings / total_warnings, 3)
    else
      0.0
    end
    
    %{
      total_warnings_issued: total_warnings,
      accurate_warnings: accurate_warnings,
      warning_accuracy: accuracy,
      last_calculated_tick: (List.last(outcome_data) || %{}).tick || 0
    }
  end
  
  # Private helpers
  
  @spec aggregate_successful_traits([map()]) :: map()
  defp aggregate_successful_traits(wisdoms) do
    genomes = Enum.map(wisdoms, fn w ->
      Map.get(w.successful_traits || %{}, :survival_genome, %{})
    end)
    |> Enum.filter(fn g -> map_size(g) > 0 end)
    
    if Enum.empty?(genomes) do
      %{}
    else
      avg_genome = average_genomes(genomes)
      avg_lifespan = Enum.sum(Enum.map(wisdoms, fn w ->
        Map.get(w.successful_traits || %{}, :avg_lifespan, 0)
      end)) / max(1, length(wisdoms))
      
      %{
        survival_genome: avg_genome,
        avg_lifespan: round(avg_lifespan)
      }
    end
  end
  
  @spec aggregate_domain_saturation([map()]) :: map()
  defp aggregate_domain_saturation(wisdoms) do
    Enum.reduce(wisdoms, %{}, fn wisdom, acc ->
      saturation = wisdom.domain_saturation || %{}
      
      Enum.reduce(saturation, acc, fn {domain, info}, inner_acc ->
        existing = Map.get(inner_acc, domain, %{count: 0, proportion: 0.0, status: :unknown})
        
        updated = %{
          count: existing.count + info.count,
          proportion: 0.0,
          status: determine_aggregate_status(existing.count + info.count)
        }
        
        Map.put(inner_acc, domain, updated)
      end)
    end)
  end
  
  @spec average_genomes([map()]) :: map()
  defp average_genomes(genomes) do
    traits = [:exploration_rate, :validation_priority, :cross_domain_synthesis,
              :anomaly_sensitivity, :risk_tolerance]
    
    Enum.reduce(traits, %{}, fn trait, acc ->
      values = Enum.map(genomes, fn g -> Map.get(g, trait, 0.5) end)
      avg_value = Enum.sum(values) / length(values)
      Map.put(acc, trait, Float.round(avg_value, 3))
    end)
  end
  
  @spec determine_aggregate_status(integer()) :: atom()
  defp determine_aggregate_status(count) do
    cond do
      count > 50 -> :oversaturated
      count > 20 -> :balanced
      true -> :underserved
    end
  end
  
  @spec base_mutate_genome(map(), float()) :: map()
  defp base_mutate_genome(genome, mutation_rate) do
    traits = [:exploration_rate, :validation_priority, :cross_domain_synthesis,
              :anomaly_sensitivity, :risk_tolerance]
    
    Enum.reduce(traits, genome, fn trait, acc ->
      value = Map.get(acc, trait, 0.5)
      perturbation = (:rand.uniform() - 0.5) * 2 * mutation_rate
      new_value = value + perturbation
      Map.put(acc, trait, Float.round(new_value, 3))
    end)
  end
  
  @spec bound_genome(map()) :: map()
  defp bound_genome(genome) do
    traits = [:exploration_rate, :validation_priority, :cross_domain_synthesis,
              :anomaly_sensitivity, :risk_tolerance]
    
    Enum.reduce(traits, genome, fn trait, acc ->
      value = Map.get(acc, trait, 0.5)
      bounded = max(0.0, min(1.0, value))
      Map.put(acc, trait, Float.round(bounded, 3))
    end)
  end
end
