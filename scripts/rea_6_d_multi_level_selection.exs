# scripts/rea_6_d_multi_level_selection.exs
defmodule Tiannara.REA.MultiLevelSelectionTest do
  @moduledoc """
  Phase REA-6D: Selection Decomposition.
  
  Tests whether changing the selection tensor (Multi-Level Selection)
  from individual fitness to network/dependency fitness can create 
  epistemic civilization (persistent interdependent graphs).
  """
  require Logger

  @epochs 1_500
  @population_size 100
  @hmt_frequency 0.20
  
  @baseline_comp 0.40
  @baseline_expl 0.35
  @baseline_pred 0.45

  def run_matrix() do
    Logger.info("🌌 [REA-6D] Initiating Multi-Level Selection Sweep...")
    
    kg = generate_knowledge_graph(1_000)
    
    sweeps = [
      {1.00, 0.00, 0.00}, # 100 / 0 / 0
      {0.75, 0.25, 0.00}, # 75 / 25 / 0
      {0.50, 0.50, 0.00}, # 50 / 50 / 0
      {0.25, 0.75, 0.00}, # 25 / 75 / 0
      {0.00, 1.00, 0.00}, # 0 / 100 / 0
      {0.50, 0.25, 0.25}, # 50 / 25 / 25
      {0.25, 0.50, 0.25}, # 25 / 50 / 25
      {0.25, 0.25, 0.50}, # 25 / 25 / 50
      {0.00, 0.00, 1.00}  # 0 / 0 / 100
    ]
    
    results = Enum.map(sweeps, fn sweep ->
      run_single_sweep(sweep, kg)
    end)
    
    print_matrix(results)
  end

  defp run_single_sweep({w_a, w_n, w_l} = sweep, kg) do
    sweep_name = "#{trunc(w_a*100)}/#{trunc(w_n*100)}/#{trunc(w_l*100)}"
    Logger.info("🔬 Testing MLS Tensor [Agent: #{trunc(w_a*100)}% | Neigh: #{trunc(w_n*100)}% | Lin: #{trunc(w_l*100)}%]")
    
    base_pop = generate_ecological_population()
    lineage_registry = initialize_lineage_registry(base_pop)
    
    {final_pop, telemetry, _reg} = evolve_mls(
      base_pop, kg, @epochs, lineage_registry, sweep, %{}, []
    )
    
    final_snapshot = List.first(telemetry)
    
    # Analyze the telemetry over the run
    avg_gini = telemetry |> Enum.map(& &1.gini) |> mean()
    avg_div = telemetry |> Enum.map(& &1.diversity) |> mean()
    max_borrowing = telemetry |> Enum.map(& &1.borrowing_count) |> Enum.max()
    max_adoption = telemetry |> Enum.map(& &1.adoption_count) |> Enum.max()
    
    avg_dep_strength = telemetry |> Enum.map(& &1.mean_dependency_strength) |> mean()
    max_dep_persistence = telemetry |> Enum.map(& &1.max_dependency_persistence) |> Enum.max()
    
    %{
      sweep: sweep_name,
      gini: avg_gini,
      diversity: avg_div,
      borrowing: max_borrowing,
      adoption: max_adoption,
      dep_strength: avg_dep_strength,
      dep_persistence: max_dep_persistence
    }
  end

  defp evolve_mls(pop, _kg, 0, registry, _sweep, _persistence_map, telemetry), do: {pop, telemetry, registry}
  
  defp evolve_mls(pop, kg, epochs_remaining, registry, {w_a, w_n, w_l} = sweep, persistence_map, telemetry) do
    current_epoch = @epochs - epochs_remaining + 1
    
    # 1. Base Walk (Individual Fitness)
    base_evaluated = Enum.map(pop, fn agent ->
      {traversal, visited_nodes} = simulate_weighted_walk(agent.heuristic_weights, kg, 50, [])
      metrics = %{
        compression_score: traversal.compression_score,
        exploration_score: traversal.novelty_score,
        prediction_score: traversal.prediction_score
      }
      fitness = (metrics.compression_score * 0.33) + (metrics.exploration_score * 0.33) + (metrics.prediction_score * 0.34)
      Map.merge(agent, %{raw_fitness: fitness, base_metrics: metrics, artifact: visited_nodes})
    end)
    
    # 2. Interaction Phase (Empirical Dependency)
    # Agents pair up. Each agent attempts to give its artifact to 2 neighbors.
    interactions = Enum.flat_map(base_evaluated, fn agent ->
      neighbors = Enum.take_random(base_evaluated |> Enum.reject(& &1.id == agent.id), 2)
      Enum.map(neighbors, fn neighbor -> {agent, neighbor} end)
    end)
    
    # Evaluate marginal contributions
    marginal_contributions = Enum.map(interactions, fn {supplier, consumer} ->
      # Consumer takes Supplier's artifact as starting points
      {traversal, _} = simulate_weighted_walk(consumer.heuristic_weights, kg, 50, Enum.take(MapSet.to_list(supplier.artifact), 5))
      new_fitness = (traversal.compression_score * 0.33) + (traversal.novelty_score * 0.33) + (traversal.prediction_score * 0.34)
      
      boost = max(0.0, new_fitness - consumer.raw_fitness)
      %{supplier_id: supplier.id, consumer_id: consumer.id, s_lineage: supplier.lineage_id, c_lineage: consumer.lineage_id, boost: boost}
    end)
    
    # Accumulate neighborhood fitness
    supplier_boosts = Enum.group_by(marginal_contributions, & &1.supplier_id)
    
    # Update Persistence Map
    new_persistence_map = Enum.reduce(marginal_contributions, persistence_map, fn interaction, acc ->
      if interaction.boost > 0.05 do
        key = {interaction.s_lineage, interaction.c_lineage}
        Map.update(acc, key, 1, & &1 + 1)
      else
        acc
      end
    end)
    
    max_persistence = if map_size(new_persistence_map) > 0, do: Enum.max(Map.values(new_persistence_map)), else: 0

    # 3. Lineage Fitness Update
    updated_registry = update_lineage_registry(base_evaluated, registry, current_epoch)
    
    # 4. Composite Fitness Calculation
    evaluated_pop = Enum.map(base_evaluated, fn agent ->
      f_agent = agent.raw_fitness
      
      agent_boosts = Map.get(supplier_boosts, agent.id, [])
      f_neigh = if length(agent_boosts) > 0 do
        Enum.sum(Enum.map(agent_boosts, & &1.boost))
      else
        0.0
      end
      
      f_lin = calculate_lineage_ema(updated_registry[agent.lineage_id].fitness_history)
      
      total_fitness = (w_a * f_agent) + (w_n * f_neigh) + (w_l * f_lin)
      Map.merge(agent, %{composite_fitness: total_fitness, f_neigh: f_neigh, f_lin: f_lin, metrics: agent.base_metrics})
    end)
    
    # 5. Tournament Selection (Based on Composite Fitness)
    survivors = Enum.map(1..@population_size, fn _ ->
      contenders = Enum.take_random(evaluated_pop, 3)
      Enum.max_by(contenders, & &1.composite_fitness)
    end)
    
    # 6. Reproduction
    {next_gen, final_registry} = Enum.map_reduce(survivors, updated_registry, fn parent, current_registry ->
      child_id = "agent_#{System.unique_integer([:positive])}"
      
      {child_weights, mentor_lineage_id} = if :rand.uniform() < @hmt_frequency do
        mentor = Enum.random(survivors)
        if mentor.id != parent.id do
          hybrid_weights = blend_weights(parent.heuristic_weights, mentor.heuristic_weights, 0.70)
          {hybrid_weights, mentor.lineage_id}
        else
          {mutate_weights(parent.heuristic_weights), nil}
        end
      else
        {mutate_weights(parent.heuristic_weights), nil}
      end
      
      child = %{
        id: child_id,
        lineage_id: parent.lineage_id,
        parent_id: parent.id,
        mentor_lineage_id: mentor_lineage_id,
        ancestral_weights: parent.ancestral_weights,
        original_niche: parent.original_niche,
        heuristic_weights: child_weights,
        raw_fitness: 0.0,
        composite_fitness: 0.0,
        metrics: %{}
      }
      {child, current_registry}
    end)
    
    # 7. Telemetry
    mean_dep_strength = if length(marginal_contributions) > 0, do: mean(Enum.map(marginal_contributions, & &1.boost)), else: 0.0
    
    new_telemetry = if epochs_remaining == 1 or rem(current_epoch, 100) == 0 do
      [record_snapshot(evaluated_pop, current_epoch, updated_registry, mean_dep_strength, max_persistence) | telemetry]
    else
      telemetry
    end
    
    evolve_mls(next_gen, kg, epochs_remaining - 1, final_registry, sweep, new_persistence_map, new_telemetry)
  end

  # =========================================================================
  # CORE LOGIC
  # =========================================================================

  defp generate_ecological_population() do
    # 80% Compression, 10% Exploration, 10% Prediction
    Enum.map(1..@population_size, fn i ->
      {weights, niche, lineage_id} = cond do
        i <= 80 -> {[0.85, 0.30, 0.30, 0.30], :compression, "L_COMP"}
        i <= 90 -> {[0.30, 0.85, 0.30, 0.30], :exploration, "L_EXPL"}
        true    -> {[0.30, 0.30, 0.85, 0.30], :prediction,  "L_PRED"}
      end
      
      %{
        id: "culture_init_#{i}", lineage_id: lineage_id, parent_id: nil, mentor_lineage_id: nil,
        ancestral_weights: weights, original_niche: niche, heuristic_weights: weights, raw_fitness: 0.0, composite_fitness: 0.0, metrics: %{}
      }
    end)
  end

  defp update_lineage_registry(evaluated_pop, registry, current_epoch) do
    active_lineages = Enum.group_by(evaluated_pop, & &1.lineage_id)
    
    Enum.reduce(active_lineages, registry, fn {lineage_id, agents}, reg ->
      avg_raw = mean(Enum.map(agents, & &1.raw_fitness))
      
      Map.update!(reg, lineage_id, fn data ->
        history = [avg_raw | Enum.take(data.fitness_history, 99)]
        %{data | fitness_history: history}
      end)
    end)
  end

  defp calculate_lineage_ema([]), do: 0.0
  defp calculate_lineage_ema(history) do
    # Simple moving average for stability
    mean(history)
  end

  defp record_snapshot(pop, epoch, registry, mean_dep, max_persistence) do
    comp_scores = Enum.map(pop, & &1.metrics.compression_score)
    expl_scores = Enum.map(pop, & &1.metrics.exploration_score)
    pred_scores = Enum.map(pop, & &1.metrics.prediction_score)
    
    comp_thresh = max(mean(comp_scores) + 0.5 * std_dev(comp_scores), @baseline_comp)
    expl_thresh = max(mean(expl_scores) + 0.5 * std_dev(expl_scores), @baseline_expl)
    pred_thresh = max(mean(pred_scores) + 0.5 * std_dev(pred_scores), @baseline_pred)
    
    {borrowing_ids, adoption_ids} = 
      Enum.reduce(pop, {[], []}, fn agent, {b, a} ->
        metrics = agent.metrics
        reg_data = registry[agent.lineage_id]
        original_niche = reg_data.original_niche
        current_niche = get_dominant_niche(metrics)
        
        is_secondary_elevated = secondary_elevated?(metrics, original_niche, comp_thresh, expl_thresh, pred_thresh)
        is_borrowing = is_secondary_elevated
        is_adoption = current_niche != original_niche
        
        cond do
          is_adoption -> { b, [agent.lineage_id | a] }
          current_niche == original_niche and is_borrowing -> { [agent.lineage_id | b], a }
          true -> { b, a }
        end
      end)
      
    lineage_counts = Enum.frequencies(Enum.map(pop, & &1.lineage_id))
    gini = calculate_gini(Map.values(lineage_counts))
    diversity = calculate_shannon(Map.values(lineage_counts), @population_size)
    
    %{
      epoch: epoch,
      gini: gini,
      diversity: diversity,
      borrowing_count: length(borrowing_ids),
      adoption_count: length(adoption_ids),
      mean_dependency_strength: mean_dep,
      max_dependency_persistence: max_persistence
    }
  end

  defp print_matrix(results) do
    Logger.info("\n==========================================================================")
    Logger.info("🌌 REA-6D MULTI-LEVEL SELECTION MATRIX (TENSOR SWEEP)")
    Logger.info("==========================================================================")
    Logger.info("MLS Tensor | Gini  | Shannon | Borrow | Adopt | Dep. Str. | Max Dep. Pers.")
    Logger.info("--------------------------------------------------------------------------")
    
    Enum.each(results, fn r ->
      t = "#{r.sweep}" |> String.pad_trailing(10)
      g = Float.round(r.gini, 3) |> Float.to_string() |> String.pad_trailing(5)
      d = Float.round(r.diversity, 3) |> Float.to_string() |> String.pad_trailing(7)
      b = "#{r.borrowing}" |> String.pad_trailing(6)
      a = "#{r.adoption}" |> String.pad_trailing(5)
      ds = Float.round(r.dep_strength, 3) |> Float.to_string() |> String.pad_trailing(9)
      dp = "#{r.dep_persistence} eps"
      
      Logger.info("#{t} | #{g} | #{d} | #{b} | #{a} | #{ds} | #{dp}")
    end)
    
    Logger.info("==========================================================================")
  end

  # =========================================================================
  # HELPER FUNCTIONS
  # =========================================================================

  defp mean(list), do: if(length(list) == 0, do: 0.0, else: Enum.sum(list) / length(list))
  defp std_dev(list) do
    m = mean(list)
    if length(list) == 0, do: 0.0, else: :math.sqrt(Enum.sum(Enum.map(list, fn x -> :math.pow(x - m, 2) end)) / length(list))
  end
  defp get_dominant_niche(metrics) do
    cond do
      metrics.compression_score > 0.75 -> :compression
      metrics.exploration_score > 0.60 -> :exploration
      metrics.prediction_score > 0.80 -> :prediction
      true -> :generalist
    end
  end
  defp secondary_elevated?(metrics, original_niche, comp_t, expl_t, pred_t) do
    case original_niche do
      :compression -> metrics.exploration_score > expl_t or metrics.prediction_score > pred_t
      :exploration -> metrics.compression_score > comp_t or metrics.prediction_score > pred_t
      :prediction  -> metrics.compression_score > comp_t or metrics.exploration_score > expl_t
      _ -> false
    end
  end
  defp blend_weights(parent_w, mentor_w, parent_retention) do
    Enum.zip(parent_w, mentor_w) |> Enum.map(fn {p, m} -> (p * parent_retention) + (m * (1.0 - parent_retention)) end)
  end
  defp mutate_weights(weights) do
    Enum.map(weights, fn w -> max(0.0, min(1.0, w + (:rand.uniform() - 0.5) * 0.15)) end)
  end
  
  defp initialize_lineage_registry(pop) do
    Map.new(pop, fn agent -> 
      {agent.lineage_id, %{
        original_niche: agent.original_niche,
        fitness_history: []
      }} 
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
  
  defp simulate_weighted_walk([w_comp, w_expl, w_pred, w_gen], kg, steps, start_nodes) do
    start_node = if length(start_nodes) > 0, do: Enum.random(start_nodes), else: :rand.uniform(kg.total_active_nodes) - 1
    
    {visited, comp_acc, nov_acc, pred_acc} = Enum.reduce(1..steps, {MapSet.new([start_node]), 0.0, 0.0, 0.0}, fn _, {visited_set, c, n, p} ->
      current_node = kg.nodes[Enum.random(MapSet.to_list(visited_set))]
      best_neighbor_id = current_node.neighbors |> Enum.max_by(fn n_id -> 
        neighbor = kg.nodes[n_id]
        score = (w_comp * neighbor.shortcut_potential) + (w_expl * neighbor.novelty_value) + (w_pred * neighbor.consistency) + (w_gen * :rand.uniform())
        score - (if MapSet.member?(visited_set, n_id), do: w_expl * 0.5, else: 0.0)
      end, fn -> Enum.random(current_node.neighbors) end)
      
      chosen = kg.nodes[best_neighbor_id]
      {MapSet.put(visited_set, best_neighbor_id), c + chosen.shortcut_potential, n + chosen.novelty_value, p + chosen.consistency}
    end)
    
    {%{compression_score: comp_acc / steps, novelty_score: nov_acc / steps, prediction_score: pred_acc / steps}, visited}
  end

  defp calculate_gini(counts) do
    n = length(counts)
    if n <= 1 do
      0.0
    else
      sorted = Enum.sort(counts)
      total = Enum.sum(sorted)
      if total == 0 do
        0.0
      else
        numerator = Enum.with_index(sorted, 1) |> Enum.map(fn {v, i} -> i * v end) |> Enum.sum()
        (2.0 * numerator) / (n * total) - ((n + 1.0) / n)
      end
    end
  end

  defp calculate_shannon(counts, total) do
    if total == 0 do
      0.0
    else
      counts
      |> Enum.filter(& &1 > 0)
      |> Enum.map(fn c -> 
        p = c / total
        -p * :math.log2(p)
      end)
      |> Enum.sum()
    end
  end
end

Tiannara.REA.MultiLevelSelectionTest.run_matrix()
