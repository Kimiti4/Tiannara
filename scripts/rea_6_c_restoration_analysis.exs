# scripts/rea_6_c_restoration_analysis.exs
defmodule Tiannara.REA.RestorationAnalysis do
  @moduledoc """
  Phase REA-6C: Restoration Mechanism Analysis.
  
  Determines WHAT actively preserves Epistemic Identity by running a 2D matrix
  of [Mentor Pressure] x [Disabled Restoring Force].
  """
  require Logger

  @epochs 1_500
  @population_size 100
  @hmt_frequency 0.40 # High interaction frequency to apply pressure
  
  @baseline_comp 0.40
  @baseline_expl 0.35
  @baseline_pred 0.45
  
  @mentor_influence_threshold 0.40
  @adoption_persistence_threshold 300

  def run_matrix() do
    Logger.info("🌋 [REA-6C] Initiating Restoration Mechanism Matrix...")
    
    base_kg = generate_knowledge_graph(1_000)
    
    pressures = [0.10, 0.40, 0.70]
    modes = [:baseline, :no_selection, :no_mutation, :no_sel_no_mut, :topo_20, :topo_50]
    
    results = for p <- pressures, m <- modes do
      run_single_sweep(p, m, base_kg)
    end
    
    print_matrix(results)
  end

  defp run_single_sweep(mentor_blend_ratio, mode, base_kg) do
    Logger.info("🔬 Testing [#{mode}] at #{Float.round(mentor_blend_ratio * 100)}% pressure...")
    
    base_pop = generate_ecological_population()
    lineage_registry = initialize_lineage_registry(base_pop)
    
    {final_pop, telemetry, _final_registry} = evolve_with_hmt(
      base_pop, base_kg, @epochs, lineage_registry, mentor_blend_ratio, mode, []
    )
    
    final_snapshot = List.first(telemetry)
    prev_snapshot = Enum.find(telemetry, &(&1.epoch == @epochs - 300)) || final_snapshot
    
    final_div = calculate_mean_divergence(final_snapshot.drift_metrics)
    prev_div = calculate_mean_divergence(prev_snapshot.drift_metrics)
    velocity = (final_div - prev_div) / 300.0 # Delta divergence per epoch in the final stretch
    
    max_div = calculate_max_divergence(final_snapshot.drift_metrics)
    
    adopted_epochs = final_snapshot.adoption_details |> Enum.map(& &1.niche_change_epoch)
    time_to_adoption = if Enum.empty?(adopted_epochs), do: "N/A", else: "#{Enum.min(adopted_epochs)}"
    
    %{
      pressure: mentor_blend_ratio,
      mode: mode,
      borrowing: final_snapshot.borrowing_count,
      adoption: final_snapshot.adoption_count,
      mean_divergence: final_div,
      max_divergence: max_div,
      velocity: velocity,
      time_to_adoption: time_to_adoption
    }
  end

  defp evolve_with_hmt(pop, _base_kg, 0, registry, _blend_ratio, _mode, telemetry), do: {pop, telemetry, registry}
  
  defp evolve_with_hmt(pop, base_kg, epochs_remaining, registry, blend_ratio, mode, telemetry) do
    current_epoch = @epochs - epochs_remaining + 1
    
    kg = apply_topology_mode(base_kg, mode)
    
    evaluated_pop = Enum.map(pop, fn agent ->
      traversal = simulate_weighted_walk(agent.heuristic_weights, kg, 50)
      metrics = %{
        compression_score: traversal.compression_score,
        exploration_score: traversal.novelty_score,
        prediction_score: traversal.prediction_score
      }
      fitness = (metrics.compression_score * 0.33) + (metrics.exploration_score * 0.33) + (metrics.prediction_score * 0.34)
      %{agent | fitness: fitness, metrics: metrics}
    end)

    updated_registry = update_lineage_registry(evaluated_pop, registry, current_epoch)
    
    # 2. Selection Mode
    survivors = case mode do
      m when m in [:no_selection, :no_sel_no_mut] -> 
        # Random survival with replacement (Neutral Drift)
        Enum.map(1..@population_size, fn _ -> Enum.random(evaluated_pop) end)
      _ ->
        # Tournament selection
        Enum.map(1..@population_size, fn _ ->
          contenders = Enum.take_random(evaluated_pop, 3)
          Enum.max_by(contenders, & &1.fitness)
        end)
    end
    
    # 3. Mutation Mode
    mutation_enabled = not (mode in [:no_mutation, :no_sel_no_mut])
    
    {next_gen, final_registry} = Enum.map_reduce(survivors, updated_registry, fn parent, current_registry ->
      child_id = "agent_#{System.unique_integer([:positive])}"
      
      {child_weights, mentor_lineage_id} = if :rand.uniform() < @hmt_frequency do
        mentor = find_mentor_from_different_behavioral_niche(survivors, parent)
        if mentor do
          hybrid_weights = blend_weights(parent.heuristic_weights, mentor.heuristic_weights, 1.0 - blend_ratio)
          {hybrid_weights, mentor.lineage_id}
        else
          {maybe_mutate(parent.heuristic_weights, mutation_enabled), nil}
        end
      else
        {maybe_mutate(parent.heuristic_weights, mutation_enabled), nil}
      end
      
      child = %{
        id: child_id,
        lineage_id: parent.lineage_id,
        parent_id: parent.id,
        mentor_lineage_id: mentor_lineage_id,
        ancestral_weights: parent.ancestral_weights,
        original_niche: parent.original_niche,
        heuristic_weights: child_weights,
        fitness: 0.0,
        metrics: %{}
      }
      
      {child, current_registry}
    end)
    
    new_telemetry = if epochs_remaining == 1 or rem(current_epoch, 300) == 0 do
      [record_cultural_snapshot(evaluated_pop, current_epoch, updated_registry) | telemetry]
    else
      telemetry
    end
    
    evolve_with_hmt(next_gen, base_kg, epochs_remaining - 1, final_registry, blend_ratio, mode, new_telemetry)
  end

  # =========================================================================
  # CORE LOGIC
  # =========================================================================

  defp apply_topology_mode(base_kg, :topo_20), do: scramble_edges(base_kg, 0.20)
  defp apply_topology_mode(base_kg, :topo_50), do: scramble_edges(base_kg, 0.50)
  defp apply_topology_mode(base_kg, _), do: base_kg

  defp scramble_edges(kg, rate) do
    num_to_scramble = round(kg.total_active_nodes * rate)
    nodes_to_scramble = Enum.take_random(0..(kg.total_active_nodes - 1), num_to_scramble)
    
    new_nodes = Enum.reduce(nodes_to_scramble, kg.nodes, fn node_id, acc ->
      node = acc[node_id]
      new_neighbors = Enum.map(1..10, fn _ -> :rand.uniform(kg.total_active_nodes) - 1 end) |> Enum.uniq() |> List.delete(node_id)
      Map.put(acc, node_id, %{node | neighbors: new_neighbors})
    end)
    %{kg | nodes: new_nodes}
  end

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
        ancestral_weights: weights, original_niche: niche, heuristic_weights: weights, fitness: 0.0, metrics: %{}
      }
    end)
  end

  defp maybe_mutate(weights, true) do
    Enum.map(weights, fn w -> max(0.0, min(1.0, w + (:rand.uniform() - 0.5) * 0.15)) end)
  end
  defp maybe_mutate(weights, false), do: weights

  # =========================================================================
  # REGISTRY MAINTENANCE & CLASSIFICATION
  # =========================================================================

  defp update_lineage_registry(evaluated_pop, registry, current_epoch) do
    active_lineages = Enum.group_by(evaluated_pop, & &1.lineage_id)
    
    Enum.reduce(active_lineages, registry, fn {lineage_id, agents}, reg ->
      centroid = calculate_average_weights(agents)
      
      avg_comp = mean(Enum.map(agents, & &1.metrics.compression_score))
      avg_expl = mean(Enum.map(agents, & &1.metrics.exploration_score))
      avg_pred = mean(Enum.map(agents, & &1.metrics.prediction_score))
      
      dominant_niche = get_dominant_niche(%{compression_score: avg_comp, exploration_score: avg_expl, prediction_score: avg_pred})
      
      Map.update!(reg, lineage_id, fn data ->
        {new_niche, new_change_epoch} = if dominant_niche != data.current_niche do
          {dominant_niche, current_epoch}
        else
          {data.current_niche, data.niche_change_epoch}
        end
        
        %{data | 
          last_known_centroid: centroid,
          current_niche: new_niche,
          niche_change_epoch: new_change_epoch
        }
      end)
    end)
  end

  defp record_cultural_snapshot(pop, epoch, registry) do
    comp_scores = Enum.map(pop, & &1.metrics.compression_score)
    expl_scores = Enum.map(pop, & &1.metrics.exploration_score)
    pred_scores = Enum.map(pop, & &1.metrics.prediction_score)
    
    comp_thresh = max(mean(comp_scores) + 0.5 * std_dev(comp_scores), @baseline_comp)
    expl_thresh = max(mean(expl_scores) + 0.5 * std_dev(expl_scores), @baseline_expl)
    pred_thresh = max(mean(pred_scores) + 0.5 * std_dev(pred_scores), @baseline_pred)
    
    {borrowing_ids, adoption_ids, drift_metrics, adoption_details} = 
      Enum.reduce(pop, {[], [], [], []}, fn agent, {b, a, dm, ad} ->
        metrics = agent.metrics
        reg_data = registry[agent.lineage_id]
        original_niche = reg_data.original_niche
        current_niche = get_dominant_niche(metrics)
        
        divergence_score = 1.0 - cosine_similarity(agent.heuristic_weights, agent.ancestral_weights)
        mentor_influence = calculate_mentor_influence(agent, registry)
        
        is_secondary_elevated = secondary_elevated?(metrics, original_niche, comp_thresh, expl_thresh, pred_thresh)
        is_borrowing = is_secondary_elevated and mentor_influence > @mentor_influence_threshold
        
        is_adoption = current_niche != original_niche and (epoch - reg_data.niche_change_epoch >= @adoption_persistence_threshold)
        
        cond do
          is_adoption -> 
            { b, [agent.lineage_id | a], dm, [%{id: agent.id, niche_change_epoch: reg_data.niche_change_epoch} | ad] }
          current_niche == original_niche and is_borrowing -> 
            { [agent.lineage_id | b], a, dm, ad }
          true -> 
            { b, a, dm, ad }
        end
        |> then(fn {nb, na, ndm, nad} ->
          new_dm = [%{divergence: divergence_score} | ndm]
          {nb, na, new_dm, nad}
        end)
      end)
    
    %{
      epoch: epoch,
      borrowing_count: length(borrowing_ids),
      adoption_count: length(adoption_ids),
      drift_metrics: drift_metrics,
      adoption_details: adoption_details
    }
  end

  defp print_matrix(results) do
    Logger.info("\n==================================================================")
    Logger.info("📊 REA-6C RESTORATION MECHANISM MATRIX (2D PHASE SPACE)")
    Logger.info("==================================================================")
    Logger.info("Press | Mode            | Borrow% | Adopt% | Max Div | Div Velocity | TTA")
    Logger.info("------------------------------------------------------------------")
    
    Enum.each(results, fn r ->
      p = "#{Float.round(r.pressure * 100)}%" |> String.pad_trailing(5)
      m = "#{r.mode}" |> String.pad_trailing(15)
      b = "#{r.borrowing}%" |> String.pad_trailing(7)
      a = "#{r.adoption}%" |> String.pad_trailing(6)
      md = Float.round(r.max_divergence, 3) |> Float.to_string() |> String.pad_trailing(7)
      
      vel_str = cond do
        r.velocity > 0.0001 -> "+#{Float.round(r.velocity * 1000, 3)}/kE"
        r.velocity < -0.0001 -> "#{Float.round(r.velocity * 1000, 3)}/kE"
        true -> "0.000/kE (Ceiling)"
      end |> String.pad_trailing(12)
      
      tta = "#{r.time_to_adoption}"
      
      Logger.info("#{p} | #{m} | #{b} | #{a} | #{md} | #{vel_str} | #{tta}")
    end)
    
    Logger.info("==================================================================")
  end

  # =========================================================================
  # HELPER FUNCTIONS
  # =========================================================================

  defp calculate_average_weights(agents) do
    num_agents = length(agents)
    if num_agents == 0, do: [0.5, 0.5, 0.5, 0.5], else: Enum.map(0..3, fn i -> Enum.sum(Enum.map(agents, &Enum.at(&1.heuristic_weights, i))) / num_agents end)
  end
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
  defp calculate_mentor_influence(agent, registry) do
    if agent.mentor_lineage_id do
      dist_ancestor = cosine_distance(agent.heuristic_weights, agent.ancestral_weights)
      mentor_centroid = registry[agent.mentor_lineage_id].last_known_centroid
      dist_mentor = cosine_distance(agent.heuristic_weights, mentor_centroid)
      dist_ancestor / (dist_ancestor + dist_mentor + 0.0001)
    else
      0.0
    end
  end
  defp find_mentor_from_different_behavioral_niche(population, agent) do
    agent_niche = get_dominant_niche(agent.metrics)
    potential_mentors = Enum.filter(population, fn other -> other.id != agent.id and get_dominant_niche(other.metrics) != agent_niche end)
    if Enum.empty?(potential_mentors), do: nil, else: Enum.random(potential_mentors)
  end
  defp blend_weights(parent_w, mentor_w, parent_retention) do
    Enum.zip(parent_w, mentor_w) |> Enum.map(fn {p, m} -> (p * parent_retention) + (m * (1.0 - parent_retention)) end)
  end
  defp cosine_distance(vec1, vec2) do
    dot_product = Enum.zip(vec1, vec2) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
    mag1 = :math.sqrt(Enum.sum(Enum.map(vec1, &(&1 * &1))))
    mag2 = :math.sqrt(Enum.sum(Enum.map(vec2, &(&1 * &1))))
    similarity = if mag1 == 0 or mag2 == 0, do: 0.0, else: dot_product / (mag1 * mag2)
    1.0 - similarity
  end
  defp cosine_similarity(vec1, vec2), do: 1.0 - cosine_distance(vec1, vec2)
  defp initialize_lineage_registry(pop) do
    Map.new(pop, fn agent -> 
      {agent.lineage_id, %{
        parent_id: nil, mentor_lineage_id: nil, birth_epoch: 0, ancestral_weights: agent.ancestral_weights,
        original_niche: agent.original_niche, last_known_centroid: agent.heuristic_weights,
        current_niche: agent.original_niche, niche_change_epoch: 0
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
  defp calculate_mean_divergence(metrics), do: if(length(metrics) > 0, do: Enum.sum(Enum.map(metrics, & &1.divergence)) / length(metrics), else: 0.0)
  defp calculate_max_divergence(metrics), do: if(length(metrics) > 0, do: Enum.max(Enum.map(metrics, & &1.divergence)), else: 0.0)
end

Tiannara.REA.RestorationAnalysis.run_matrix()
