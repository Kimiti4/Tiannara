# scripts/rea_5_5_strategy_transplant.exs
defmodule Tiannara.REA.StrategyTransplantTest do
  @moduledoc """
  Phase REA-5.5: Strategy Transplant Test (Refined).
  
  Tests whether epistemic niches are heritable species or temporary environmental roles
  by measuring BEHAVIORAL RETENTION across transplanted environments.
  """
  require Logger

  @epochs 2_000
  @population_size 100
  @mutation_rate 0.05

  def run_transplant_battery() do
    Logger.info("🧬 [REA-5.5] Initiating Strategy Transplant Battery...")
    
    kg = generate_knowledge_graph(1_000)
    
    # We use mature weights representing established lineages from REA-5.4
    stable_compression_lineage = %{lineage_id: "L_COMP", heuristic_weights: [0.85, 0.05, 0.05, 0.05]}
    stable_exploration_lineage = %{lineage_id: "L_EXPL", heuristic_weights: [0.05, 0.85, 0.05, 0.05]}

    # 1. Control: Compression -> Compression World
    control_result = run_experiment(
      "Control: Compression -> Compression",
      stable_compression_lineage, 
      kg, 
      :compression_environment
    )
    
    # 2. Primary Transplant: Compression -> Exploration World
    primary_result = run_experiment(
      "Primary: Compression -> Exploration",
      stable_compression_lineage, 
      kg, 
      :exploration_environment
    )
    
    # 3. Reverse Transplant: Exploration -> Compression World
    reverse_result = run_experiment(
      "Reverse: Exploration -> Compression",
      stable_exploration_lineage, 
      kg, 
      :compression_environment
    )
    
    generate_comprehensive_verdict(control_result, primary_result, reverse_result)
  end

  defp run_experiment(experiment_name, source_lineage, kg, target_environment) do
    Logger.info("🔬 Running #{experiment_name}...")
    
    initial_pop = Enum.map(1..@population_size, fn i ->
      %{
        id: "#{experiment_name}_#{i}",
        lineage_id: source_lineage.lineage_id,
        heuristic_weights: source_lineage.heuristic_weights,
        fitness: 0.0,
        metrics: %{}
      }
    end)
    
    # Measure baseline behavior BEFORE transplant
    baseline_behavior = measure_population_behavior(initial_pop, kg)
    
    # Run evolution under target environment pressure
    {final_pop, _telemetry} = evolve_under_pressure(
      initial_pop, kg, @epochs, target_environment, []
    )
    
    # Measure post-transplant behavior and weights
    final_behavior = measure_population_behavior(final_pop, kg)
    final_weights = calculate_average_weights(final_pop)
    
    %{
      experiment: experiment_name,
      baseline_behavior: baseline_behavior,
      final_behavior: final_behavior,
      final_weights: final_weights,
      original_weights: source_lineage.heuristic_weights
    }
  end

  defp measure_population_behavior(pop, kg) do
    metrics_list = Enum.map(pop, fn agent ->
      traversal = simulate_weighted_walk(agent.heuristic_weights, kg, 50)
      %{
        compression_score: traversal.compression_score,
        exploration_score: traversal.novelty_score,
        prediction_score: traversal.prediction_score
      }
    end)
    
    avg_comp = Enum.sum(Enum.map(metrics_list, & &1.compression_score)) / length(metrics_list)
    avg_expl = Enum.sum(Enum.map(metrics_list, & &1.exploration_score)) / length(metrics_list)
    avg_pred = Enum.sum(Enum.map(metrics_list, & &1.prediction_score)) / length(metrics_list)
    
    %{
      compression: avg_comp,
      exploration: avg_expl,
      prediction: avg_pred
    }
  end

  defp evolve_under_pressure(pop, _kg, 0, _env, telemetry), do: {pop, telemetry}
  
  defp evolve_under_pressure(pop, kg, epochs_remaining, env, telemetry) do
    evaluated_pop = Enum.map(pop, fn agent ->
      traversal = simulate_weighted_walk(agent.heuristic_weights, kg, 50)
      
      metrics = %{
        compression_score: traversal.compression_score,
        exploration_score: traversal.novelty_score,
        prediction_score: traversal.prediction_score
      }
      
      # Fitness function uses a softer bias (50/35/15) to favor but not dictate a strategy
      fitness = case env do
        :compression_environment ->
          (metrics.compression_score * 0.50) + (metrics.exploration_score * 0.35) + (metrics.prediction_score * 0.15)
        :exploration_environment ->
          (metrics.exploration_score * 0.50) + (metrics.compression_score * 0.35) + (metrics.prediction_score * 0.15)
      end
      
      %{agent | fitness: fitness, metrics: metrics}
    end)
    
    # Tournament Selection
    survivors = Enum.map(1..@population_size, fn _ ->
      contenders = Enum.take_random(evaluated_pop, 3)
      Enum.max_by(contenders, & &1.fitness)
    end)
    
    # Mutation
    next_gen = Enum.map(survivors, fn parent ->
      if :rand.uniform() < @mutation_rate do
        new_weights = Enum.map(parent.heuristic_weights, fn w ->
          max(0.0, min(1.0, w + (:rand.uniform() - 0.5) * 0.2))
        end)
        %{parent | heuristic_weights: new_weights, fitness: 0.0, metrics: %{}}
      else
        %{parent | fitness: 0.0, metrics: %{}}
      end
    end)
    
    evolve_under_pressure(next_gen, kg, epochs_remaining - 1, env, telemetry)
  end

  defp calculate_average_weights(pop) do
    num_agents = length(pop)
    num_weights = length(hd(pop).heuristic_weights)
    
    Enum.map(0..(num_weights - 1), fn i ->
      Enum.sum(Enum.map(pop, fn agent -> Enum.at(agent.heuristic_weights, i) end)) / num_agents
    end)
  end

  defp generate_comprehensive_verdict(control, primary, reverse) do
    Logger.info("\n==================================================")
    Logger.info("📊 REA-5.5 STRATEGY TRANSPLANT VERDICT (REFINED)")
    Logger.info("==================================================")
    
    analyze_single_experiment("CONTROL", control)
    analyze_single_experiment("PRIMARY TRANSPLANT (Comp -> Expl)", primary)
    analyze_single_experiment("REVERSE TRANSPLANT (Expl -> Comp)", reverse)
    
    Logger.info("\n🏆 FINAL SYNTHESIS:")
    primary_bri = calculate_behavioral_retention(primary.baseline_behavior, primary.final_behavior)
    reverse_bri = calculate_behavioral_retention(reverse.baseline_behavior, reverse.final_behavior)
    
    Logger.info("   Primary Retention Index: #{Float.round(primary_bri, 3)}")
    Logger.info("   Reverse Retention Index: #{Float.round(reverse_bri, 3)}")
    
    avg_retention = (primary_bri + reverse_bri) / 2.0
    
    cond do
      avg_retention > 0.85 ->
        Logger.info("✅ CONCLUSION: TRUE EPISTEMIC SPECIES CONFIRMED.")
        Logger.info("   Lineages maintain core behavioral identity despite environmental pressure.")
        
      avg_retention < 0.35 ->
        Logger.info("🔄 CONCLUSION: CONTEXTUAL ECOLOGICAL ROLES CONFIRMED.")
        Logger.info("   Lineages rapidly convert to match the new environmental fitness landscape.")
        
      true ->
        Logger.info("🧬 CONCLUSION: EPISTEMIC SPECIES WITH PHENOTYPIC PLASTICITY.")
        Logger.info("   Core identity persists, but lineages exhibit adaptive drift to survive.")
    end
    
    if abs(primary_bri - reverse_bri) > 0.20 do
      Logger.info("\n⚠️ NOTE: ASYMMETRIC STABILITY DETECTED.")
      Logger.info("   One niche is significantly more resistant to environmental conversion.")
    end
    Logger.info("==================================================")
  end

  defp analyze_single_experiment(label, result) do
    Logger.info("\n🔬 EXPERIMENT: #{label}")
    Logger.info("   Baseline Behavior -> Comp: #{Float.round(result.baseline_behavior.compression, 3)} | Expl: #{Float.round(result.baseline_behavior.exploration, 3)} | Pred: #{Float.round(result.baseline_behavior.prediction, 3)}")
    Logger.info("   Final Behavior    -> Comp: #{Float.round(result.final_behavior.compression, 3)} | Expl: #{Float.round(result.final_behavior.exploration, 3)} | Pred: #{Float.round(result.final_behavior.prediction, 3)}")
    
    bri = calculate_behavioral_retention(result.baseline_behavior, result.final_behavior)
    Logger.info("   Behavioral Retention -> #{Float.round(bri, 3)}")
    
    weight_sim = calculate_cosine_similarity(result.original_weights, result.final_weights)
    Logger.info("   Weight Similarity    -> #{Float.round(weight_sim, 3)} (Secondary Metric)")
  end

  defp calculate_behavioral_retention(baseline, final) do
    # Euclidean distance between behavioral vectors
    distance = :math.sqrt(
      :math.pow(baseline.compression - final.compression, 2) + 
      :math.pow(baseline.exploration - final.exploration, 2) + 
      :math.pow(baseline.prediction - final.prediction, 2)
    )
    
    # Normalizing. Max practical distance across these metrics is ~1.0
    max(0.0, 1.0 - distance)
  end

  defp calculate_cosine_similarity(vec1, vec2) do
    dot_product = Enum.zip(vec1, vec2) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
    mag1 = :math.sqrt(Enum.sum(Enum.map(vec1, &(&1 * &1))))
    mag2 = :math.sqrt(Enum.sum(Enum.map(vec2, &(&1 * &1))))
    
    if mag1 == 0 or mag2 == 0, do: 0.0, else: dot_product / (mag1 * mag2)
  end

  # --- Simplified Helpers ---
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
    
    %{
      compression_score: comp_acc / steps, 
      novelty_score: nov_acc / steps, 
      prediction_score: pred_acc / steps
    }
  end
end

Tiannara.REA.StrategyTransplantTest.run_transplant_battery()
