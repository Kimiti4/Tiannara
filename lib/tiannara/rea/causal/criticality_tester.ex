defmodule Tiannara.REA.Causal.CriticalityTester do
  @moduledoc """
  Measures the full criticality landscape of causal channels.
  Includes removal, scaling, delay, replacement testing, bottleneck scoring,
  and evolutionary replaceability tracking.
  """
  
  alias Tiannara.REA.{SimulationRunner, LineageRegistry, ArchaeologyRegistry}
  alias Tiannara.REA.Causal.{Graph, ChannelMonitor, Topology, Channel}
  
  @type criticality_profile :: %{
    channel_id: binary(),
    channel_name: atom(),
    removal_damage: float(),
    weight_increase_damage: float(),
    weight_decrease_damage: float(),
    delay_increase_damage: float(),
    delay_decrease_damage: float(),
    optimal_weight: float(),
    optimal_delay: integer(),
    bottleneck_score: float(),
    replaceability: float(),
    criticality_score: float(),
    classification: :constitutional | :structural | :adaptive | :experimental,
    protected_for: [atom() | binary()]
  }
  
  @doc "Run full criticality analysis on all channels."
  def analyze_all(channels, baseline_config) do
    channels
    |> Enum.map(&analyze_channel(&1, baseline_config))
    |> classify_channels()
    |> Enum.sort_by(& &1.criticality_score, :desc)
  end
  
  @doc "Analyze a single channel's criticality profile."
  def analyze_channel(channel, baseline_config) do
    IO.puts("  🔬 Analyzing: #{channel.name}")
    
    # Baseline run
    baseline = run_configured(baseline_config, [])
    
    # Removal test
    removal = run_configured(baseline_config, remove: channel.id)
    removal_damage = compute_damage(baseline, removal)
    
    # Weight increase (2x)
    weight_up = run_configured(baseline_config, modify_weight: {channel.id, 2.0})
    weight_up_damage = compute_damage(baseline, weight_up)
    
    # Weight decrease (0.5x)
    weight_down = run_configured(baseline_config, modify_weight: {channel.id, 0.5})
    weight_down_damage = compute_damage(baseline, weight_down)
    
    # Delay increase (+2 epochs)
    delay_up = run_configured(baseline_config, modify_delay: {channel.id, +2})
    delay_up_damage = compute_damage(baseline, delay_up)
    
    # Delay decrease (-1 epoch, min 0)
    delay_down = run_configured(baseline_config, modify_delay: {channel.id, -1})
    delay_down_damage = compute_damage(baseline, delay_down)
    
    # Find optimal operating point
    optimal_weight = find_optimal_weight(channel, baseline_config, baseline)
    optimal_delay = find_optimal_delay(channel, baseline_config, baseline)
    
    # NEW: Measure evolutionary elasticity
    elasticity = measure_elasticity(channel, baseline_config, baseline)
    
    # Replacement test & Replaceability score
    {replaceability_score, avg_replacement_damage} = test_replacements(channel, baseline_config, baseline)
    
    # Bottleneck score: heuristic based on average signal throughput volume vs ecosystem size
    # High if removing the channel halts system diversity significantly compared to just weight down
    bottleneck = compute_bottleneck(channel, baseline_config, baseline, removal_damage)
    
    # Overall criticality score (weighted sum of damages + non-replaceability + bottleneck)
    criticality =
      (removal_damage * 0.4) +
      (abs(weight_up_damage) * 0.15) +
      (abs(weight_down_damage) * 0.15) +
      (abs(delay_up_damage) * 0.15) +
      (abs(delay_down_damage) * 0.15)
    
    %{
      channel_id: channel.id,
      channel_name: channel.name,
      removal_damage: removal_damage,
      weight_increase_damage: weight_up_damage,
      weight_decrease_damage: weight_down_damage,
      delay_increase_damage: delay_up_damage,
      delay_decrease_damage: delay_down_damage,
      optimal_weight: optimal_weight,
      optimal_delay: optimal_delay,
      bottleneck: bottleneck,
      replaceability: replaceability_score,
      evolutionary_elasticity: elasticity,
      criticality_score: criticality,
      classification: :pending,
      protected_for: [:global] # By default in REA-2.75 script, later expanded per lineage
    }
  end
  
  defp run_configured(config, modifications) do
    # Reset state safely
    if Code.ensure_loaded?(LineageRegistry), do: LineageRegistry.reset()
    if Code.ensure_loaded?(ArchaeologyRegistry), do: ArchaeologyRegistry.reset()
    ChannelMonitor.reset()
    Graph.flush()
    Graph.load_topology(Topology.default())
    
    # Apply modifications
    Enum.each(modifications, fn
      {:remove, ch_id} -> Graph.set_enabled(ch_id, false)
      {:modify_weight, {ch_id, factor}} -> modify_channel_param(ch_id, :weight, factor)
      {:modify_delay, {ch_id, delta}} -> modify_channel_param(ch_id, :delay, delta)
      {:replace_source, {ch_id, new_source}} -> replace_channel_source(ch_id, new_source)
    end)
    
    # Run simulation (shortened for criticality testing)
    short_config = %{config | epochs: min(config.epochs, 500)}
    result = SimulationRunner.run(short_config)
    
    extract_metrics(result.universe)
  end
  
  defp modify_channel_param(ch_id, param, value) do
    channel = Graph.all() |> Enum.find(&(&1.id == ch_id))
    if channel do
      updated = case param do
        :weight -> %{channel | weight: channel.weight * value}
        :delay -> %{channel | delay: max(0, channel.delay + value)}
      end
      Graph.register(updated)
    end
  end
  
  defp replace_channel_source(ch_id, new_source) do
    channel = Graph.all() |> Enum.find(&(&1.id == ch_id))
    if channel do
      updated = %{channel | source: new_source}
      Graph.register(updated)
    end
  end
  
  defp compute_damage(baseline, modified) do
    delta_diversity = modified.diversity - baseline.diversity
    delta_truth = modified.truth_retention - baseline.truth_retention
    delta_resilience = modified.resilience - baseline.resilience
    delta_extinctions = modified.extinctions - baseline.extinctions
    
    # Negative impact = higher damage
    damage =
      (-delta_diversity * 0.3) +
      (-delta_truth * 0.3) +
      (-delta_resilience * 0.2) +
      (delta_extinctions * 0.005)
      
    damage
  end
  
  defp extract_metrics(universe) do
    %{
      diversity: compute_avg_diversity(universe),
      truth_retention: compute_avg_truth_retention(universe),
      resilience: compute_avg_resilience(universe),
      extinctions: count_total_extinctions(universe)
    }
  end
  
  defp find_optimal_weight(channel, config, baseline) do
    weights = [0.5, 0.75, 1.0, 1.25, 1.5]
    results = Enum.map(weights, fn factor ->
      modified = run_configured(config, modify_weight: {channel.id, factor})
      {factor, compute_damage(baseline, modified)}
    end)
    
    {optimal_factor, _} = Enum.min_by(results, &elem(&1, 1))
    channel.weight * optimal_factor
  end
  
  defp find_optimal_delay(channel, config, baseline) do
    deltas = [-1, 0, 1, 2]
    results = Enum.map(deltas, fn delta ->
      modified = run_configured(config, modify_delay: {channel.id, delta})
      {delta, compute_damage(baseline, modified)}
    end)
    
    {optimal_delta, _} = Enum.min_by(results, &elem(&1, 1))
    max(0, channel.delay + optimal_delta)
  end
  
  defp test_replacements(channel, config, baseline) do
    # Try replacing the source signal with a few alternatives from the same population
    alternatives = get_alternative_signals(channel.source.population, channel.source.signal)
    
    if Enum.empty?(alternatives) do
      {0.0, compute_damage(baseline, run_configured(config, remove: channel.id))} # Unreplaceable
    else
      results = Enum.map(alternatives, fn alt_signal ->
        new_source = %{channel.source | signal: alt_signal}
        modified = run_configured(config, replace_source: {channel.id, new_source})
        dmg = compute_damage(baseline, modified)
        
        # Successful replacement if damage is near 0 or negative (better)
        success = if dmg < 0.1, do: 1.0, else: 0.0
        {success, dmg}
      end)
      
      attempts = length(alternatives)
      successful = results |> Enum.map(&elem(&1, 0)) |> Enum.sum()
      replaceability = successful / attempts
      avg_damage = results |> Enum.map(&elem(&1, 1)) |> Enum.sum() |> Kernel./(attempts)
      
      {replaceability, avg_damage}
    end
  end
  
  defp get_alternative_signals(:civilization, current), do: [:economic_output, :cohesion, :truth_retention, :compute_capacity] |> List.delete(current)
  defp get_alternative_signals(:epistemology, current), do: [:adaptability, :coherence, :cognitive_yield, :symmetry_stability] |> List.delete(current)
  defp get_alternative_signals(:law_species, current), do: [:diversity_index, :innovation_rate, :perturbation_survival, :symmetry_stability] |> List.delete(current)
  defp get_alternative_signals(:meta_genome, current), do: [:resilience, :diversity_index, :innovation_rate] |> List.delete(current)
  defp get_alternative_signals(_, _), do: []
  
  defp classify_channels(profiles) do
    Enum.map(profiles, fn p ->
      classification = cond do
        p.removal_damage > 0.5 and p.replaceability < 0.25 -> :constitutional
        p.removal_damage > 0.3 or p.bottleneck_score > 0.6 -> :structural
        p.replaceability >= 0.5 and p.removal_damage > 0.0 -> :adaptive
        true -> :experimental
      end
      %{p | classification: classification}
    end)
  end
  
  # Metric extraction helpers
  defp compute_avg_diversity(universe) do
    universe.metrics
    |> Enum.map(fn {_, m} -> Map.get(m, :diversity, 0.0) end)
    |> Enum.sum()
    |> Kernel./(max(map_size(universe.metrics), 1))
  end
  
  defp compute_avg_truth_retention(universe) do
    case universe.populations[:civilization] do
      nil -> 0.0
      pop ->
        if length(pop.organisms) == 0, do: 0.0, else:
          pop.organisms
          |> Enum.map(&Map.get(&1, :truth_stock, 0.0))
          |> Enum.sum()
          |> Kernel./(max(length(pop.organisms), 1))
    end
  end
  
  defp compute_avg_resilience(universe) do
    case universe.populations[:meta_genome] do
      nil -> 0.0
      pop ->
        if length(pop.organisms) == 0, do: 0.0, else:
          pop.organisms
          |> Enum.map(&Map.get(&1, :resilience, 0.0))
          |> Enum.sum()
          |> Kernel./(max(length(pop.organisms), 1))
    end
  end
  
  defp count_total_extinctions(universe) do
    universe.metrics
    |> Enum.map(fn {_, m} -> Map.get(m, :extinctions, 0) end)
    |> Enum.sum()
  end
  
  @doc """
  Measure evolutionary elasticity: how much can the channel be modified
  before system health degrades by 10%?

  Returns a value 0.0 to 1.0 where:
    0.0 = extremely fragile (any perturbation causes 10% degradation)
    1.0 = extremely robust (can be doubled/halved without 10% degradation)
  """
  @spec measure_elasticity(Channel.t(), map(), map()) :: float()
  def measure_elasticity(channel, config, baseline) do
    # Test progressive weight modifications until 10% degradation
    degradation_threshold = 0.10  # 10% degradation

    # Find maximum weight multiplier before degradation
    max_weight_factor = find_elasticity_limit(channel, config, baseline, :weight, 1.0, 3.0, degradation_threshold)

    # Find minimum weight multiplier before degradation
    min_weight_factor = find_elasticity_limit(channel, config, baseline, :weight, 1.0, 0.1, degradation_threshold)

    # Find maximum delay addition before degradation
    max_delay_delta = find_elasticity_limit(channel, config, baseline, :delay, 0, 5, degradation_threshold)

    # Elasticity = average of normalized tolerances
    weight_range = abs(max_weight_factor - min_weight_factor)
    delay_range = max_delay_delta

    # Normalize: weight range of 2.0 (0.5x to 2.5x) = 1.0 elasticity
    # Delay range of 3 epochs = 1.0 elasticity
    normalized_weight = min(weight_range / 2.0, 1.0)
    normalized_delay = min(delay_range / 3.0, 1.0)

    (normalized_weight * 0.7 + normalized_delay * 0.3) |> min(1.0) |> max(0.0)
  end

  defp find_elasticity_limit(channel, config, baseline, param, start_val, end_val, threshold) do
    # Binary search for the limit
    steps = 10
    step_size = (end_val - start_val) / steps

    Enum.reduce_while(0..steps, start_val, fn i, _acc ->
      test_val = start_val + i * step_size
      modification = case param do
        :weight -> {:modify_weight, {channel.id, test_val}}
        :delay -> {:modify_delay, {channel.id, trunc(test_val)}}
      end

      modified = run_configured(config, [modification])
      damage = compute_damage(baseline, modified)

      if damage >= threshold do
        {:halt, test_val - step_size}
      else
        {:cont, test_val}
      end
    end)
  end

  defp compute_bottleneck(_channel, _config, _baseline, removal_damage) do
    # Bottleneck = how much the system relies on this exact channel
    # High bottleneck = system collapses without it
    # Normalize removal damage to 0-1 scale
    min(removal_damage / 2.0, 1.0)
  end
end
