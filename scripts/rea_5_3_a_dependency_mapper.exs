# scripts/rea_5_3_a_dependency_mapper.exs
defmodule Tiannara.REA.ResourceDependencyMapper do
  @moduledoc """
  Phase REA-5.3A: Candidate Dependency Mapping.
  
  Analyzes time-series telemetry to measure actual metabolic flows between 
  cognitive niches, replacing hardcoded assumptions with empirical cross-correlation
  and asymmetry logic.
  """
  require Logger

  @epochs 3_000
  @population_size 100
  @mutation_rate 0.05
  @snapshot_interval 50 # High-resolution sampling for time-series analysis
  @max_lag 5 # Measure dependencies up to 5 snapshot intervals in the past (250 epochs)

  def run() do
    Logger.info("🧪 [REA-5.3A] Generating baseline unperturbed telemetry for Dependency Mapping...")
    kg = generate_knowledge_graph(1_000)
    base_pop = generate_diverse_initial_population()
    
    # We only run the control environment to see natural metabolic flows
    {_pop, _lineage, telemetry} = evolve_with_pressure(
      base_pop, kg, @epochs, %{"root" => %{parent: nil, generation: 0}}, []
    )
    
    # telemetry is collected with latest at head. Reverse it to chronological order.
    chronological_telemetry = Enum.reverse(telemetry) |> List.flatten()
    analyze_dependencies(chronological_telemetry)
  end

  def analyze_dependencies(telemetry_log) do
    Logger.info("🔬 [REA-5.3A] Initiating Candidate Dependency Mapping...")
    
    niche_timeseries = group_by_niche_and_epoch(telemetry_log)
    dependency_matrix = calculate_lagged_correlations(niche_timeseries)
    
    generate_dependency_report(dependency_matrix)
  end

  defp group_by_niche_and_epoch(telemetry_log) do
    Enum.group_by(telemetry_log, & &1.niche)
    |> Map.new(fn {niche, records} ->
      sorted_records = Enum.sort_by(records, & &1.epoch)
      {niche, %{
        novelty: Enum.map(sorted_records, & &1.avg_novelty),
        compression: Enum.map(sorted_records, & &1.avg_compression),
        prediction: Enum.map(sorted_records, & &1.avg_prediction)
      }}
    end)
  end

  defp calculate_lagged_correlations(niche_timeseries) do
    niches = Map.keys(niche_timeseries)
    metrics = [:novelty, :compression, :prediction]
    
    # Store all in a flat map for easy reverse lookup
    all_correlations = for producer <- niches, p_metric <- metrics, consumer <- niches, c_metric <- metrics, producer != consumer, into: %{} do
      best_lag = find_best_lag_correlation(niche_timeseries[producer][p_metric], niche_timeseries[consumer][c_metric], @max_lag)
      {{producer, p_metric, consumer, c_metric}, best_lag}
    end
    
    all_correlations
  end

  defp find_best_lag_correlation(producer_series, consumer_series, max_lag) do
    min_len = min(length(producer_series), length(consumer_series))
    p_trimmed = Enum.take(producer_series, min_len)
    c_trimmed = Enum.take(consumer_series, min_len)
    
    correlations = for lag <- 1..max_lag do
      p_shifted = Enum.drop(p_trimmed, lag)
      c_target = Enum.take(c_trimmed, min_len - lag)
      
      if length(p_shifted) > 2 do
        r = calculate_pearson_r(p_shifted, c_target)
        %{lag: lag, strength: abs(r), raw_r: r}
      else
        %{lag: lag, strength: 0.0, raw_r: 0.0}
      end
    end
    
    Enum.max_by(correlations, & &1.strength, fn -> %{lag: 0, strength: 0.0, raw_r: 0.0} end)
  end

  defp calculate_pearson_r(x, y) do
    n = length(x)
    if n == 0 do
      0.0
    else
      sum_x = Enum.sum(x)
      sum_y = Enum.sum(y)
      sum_xy = Enum.sum(Enum.zip(x, y) |> Enum.map(fn {a, b} -> a * b end))
      sum_x2 = Enum.sum(Enum.map(x, fn a -> a * a end))
      sum_y2 = Enum.sum(Enum.map(y, fn a -> a * a end))
      
      numerator = n * sum_xy - sum_x * sum_y
      denominator = :math.sqrt(max(0.0, n * sum_x2 - sum_x * sum_x)) * :math.sqrt(max(0.0, n * sum_y2 - sum_y * sum_y))
      
      if denominator == 0.0, do: 0.0, else: numerator / denominator
    end
  end

  defp generate_dependency_report(all_correlations) do
    Logger.info("\n==================================================")
    Logger.info("📊 REA-5.3A CANDIDATE DEPENDENCY MATRIX")
    Logger.info("==================================================")
    Logger.info("Format: [Producer] --(produces Metric A)--> [Consumer] --(consumes Metric B)")
    Logger.info("--------------------------------------------------")
    
    strong_deps = Enum.filter(all_correlations, fn {_, v} -> v.strength > 0.4 end)
    
    if length(strong_deps) == 0 do
      Logger.info("No strong dependencies (r > 0.4) discovered. Niches are metabolically independent.")
    else
      grouped = Enum.group_by(strong_deps, fn {{p, pm, _, _}, _} -> {p, pm} end)
      
      grouped
      |> Enum.sort_by(fn {{p, pm}, _} -> {p, pm} end)
      |> Enum.each(fn {{producer, p_metric}, deps} ->
        Logger.info("\n🌱 PRODUCER: #{String.capitalize(to_string(producer))} (Metric: #{p_metric})")
        
        deps
        |> Enum.sort_by(fn {_, best_lag} -> best_lag.strength end, :desc)
        |> Enum.each(fn {{_, _, consumer, c_metric}, best_lag} ->
          reverse_key = {consumer, c_metric, producer, p_metric}
          reverse_lag = all_correlations[reverse_key] || %{strength: 0.0}
          
          # Asymmetry tells us if this is a directional flow or just mutual correlation
          asymmetry = best_lag.strength - reverse_lag.strength
          
          Logger.info("   ↳ Candidate flow into #{String.capitalize(to_string(consumer))}'s #{c_metric}")
          Logger.info("      (r: #{Float.round(best_lag.raw_r, 2)} | Lag: #{best_lag.lag * @snapshot_interval} epochs | Asymmetry: #{Float.round(asymmetry, 2)})")
          Logger.info("      Reverse (Mutual) r: #{Float.round(reverse_lag.raw_r, 2)}")
        end)
      end)
    end
    
    Logger.info("\n==================================================")
    Logger.info("🔍 INTERPRETATION GUIDE:")
    Logger.info("• High r & High Asymmetry: True directional candidate dependency.")
    Logger.info("• High r & Low Asymmetry: Mutual correlation (likely a shared hidden factor Z).")
    Logger.info("• No significant correlations: Niches are metabolically independent.")
    Logger.info("==================================================")
  end

  # --- Evolution Engine adapted to export detailed niche telemetry ---
  
  defp evolve_with_pressure(pop, _kg, 0, _lineage, telemetry), do: {pop, _lineage, telemetry}
  
  defp evolve_with_pressure(pop, kg, epochs_remaining, lineage, telemetry) do
    current_epoch = @epochs - epochs_remaining + 1
    
    evaluated_pop = Enum.map(pop, fn agent ->
      traversal = simulate_weighted_walk(agent.heuristic_weights, kg, 50)
      metrics = %{
        predictive_compression_ratio: traversal.compression_score,
        novelty_yield: traversal.novelty_score,
        prediction_accuracy: traversal.prediction_score
      }
      
      base_fitness = (metrics.predictive_compression_ratio * 0.4) + 
                     (metrics.novelty_yield * 0.4) + 
                     (metrics.prediction_accuracy * 0.2)
                     
      %{agent | fitness: base_fitness, metrics: metrics}
    end)
    
    survivors = Enum.map(1..@population_size, fn _ ->
      contenders = Enum.take_random(evaluated_pop, 3)
      Enum.max_by(contenders, & &1.fitness)
    end)
    
    {next_gen, new_lineage} = Enum.map_reduce(survivors, lineage, fn parent, current_lineage ->
      child_id = System.unique_integer([:positive])
      child = if :rand.uniform() < @mutation_rate do
        new_weights = Enum.map(parent.heuristic_weights, fn w ->
          max(0.0, min(1.0, w + (:rand.uniform() - 0.5) * 0.2))
        end)
        %{parent | id: child_id, lineage_id: parent.lineage_id, heuristic_weights: new_weights, fitness: 0.0, metrics: parent.metrics}
      else
        %{parent | id: child_id, lineage_id: parent.lineage_id, fitness: 0.0, metrics: parent.metrics}
      end
      
      updated_lineage = Map.put(current_lineage, child_id, %{
        parent: parent.id,
        lineage_id: parent.lineage_id,
        generation: (current_lineage[parent.id][:generation] || 0) + 1
      })
      {child, updated_lineage}
    end)
    
    new_telemetry = if rem(current_epoch, @snapshot_interval) == 0 do
      [record_detailed_niche_snapshot(next_gen, current_epoch) | telemetry]
    else
      telemetry
    end
    
    evolve_with_pressure(next_gen, kg, epochs_remaining - 1, new_lineage, new_telemetry)
  end

  defp classify_niche_by_behavior(metrics) do
    cond do
      metrics.predictive_compression_ratio >= 0.844 -> :compression
      metrics.novelty_yield >= 0.718 -> :exploration
      metrics.prediction_accuracy >= 0.725 -> :prediction
      true -> :generalist
    end
  end

  defp record_detailed_niche_snapshot(pop, epoch) do
    niches = Enum.group_by(pop, fn agent -> classify_niche_by_behavior(agent.metrics) end)
    
    Enum.map([:compression, :exploration, :prediction, :generalist], fn niche ->
      agents = niches[niche] || []
      count = length(agents)
      
      if count > 0 do
        avg_comp = Enum.sum(Enum.map(agents, & &1.metrics.predictive_compression_ratio)) / count
        avg_nov = Enum.sum(Enum.map(agents, & &1.metrics.novelty_yield)) / count
        avg_pred = Enum.sum(Enum.map(agents, & &1.metrics.prediction_accuracy)) / count
        %{epoch: epoch, niche: niche, avg_compression: avg_comp, avg_novelty: avg_nov, avg_prediction: avg_pred, count: count}
      else
        # If a niche is extinct at this snapshot, pad it with the global averages or zero. Using 0.0 might cause extreme correlation drops, so we pad with 0.0.
        %{epoch: epoch, niche: niche, avg_compression: 0.0, avg_novelty: 0.0, avg_prediction: 0.0, count: 0}
      end
    end)
  end

  defp generate_diverse_initial_population do
    Enum.map(1..@population_size, fn i ->
      weights = case rem(i, 4) do
        0 -> [0.8, 0.3, 0.3, 0.3]
        1 -> [0.3, 0.8, 0.3, 0.3]
        2 -> [0.3, 0.3, 0.8, 0.3]
        3 -> [0.5, 0.5, 0.5, 0.5]
      end
      %{
        id: "init_#{i}", 
        lineage_id: "lineage_#{i}",
        heuristic_weights: weights, 
        fitness: 0.0, 
        metrics: %{}
      }
    end)
  end

  defp generate_knowledge_graph(size) do
    :rand.seed(:exsss, {1, 2, 3})
    nodes = Enum.reduce(0..(size-1), %{}, fn i, acc ->
      Map.put(acc, i, %{
        id: i, shortcut_potential: :rand.uniform(), novelty_value: :rand.uniform(), consistency: :rand.uniform(),
        neighbors: Enum.map(1..10, fn _ -> :rand.uniform(size) - 1 end) |> Enum.uniq() |> List.delete(i)
      })
    end)
    %{nodes: nodes, total_active_nodes: size}
  end

  defp simulate_weighted_walk([w_comp, w_expl, w_pred, w_gen], kg, steps) do
    start_node = :rand.uniform(kg.total_active_nodes) - 1
    {_visited, comp_acc, nov_acc, pred_acc} = Enum.reduce(1..steps, {MapSet.new([start_node]), 0.0, 0.0, 0.0}, fn _, {visited_set, c, n, p} ->
      current_node = kg.nodes[Enum.random(MapSet.to_list(visited_set))]
      best_neighbor_id = current_node.neighbors |> Enum.max_by(fn n_id -> 
        neighbor = kg.nodes[n_id]
        score = (w_comp * neighbor.shortcut_potential) + (w_expl * neighbor.novelty_value) + (w_pred * neighbor.consistency) + (w_gen * :rand.uniform())
        score - (if MapSet.member?(visited_set, n_id), do: w_expl * 0.5, else: 0.0)
      end, fn -> Enum.random(current_node.neighbors) end)
      
      chosen = kg.nodes[best_neighbor_id]
      {MapSet.put(visited_set, best_neighbor_id), c + chosen.shortcut_potential, n + chosen.novelty_value, p + chosen.consistency}
    end)
    %{compression_score: comp_acc / steps, novelty_score: nov_acc / steps, prediction_score: pred_acc / steps}
  end
end

Tiannara.REA.ResourceDependencyMapper.run()
