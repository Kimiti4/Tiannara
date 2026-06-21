defmodule TiannaraOS.InstitutionalMemory do
  @moduledoc """
  Institutional Memory System - Layer 6.5D Sprint 2
  
  Extracts evolutionary lessons from program deaths and feeds them back
  into reproduction decisions. This is what separates civilizations from ecosystems.
  
  Civilizations accumulate wisdom from previous generations:
  - What strategies lead to death?
  - What traits correlate with survival?
  - Which domains are oversaturated?
  - What discovery patterns work?
  
  This wisdom influences mutation in ReproductionEngine, preventing
  offspring from repeating ancestral mistakes.
  """
  
  alias TiannaraOS.State
  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.Discovery
  
  # Minimum deaths before extracting patterns
  @min_deaths_for_analysis 3
    
  # Weight given to institutional wisdom vs random mutation
  @wisdom_influence_weight 0.4
    
  # Base mutation rate (matches reproduction engine)
  @base_mutation_rate 0.2
  
  @doc """
  Extract wisdom from graveyard for a specific world.
  
  Returns structured lessons that guide mutation decisions.
  
  ## Example
  
      wisdom = InstitutionalMemory.extract_wisdom(state, :w1_medicine)
      # => %{
      #   failed_traits: %{high_exploration_fatal: true, ...},
      #   successful_traits: %{survival_genome: %{...}, ...},
      #   domain_saturation: %{energy: :oversaturated, ...},
      #   lesson_count: 47
      # }
  """
  @spec extract_wisdom(State.t(), atom()) :: map()
  def extract_wisdom(%State{} = state, world_id) do
    graveyard = state.program_graveyard || %{}
    
    # Get all deaths in this world
    world_deaths = graveyard
      |> Enum.filter(fn {_id, record} ->
        record.world_id == world_id
      end)
      |> Enum.map(fn {_id, record} -> record end)
    
    if length(world_deaths) < @min_deaths_for_analysis do
      # Not enough death data for trait analysis, but still analyze domain saturation
      domain_saturation = analyze_domain_saturation(state, world_id, world_deaths)
      
      %{
        failed_traits: %{},
        successful_traits: %{},
        domain_saturation: domain_saturation,
        lesson_count: length(world_deaths),
        last_updated_tick: state.economy[:tick] || 0,
        confidence: 0.0
      }
    else
      # Analyze failure patterns
      failed_traits = analyze_failure_patterns(world_deaths)
      
      # Analyze success patterns
      successful_traits = analyze_success_patterns(world_deaths)
      
      # Analyze domain saturation
      domain_saturation = analyze_domain_saturation(state, world_id, world_deaths)
      
      # Calculate confidence based on sample size
      confidence = min(1.0, length(world_deaths) / 50.0)
      
      %{
        failed_traits: failed_traits,
        successful_traits: successful_traits,
        domain_saturation: domain_saturation,
        lesson_count: length(world_deaths),
        last_updated_tick: state.economy[:tick] || 0,
        confidence: Float.round(confidence, 2)
      }
    end
  end
  
  @doc """
  Apply institutional wisdom to mutate a genome.
  
  Wisdom influences mutation direction but doesn't override it completely.
  Uses weighted combination of random mutation and guided adjustment.
  
  ## Parameters
  
  - `genome`: Parent's strategy genome
  - `wisdom`: Extracted wisdom from graveyard
  - `mutation_rate`: Base mutation rate (0.0-1.0)
  
  ## Returns
  
  Mutated genome influenced by ancestral lessons.
  """
  @spec apply_wisdom_to_mutation(map(), map(), float()) :: map()
  def apply_wisdom_to_mutation(genome, wisdom, mutation_rate) do
    failed_traits = wisdom.failed_traits || %{}
    successful_traits = wisdom.successful_traits || %{}
    confidence = wisdom.confidence || 0.0
    
    # Start with base mutation
    mutated = base_mutate_genome(genome, mutation_rate)
    
    # Apply wisdom-guided adjustments (weighted by confidence)
    adjusted = if confidence > 0.1 do
      # Adjust based on failed traits
      after_failure_adjustment = adjust_for_failed_traits(mutated, failed_traits, confidence)
      
      # Adjust toward successful traits
      adjust_toward_success(after_failure_adjustment, successful_traits, confidence)
    else
      mutated
    end
    
    # Ensure all values bounded [0, 1]
    bound_genome(adjusted)
  end
  
  @doc """
  High-level wrapper for wisdom-guided mutation with contrarian exploration.
  
  Implements the desired 80/15/5 split:
  - 80% wisdom-guided mutation
  - 15% exploratory mutation
  - 5% contrarian mutation
  
  ## Parameters
  
  - `parent_genome`: Parent's strategy genome
  - `wisdom`: Extracted wisdom from graveyard
  
  ## Returns
  
  Child genome with appropriate mutation strategy.
  """
  @spec mutate_from_wisdom(map(), map()) :: map()
  def mutate_from_wisdom(parent_genome, wisdom) do
    # Determine mutation strategy based on probability
    roll = :rand.uniform()
    
    mutated_genome = cond do
      roll < 0.05 ->
        # 5% contrarian mutation - deliberately violate wisdom
        mutate_against_wisdom(parent_genome, wisdom, @base_mutation_rate * 1.5)
      
      roll < 0.20 ->
        # 15% pure exploratory mutation - no wisdom guidance
        base_mutate_genome(parent_genome, @base_mutation_rate * 1.2)
        |> bound_genome()
      
      true ->
        # 80% wisdom-guided mutation
        apply_wisdom_to_mutation(parent_genome, wisdom, @base_mutation_rate)
    end
    
    mutated_genome
  end
  
  @doc """
  Summarize institutional memory for reporting.
  
  Returns human-readable summary of accumulated wisdom.
  """
  @spec summarize_wisdom(map()) :: String.t()
  def summarize_wisdom(wisdom) do
    lines = [
      "=== Institutional Memory Summary ===",
      "Lessons learned: #{wisdom.lesson_count}",
      "Confidence: #{Float.round(wisdom.confidence * 100, 1)}%",
      "",
      "Failed Traits:",
      format_failed_traits(wisdom.failed_traits),
      "",
      "Successful Traits:",
      format_successful_traits(wisdom.successful_traits),
      "",
      "Domain Saturation:",
      format_domain_saturation(wisdom.domain_saturation)
    ]
    
    Enum.join(lines, "\n")
  end
  
  # ============================================================================
  # Private Functions - Failure Pattern Analysis
  # ============================================================================
  
  @doc false
  @spec analyze_failure_patterns([map()]) :: map()
  defp analyze_failure_patterns(death_records) do
    # Group deaths by cause
    resource_deaths = filter_by_cause(death_records, :resource_exhaustion)
    stagnation_deaths = filter_by_cause(death_records, :stagnation)
    competition_deaths = filter_by_cause(death_records, :competitive_displacement)
    
    # Analyze each death type
    resource_insights = analyze_resource_deaths(resource_deaths)
    stagnation_insights = analyze_stagnation_deaths(stagnation_deaths)
    competition_insights = analyze_competition_deaths(competition_deaths)
    
    Map.merge(resource_insights, 
      Map.merge(stagnation_insights, competition_insights))
  end
  
  @doc false
  @spec filter_by_cause([map()], atom()) :: [map()]
  defp filter_by_cause(records, cause) do
    Enum.filter(records, & &1.cause_of_death == cause)
  end
  
  @doc false
  @spec analyze_resource_deaths([map()]) :: map()
  defp analyze_resource_deaths(deaths) do
    if length(deaths) < 3 do
      %{}
    else
      # Calculate average traits of programs that died from resource exhaustion
      avg_genome = average_genome(Enum.map(deaths, & &1.strategy_genome))
      avg_lifespan = average_lifespan(deaths)
      
      insights = %{}
      
      # High exploration without validation is fatal
      insights = if avg_genome.exploration_rate > 0.7 and avg_genome.validation_priority < 0.3 do
        Map.put(insights, :high_exploration_low_validation_fatal, true)
      else
        insights
      end
      
      # Low risk tolerance leads to slow death
      insights = if avg_genome.risk_tolerance < 0.3 do
        Map.put(insights, :low_risk_tolerance_slow_death, true)
      else
        insights
      end
      
      # Very short lifespan indicates poor strategy
      insights = if avg_lifespan < 1000 do
        Map.put(insights, :short_lifespan_strategy, avg_genome)
      else
        insights
      end
      
      insights
    end
  end
  
  @doc false
  @spec analyze_stagnation_deaths([map()]) :: map()
  defp analyze_stagnation_deaths(deaths) do
    if length(deaths) < 3 do
      %{}
    else
      avg_genome = average_genome(Enum.map(deaths, & &1.strategy_genome))
      
      insights = %{}
      
      # Low exploration leads to stagnation
      if avg_genome.exploration_rate < 0.3 do
        Map.put(insights, :low_exploration_stagnation, true)
      end
      
      # Low synthesis prevents breakthroughs
      if avg_genome.cross_domain_synthesis < 0.2 do
        Map.put(insights, :low_synthesis_no_breakthroughs, true)
      end
      
      insights
    end
  end
  
  @doc false
  @spec analyze_competition_deaths([map()]) :: map()
  defp analyze_competition_deaths(deaths) do
    if length(deaths) < 3 do
      %{}
    else
      avg_genome = average_genome(Enum.map(deaths, & &1.strategy_genome))
      
      insights = %{}
      
      # High anomaly sensitivity without validation loses to competitors
      if avg_genome.anomaly_sensitivity > 0.8 and avg_genome.validation_priority < 0.4 do
        Map.put(insights, :unvalidated_anomalies_lose_competition, true)
      end
      
      insights
    end
  end
  
  # ============================================================================
  # Private Functions - Success Pattern Analysis
  # ============================================================================
  
  @doc false
  @spec analyze_success_patterns([map()]) :: map()
  defp analyze_success_patterns(death_records) do
    # Find long-lived programs (top 20% by lifespan)
    sorted = Enum.sort_by(death_records, & &1.lifespan_ticks, :desc)
    top_count = max(3, round(length(sorted) * 0.2))
    long_lived = Enum.take(sorted, top_count)
    
    if length(long_lived) < 3 do
      %{}
    else
      avg_genome = average_genome(Enum.map(long_lived, & &1.strategy_genome))
      avg_lifespan = average_lifespan(long_lived)
      avg_assets = average_assets(long_lived)
      
      %{
        survival_genome: avg_genome,
        avg_lifespan: Float.round(avg_lifespan, 0),
        avg_asset_count: Float.round(avg_assets, 1),
        recommended_min_lifespan: Float.round(avg_lifespan * 0.5, 0)
      }
    end
  end
  
  # ============================================================================
  # Private Functions - Domain Saturation Analysis
  # ============================================================================
  
  @doc false
  @spec analyze_domain_saturation(State.t(), atom(), [map()]) :: map()
  defp analyze_domain_saturation(%State{} = state, world_id, _deaths) do
    # Count discoveries by domain in this world
    discoveries = state.discoveries || %{}
    
    world_discoveries = discoveries
      |> Enum.filter(fn {_id, disc} ->
        Map.get(disc, :origin_world_id) == world_id
      end)
      |> Enum.map(fn {_id, disc} -> disc end)
    
    if Enum.empty?(world_discoveries) do
      %{}
    else
      # Count discoveries per domain
      domain_counts = Enum.reduce(world_discoveries, %{}, fn disc, acc ->
        domain_vector = Map.get(disc.metadata || %{}, :domain_vector, %{})
        
        domain = if map_size(domain_vector) > 0 do
          domain_vector
            |> Enum.max_by(fn {_k, v} -> v end, fn -> {:unknown, 0.0} end)
            |> elem(0)
        else
          :unknown
        end
        
        Map.update(acc, domain, 1, & &1 + 1)
      end)
      
      total = Enum.sum(Map.values(domain_counts))
      
      # Identify oversaturated (>30%) and underserved (<10%) domains
      Enum.reduce(domain_counts, %{}, fn {domain, count}, acc ->
        proportion = count / max(1, total)
        
        status = cond do
          proportion > 0.3 -> :oversaturated
          proportion < 0.1 -> :underserved
          true -> :balanced
        end
        
        Map.put(acc, domain, %{count: count, proportion: Float.round(proportion, 2), status: status})
      end)
    end
  end
  
  # ============================================================================
  # Private Functions - Mutation Application
  # ============================================================================
  
  @doc false
  @spec base_mutate_genome(map(), float()) :: map()
  defp base_mutate_genome(genome, mutation_rate) do
    traits = [:exploration_rate, :validation_priority, :cross_domain_synthesis,
              :anomaly_sensitivity, :risk_tolerance]
    
    Enum.reduce(traits, genome, fn trait, acc ->
      current_value = Map.get(acc, trait, 0.5)
      mutated_value = gaussian_mutate(current_value, mutation_rate)
      Map.put(acc, trait, Float.round(mutated_value, 2))
    end)
  end
  
  @doc false
  @spec adjust_for_failed_traits(map(), map(), float()) :: map()
  defp adjust_for_failed_traits(genome, failed_traits, confidence) do
    adjusted = genome
    
    # If high exploration + low validation is fatal, push away from that region
    if Map.get(failed_traits, :high_exploration_low_validation_fatal) do
      if genome.exploration_rate > 0.6 and genome.validation_priority < 0.4 do
        # Reduce exploration, increase validation
        adjusted = %{adjusted |
          exploration_rate: max(0.2, genome.exploration_rate - 0.3 * confidence),
          validation_priority: min(0.9, genome.validation_priority + 0.3 * confidence)
        }
      end
    end
    
    # If low risk tolerance leads to slow death, increase risk tolerance
    if Map.get(failed_traits, :low_risk_tolerance_slow_death) do
      if genome.risk_tolerance < 0.3 do
        adjusted = %{adjusted |
          risk_tolerance: min(0.7, genome.risk_tolerance + 0.2 * confidence)
        }
      end
    end
    
    # If low exploration causes stagnation, boost exploration
    if Map.get(failed_traits, :low_exploration_stagnation) do
      if genome.exploration_rate < 0.3 do
        adjusted = %{adjusted |
          exploration_rate: min(0.8, genome.exploration_rate + 0.2 * confidence)
        }
      end
    end
    
    adjusted
  end
  
  @doc false
  @spec adjust_toward_success(map(), map(), float()) :: map()
  defp adjust_toward_success(genome, successful_traits, confidence) do
    case Map.get(successful_traits, :survival_genome) do
      nil -> genome
      
      survival_genome ->
        # Move genome toward successful pattern (weighted by confidence)
        traits = [:exploration_rate, :validation_priority, :cross_domain_synthesis,
                  :anomaly_sensitivity, :risk_tolerance]
        
        Enum.reduce(traits, genome, fn trait, acc ->
          current = Map.get(acc, trait, 0.5)
          target = Map.get(survival_genome, trait, 0.5)
          
          # Blend toward target
          blended = current + (target - current) * @wisdom_influence_weight * confidence
          Map.put(acc, trait, Float.round(blended, 2))
        end)
    end
  end
  
  @doc false
  @spec bound_genome(map()) :: map()
  defp bound_genome(genome) do
    traits = [:exploration_rate, :validation_priority, :cross_domain_synthesis,
              :anomaly_sensitivity, :risk_tolerance]
    
    Enum.reduce(traits, genome, fn trait, acc ->
      value = Map.get(acc, trait, 0.5)
      bounded = max(0.0, min(1.0, value))
      Map.put(acc, trait, Float.round(bounded, 2))
    end)
  end
  
  # ============================================================================
  # Helper Functions
  # ============================================================================
  
  @doc false
  @spec average_genome([map()]) :: map()
  defp average_genome(genomes) do
    traits = [:exploration_rate, :validation_priority, :cross_domain_synthesis,
              :anomaly_sensitivity, :risk_tolerance]
    
    Enum.reduce(traits, %{}, fn trait, acc ->
      values = Enum.map(genomes, & Map.get(&1, trait, 0.5))
      avg = Enum.sum(values) / max(1, length(values))
      Map.put(acc, trait, Float.round(avg, 2))
    end)
  end
  
  @doc false
  @spec average_lifespan([map()]) :: float()
  defp average_lifespan(records) do
    lifespans = Enum.map(records, & &1.lifespan_ticks)
    Enum.sum(lifespans) / max(1, length(lifespans))
  end
  
  @doc false
  @spec average_assets([map()]) :: float()
  defp average_assets(records) do
    asset_counts = Enum.map(records, fn r ->
      length(r.assets_at_death || [])
    end)
    Enum.sum(asset_counts) / max(1, length(asset_counts))
  end
  
  @doc false
  @spec gaussian_mutate(float(), float()) :: float()
  defp gaussian_mutate(value, mutation_rate) do
    # Box-Muller transform for approximate normal distribution
    u1 = max(:rand.uniform(), 0.0001)
    u2 = :rand.uniform()
    
    z = :math.sqrt(-2.0 * :math.log(u1)) * :math.cos(2.0 * :math.pi * u2)
    perturbation = z * mutation_rate
    
    value + perturbation
  end
  
  @doc false
  @spec format_failed_traits(map()) :: String.t()
  defp format_failed_traits(traits) do
    if map_size(traits) == 0 do
      "  (insufficient data)"
    else
      Enum.map_join(traits, "\n", fn {trait, value} ->
        "  - #{trait}: #{inspect(value)}"
      end)
    end
  end
  
  @doc false
  @spec format_successful_traits(map()) :: String.t()
  defp format_successful_traits(traits) do
    if map_size(traits) == 0 do
      "  (insufficient data)"
    else
      genome = Map.get(traits, :survival_genome, %{})
      lifespan = Map.get(traits, :avg_lifespan, 0)
      
      "  Survival Genome: #{inspect(genome)}\n  Avg Lifespan: #{lifespan} ticks"
    end
  end
  
  @doc false
  @spec format_domain_saturation(map()) :: String.t()
  defp format_domain_saturation(saturation) do
    if map_size(saturation) == 0 do
      "  (no discoveries yet)"
    else
      Enum.map_join(saturation, "\n", fn {domain, info} ->
        "  - #{domain}: #{info.count} discoveries (#{Float.round(info.proportion * 100, 1)}%) [#{info.status}]"
      end)
    end
  end
  
  # ============================================================================
  # Future Enhancements (from INSTITUTIONAL_MEMORY_IMPLEMENTATION.md)
  # ============================================================================
  
  @doc """
  Extract wisdom from multiple worlds for cross-world learning.
  
  Allows institutions to learn from deaths in other worlds,
  accelerating knowledge transfer across the civilization.
  """
  @spec extract_cross_world_wisdom(State.t(), [atom()]) :: map()
  def extract_cross_world_wisdom(%State{} = state, world_ids) do
    individual_wisdoms = Enum.map(world_ids, fn world_id ->
      extract_wisdom(state, world_id)
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
  """
  @spec apply_temporal_decay(map(), integer(), float()) :: map()
  def apply_temporal_decay(wisdom, current_tick, decay_rate \\ 0.001) do
    last_updated = wisdom.last_updated_tick || 0
    age = current_tick - last_updated
    decay_factor = :math.exp(-decay_rate * age)
    decayed_confidence = wisdom.confidence * decay_factor
    
    %{wisdom |
      confidence: Float.round(decayed_confidence, 3),
      aged_ticks: age
    }
  end
  
  @doc """
  Occasionally spawn programs that deliberately violate wisdom.
  
  Contrarian strategies explore regions that wisdom says are dangerous.
  """
  @spec mutate_against_wisdom(map(), map(), float()) :: map()
  def mutate_against_wisdom(parent_genome, wisdom, mutation_rate) do
    mutated = base_mutate_genome(parent_genome, mutation_rate)
    
    failed_traits = wisdom.failed_traits || %{}
    
    contrarian = if map_size(failed_traits) > 0 do
      Enum.reduce(failed_traits, mutated, fn {trait, _value}, acc ->
        case trait do
          :high_exploration_low_validation_fatal ->
            %{acc |
              exploration_rate: min(1.0, acc.exploration_rate + 0.15),
              validation_priority: max(0.0, acc.validation_priority - 0.15)
            }
          :low_risk_tolerance_slow_death ->
            %{acc | risk_tolerance: min(1.0, acc.risk_tolerance + 0.15)}
          :low_exploration_stagnation ->
            %{acc | exploration_rate: min(1.0, acc.exploration_rate + 0.15)}
          _ ->
            acc
        end
      end)
    else
      mutated
    end
    
    bound_genome(contrarian)
  end
  
  @doc """
  Track meta-learning about which types of wisdom are most predictive.
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
end
