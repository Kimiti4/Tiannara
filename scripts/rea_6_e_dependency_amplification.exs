# scripts/rea_6_e_dependency_amplification.exs
defmodule Tiannara.REA.DependencyAmplificationTest do
  @moduledoc """
  Phase REA-6E: Dependency Amplification.
  
  Tests whether amplifying the F_neighborhood (Dependency Strength) signal 
  can artificially force the emergence of persistent civilization structures,
  proving whether Darwinian selection is capable of maintaining them under high trade pressure.
  """
  require Logger

  @epochs 1_500
  @population_size 100
  @hmt_frequency 0.20
  
  @baseline_comp 0.40
  @baseline_expl 0.35
  @baseline_pred 0.45

  def run_matrix() do
    Logger.info("🌌 [REA-6E] Initiating Dependency Amplification Sweep...")
    
    kg = generate_knowledge_graph(1_000)
    
    sweeps = [
      {0.50, 0.50, 0.00, 0.0},     # Control A (0x)
      {0.50, 0.50, 0.00, 1.0},     # 1x
      {0.50, 0.50, 0.00, 5.0},     # 5x
      {0.50, 0.50, 0.00, 10.0},    # 10x
      {0.50, 0.50, 0.00, 25.0},    # 25x
      {0.50, 0.50, 0.00, 50.0},    # 50x
      {0.50, 0.50, 0.00, 100.0},   # 100x
      {0.50, 0.50, 0.00, 250.0},   # 250x
      {0.50, 0.50, 0.00, 500.0},   # 500x
      {0.00, 1.00, 0.00, 50.0}     # Control B (0/100/0 at 50x)
    ]
    
    results = Enum.map(sweeps, fn sweep ->
      run_single_sweep(sweep, kg)
    end)
    
    print_matrix(results)
  end

  defp run_single_sweep({w_a, w_n, w_l, amp} = sweep, kg) do
    sweep_name = if amp == 0.0, do: "0x (C:A)", else: (if w_a == 0.0, do: "#{trunc(amp)}x (C:B)", else: "#{trunc(amp)}x")
    Logger.info("🔬 Testing Amp: #{sweep_name} [#{trunc(w_a*100)}/#{trunc(w_n*100)}/#{trunc(w_l*100)}]")
    
    base_pop = generate_ecological_population()
    lineage_registry = initialize_lineage_registry(base_pop)
    
    {_final_pop, telemetry, _reg} = evolve_mls(
      base_pop, kg, @epochs, lineage_registry, sweep, %{}, []
    )
    
    # Calculate aggregates from telemetry
    avg_gini = telemetry |> Enum.map(& &1.gini) |> mean()
    avg_div = telemetry |> Enum.map(& &1.diversity) |> mean()
    max_borrowing = telemetry |> Enum.map(& &1.borrowing_count) |> Enum.max()
    max_adoption = telemetry |> Enum.map(& &1.adoption_count) |> Enum.max()
    
    # Persistence Metrics
    final_persistence_map = List.first(telemetry).persistence_map
    pers_values = Map.values(final_persistence_map)
    mean_pers = mean(pers_values)
    max_pers = if length(pers_values) > 0, do: Enum.max(pers_values), else: 0.0
    p95_pers = calculate_percentile(pers_values, 0.95)
    
    # Cross-Niche Ratio
    avg_cnr = telemetry |> Enum.map(& &1.cross_niche_ratio) |> mean()
    
    # Dependency Concentration (Gini of edges)
    avg_edge_gini = telemetry |> Enum.map(& &1.edge_gini) |> mean()
    
    # Civilizational Index
    ci = (0.25 * avg_div) + (0.25 * min(max_pers / 500.0, 1.0)) + (0.25 * min(avg_cnr, 1.0)) + (0.25 * (max_borrowing / @population_size))
    
    %{
      sweep: sweep_name,
      gini: avg_gini,
      diversity: avg_div,
      borrowing: max_borrowing,
      adoption: max_adoption,
      mean_pers: mean_pers,
      max_pers: max_pers,
      p95_pers: p95_pers,
      edge_gini: avg_edge_gini,
      cnr: avg_cnr,
      ci: ci
    }
  end

  defp evolve_mls(pop, _kg, 0, registry, _sweep, persistence_map, telemetry), do: {pop, telemetry, registry}
  
  defp evolve_mls(pop, kg, epochs_remaining, registry, {w_a, w_n, w_l, amp} = sweep, persistence_map, telemetry) do
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
      Map.merge(agent, %{raw_fitness: fitness, base_metrics: metrics, artifact: visited_nodes, original_niche: get_dominant_niche(metrics)})
    end)
    
    # 2. Interaction Phase (Empirical Dependency)
    interactions = Enum.flat_map(base_evaluated, fn agent ->
      neighbors = Enum.take_random(base_evaluated |> Enum.reject(& &1.id == agent.id), 2)
      Enum.map(neighbors, fn neighbor -> {agent, neighbor} end)
    end)
    
    # Evaluate marginal contributions
    marginal_contributions = Enum.map(interactions, fn {supplier, consumer} ->
      {traversal, _} = simulate_weighted_walk(consumer.heuristic_weights, kg, 50, Enum.take(MapSet.to_list(supplier.artifact), 5))
      new_fitness = (traversal.compression_score * 0.33) + (traversal.novelty_score * 0.33) + (traversal.prediction_score * 0.34)
      
      boost = max(0.0, new_fitness - consumer.raw_fitness)
      %{
        supplier_id: supplier.id, 
        consumer_id: consumer.id, 
        s_lineage: supplier.lineage_id, 
        c_lineage: consumer.lineage_id,
        s_niche: supplier.original_niche,
        c_niche: consumer.original_niche,
        boost: boost
      }
    end)
    
    # Accumulate neighborhood fitness (Amplified)
    supplier_boosts = Enum.group_by(marginal_contributions, & &1.supplier_id)
    
    # Dependency Survival Value / Active Edges
    active_edges = Enum.filter(marginal_contributions, & &1.boost > 0.05)
    active_edge_keys = MapSet.new(Enum.map(active_edges, fn e -> {e.s_lineage, e.c_lineage} end))
    
    # Update Persistence Map (Contiguous Epochs)
    # If key exists in active_edges, increment. If not, delete (reset to 0).
    new_persistence_map = Enum.reduce(persistence_map, %{}, fn {k, v}, acc ->
      if MapSet.member?(active_edge_keys, k) do
        Map.put(acc, k, v + 1)
      else
        acc # Relationship died
      end
    end)
    
    # Add new keys
    final_persistence_map = Enum.reduce(active_edge_keys, new_persistence_map, fn k, acc ->
      Map.put_new(acc, k, 1)
    end)
    
    # Cross-Niche Ratio
    same_niche = Enum.count(active_edges, fn e -> e.s_niche == e.c_niche end)
    diff_niche = Enum.count(active_edges, fn e -> e.s_niche != e.c_niche end)
    cnr = if same_niche == 0, do: diff_niche * 1.0, else: diff_niche / same_niche
    
    # Dependency Concentration (Edge Gini)
    edge_counts = active_edges |> Enum.map(& {&1.s_lineage, &1.c_lineage}) |> Enum.frequencies() |> Map.values()
    edge_gini = calculate_gini(edge_counts)

    # 3. Lineage Fitness Update
    updated_registry = update_lineage_registry(base_evaluated, registry, current_epoch)
    
    # 4. Composite Fitness Calculation
    evaluated_pop = Enum.map(base_evaluated, fn agent ->
      f_agent = agent.raw_fitness
      
      agent_boosts = Map.get(supplier_boosts, agent.id, [])
      f_neigh = if length(agent_boosts) > 0 do
        Enum.sum(Enum.map(agent_boosts, & &1.boost)) * amp
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
    new_telemetry = if epochs_remaining == 1 or rem(current_epoch, 100) == 0 do
      [record_snapshot(evaluated_pop, current_epoch, updated_registry, final_persistence_map, cnr, edge_gini) | telemetry]
    else
      telemetry
    end
    
    evolve_mls(next_gen, kg, epochs_remaining - 1, final_registry, sweep, final_persistence_map, new_telemetry)
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

  defp update_lineage_registry(evaluated_pop, registry, _current_epoch) do
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
  defp calculate_lineage_ema(history), do: mean(history)

  defp record_snapshot(pop, epoch, registry, pers_map, cnr, edge_gini) do
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
      persistence_map: pers_map,
      cross_niche_ratio: cnr,
      edge_gini: edge_gini
    }
  end

  defp print_matrix(results) do
    Logger.info("\n=========================================================================================")
    Logger.info("🌌 REA-6E DEPENDENCY AMPLIFICATION MATRIX")
    Logger.info("=========================================================================================")
    Logger.info("Amp      | Gini  | Shannon | Borrow | Adopt | Max Pers | P95 Pers | CNR   | Edge Gini | CI")
    Logger.info("-----------------------------------------------------------------------------------------")
    
    Enum.each(results, fn r ->
      t = "#{r.sweep}" |> String.pad_trailing(8)
      g = Float.round(r.gini, 3) |> Float.to_string() |> String.pad_trailing(5)
      d = Float.round(r.diversity, 3) |> Float.to_string() |> String.pad_trailing(7)
      b = "#{r.borrowing}" |> String.pad_trailing(6)
      a = "#{r.adoption}" |> String.pad_trailing(5)
      mp = "#{trunc(r.max_pers)}" |> String.pad_trailing(8)
      p95 = "#{trunc(r.p95_pers)}" |> String.pad_trailing(8)
      cnr = Float.round(r.cnr, 3) |> Float.to_string() |> String.pad_trailing(5)
      eg = Float.round(r.edge_gini, 3) |> Float.to_string() |> String.pad_trailing(9)
      ci = Float.round(r.ci, 3) |> Float.to_string()
      
      Logger.info("#{t} | #{g} | #{d} | #{b} | #{a} | #{mp} | #{p95} | #{cnr} | #{eg} | #{ci}")
    end)
    
    Logger.info("=========================================================================================")
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
  
  defp calculate_percentile([], _p), do: 0.0
  defp calculate_percentile(list, p) do
    sorted = Enum.sort(list)
    index = Float.ceil(p * length(sorted)) |> trunc()
    Enum.at(sorted, max(0, index - 1))
  end
end

Tiannara.REA.DependencyAmplificationTest.run_matrix()
