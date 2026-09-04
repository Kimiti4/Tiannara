# scripts/rea_6_b_basin_escape.exs
defmodule Tiannara.REA.BasinEscapeTest do
  @moduledoc """
  Phase REA-6B: Basin Escape Test.
  
  Tests the depth of Epistemic Attractor Basins by deliberately applying 
  increasing "Mentor Influence" (memetic blend ratio) to discover the critical 
  transition point where a culture's immune system collapses and permanent 
  Knowledge Adoption occurs.
  """
  require Logger

  @epochs 1_500
  @population_size 100
  @mutation_rate 0.05
  @hmt_frequency 0.40 # 40% chance to interact per generation
  
  @baseline_comp 0.40
  @baseline_expl 0.35
  @baseline_pred 0.45
  
  @mentor_influence_threshold 0.40
  @adoption_persistence_threshold 300

  def run_basin_escape_battery() do
    Logger.info("🌍 [REA-6B] Initiating Basin Escape Sweep...")
    
    kg = generate_knowledge_graph(1_000)
    
    mentor_pressures = [0.10, 0.20, 0.30, 0.40, 0.50, 0.60, 0.70, 0.80]
    
    results = Enum.map(mentor_pressures, fn pressure ->
      run_single_sweep(pressure, kg)
    end)
    
    print_phase_transition_matrix(results)
  end

  defp run_single_sweep(mentor_blend_ratio, kg) do
    Logger.info("🔬 Running Sweep at Mentor Influence: #{Float.round(mentor_blend_ratio * 100)}%...")
    
    base_pop = generate_established_cultures()
    lineage_registry = initialize_lineage_registry(base_pop)
    
    {final_pop, telemetry, final_registry} = evolve_with_hmt(
      base_pop, kg, @epochs, lineage_registry, mentor_blend_ratio, []
    )
    
    final_snapshot = List.first(telemetry)
    
    active_lineages = Enum.uniq(Enum.map(final_pop, & &1.lineage_id))
    hybrid_lifetimes = Enum.map(active_lineages, fn lid -> final_registry[lid].hybrid_duration_epochs end)
                       |> Enum.filter(& &1 > 0)
    
    mean_hybrid_lifetime = if length(hybrid_lifetimes) > 0, do: Enum.sum(hybrid_lifetimes) / length(hybrid_lifetimes), else: 0.0
    
    final_drift = final_snapshot.drift_metrics
    max_div = if length(final_drift) > 0 do
      scores = Enum.map(final_drift, & &1.divergence)
      List.last(Enum.sort(scores))
    else
      0.0
    end
    
    %{
      pressure: mentor_blend_ratio,
      borrowing: final_snapshot.borrowing_count,
      adoption: final_snapshot.adoption_count,
      hybridization: final_snapshot.hybrid_count,
      pure: final_snapshot.pure_count,
      max_divergence: max_div,
      mean_hybrid_lifetime: mean_hybrid_lifetime
    }
  end

  defp evolve_with_hmt(pop, _kg, 0, registry, _blend_ratio, telemetry), do: {pop, telemetry, registry}
  
  defp evolve_with_hmt(pop, kg, epochs_remaining, registry, blend_ratio, telemetry) do
    current_epoch = @epochs - epochs_remaining + 1
    
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
    
    survivors = Enum.map(1..@population_size, fn _ ->
      contenders = Enum.take_random(evaluated_pop, 3)
      Enum.max_by(contenders, & &1.fitness)
    end)
    
    {next_gen, final_registry} = Enum.map_reduce(survivors, updated_registry, fn parent, current_registry ->
      child_id = "agent_#{System.unique_integer([:positive])}"
      
      {child_weights, mentor_lineage_id} = if :rand.uniform() < @hmt_frequency do
        mentor = find_mentor_from_different_behavioral_niche(survivors, parent)
        if mentor do
          # Blend ratio is Mentor's influence
          hybrid_weights = blend_weights(parent.heuristic_weights, mentor.heuristic_weights, 1.0 - blend_ratio)
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
    
    evolve_with_hmt(next_gen, kg, epochs_remaining - 1, final_registry, blend_ratio, new_telemetry)
  end

  # =========================================================================
  # REGISTRY MAINTENANCE & CLASSIFICATION
  # =========================================================================

  defp update_lineage_registry(evaluated_pop, registry, current_epoch) do
    active_lineages = Enum.group_by(evaluated_pop, & &1.lineage_id)
    
    comp_scores = Enum.map(evaluated_pop, & &1.metrics.compression_score)
    expl_scores = Enum.map(evaluated_pop, & &1.metrics.exploration_score)
    pred_scores = Enum.map(evaluated_pop, & &1.metrics.prediction_score)
    
    comp_thresh = max(mean(comp_scores) + 0.5 * std_dev(comp_scores), @baseline_comp)
    expl_thresh = max(mean(expl_scores) + 0.5 * std_dev(expl_scores), @baseline_expl)
    pred_thresh = max(mean(pred_scores) + 0.5 * std_dev(pred_scores), @baseline_pred)
    
    Enum.reduce(active_lineages, registry, fn {lineage_id, agents}, reg ->
      centroid = calculate_average_weights(agents)
      
      avg_comp = mean(Enum.map(agents, & &1.metrics.compression_score))
      avg_expl = mean(Enum.map(agents, & &1.metrics.exploration_score))
      avg_pred = mean(Enum.map(agents, & &1.metrics.prediction_score))
      
      dominant_niche = get_dominant_niche(%{compression_score: avg_comp, exploration_score: avg_expl, prediction_score: avg_pred})
      
      active_count = [
        avg_comp > comp_thresh,
        avg_expl > expl_thresh,
        avg_pred > pred_thresh
      ] |> Enum.filter(& &1) |> length()
      
      is_hybrid = active_count >= 2
      
      Map.update!(reg, lineage_id, fn data ->
        new_hybrid_epochs = if is_hybrid, do: data.hybrid_duration_epochs + 1, else: data.hybrid_duration_epochs
        
        {new_niche, new_change_epoch} = if dominant_niche != data.current_niche do
          {dominant_niche, current_epoch}
        else
          {data.current_niche, data.niche_change_epoch}
        end
        
        %{data | 
          last_known_centroid: centroid,
          current_niche: new_niche,
          niche_change_epoch: new_change_epoch,
          hybrid_duration_epochs: new_hybrid_epochs,
          is_currently_hybrid: is_hybrid
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
    
    {hybrid_ids, borrowing_ids, adoption_ids, pure_ids, drift_metrics} = 
      Enum.reduce(pop, {[], [], [], [], []}, fn agent, {h, b, a, p, dm} ->
        metrics = agent.metrics
        reg_data = registry[agent.lineage_id]
        original_niche = reg_data.original_niche
        current_niche = get_dominant_niche(metrics)
        
        active_count = [
          metrics.compression_score > comp_thresh,
          metrics.exploration_score > expl_thresh,
          metrics.prediction_score > pred_thresh
        ] |> Enum.filter(& &1) |> length()
        
        divergence_score = 1.0 - cosine_similarity(agent.heuristic_weights, agent.ancestral_weights)
        mentor_influence = calculate_mentor_influence(agent, registry)
        
        is_secondary_elevated = secondary_elevated?(metrics, original_niche, comp_thresh, expl_thresh, pred_thresh)
        is_borrowing = is_secondary_elevated and mentor_influence > @mentor_influence_threshold
        
        is_adoption = current_niche != original_niche and (epoch - reg_data.niche_change_epoch >= @adoption_persistence_threshold)
        
        cond do
          active_count >= 2 -> { [agent.lineage_id | h], b, a, p, dm }
          is_adoption -> { h, b, [agent.lineage_id | a], p, dm }
          current_niche == original_niche and is_borrowing -> { h, [agent.lineage_id | b], a, p, dm }
          true -> { h, b, a, [agent.lineage_id | p], dm }
        end
        |> then(fn {nh, nb, na, np, ndm} ->
          new_dm = [%{divergence: divergence_score} | ndm]
          {nh, nb, na, np, new_dm}
        end)
      end)
    
    %{
      epoch: epoch,
      hybrid_count: length(hybrid_ids),
      borrowing_count: length(borrowing_ids),
      adoption_count: length(adoption_ids),
      pure_count: length(pure_ids),
      drift_metrics: drift_metrics
    }
  end

  defp print_phase_transition_matrix(results) do
    Logger.info("\n==================================================")
    Logger.info("📊 REA-6B BASIN ESCAPE CRITICAL TRANSITION MATRIX")
    Logger.info("==================================================")
    Logger.info("Influence | Pure% | Borrow% | Adopt% | Max Div | Hybrid Life")
    Logger.info("--------------------------------------------------")
    
    Enum.each(results, fn r ->
      influence = "#{Float.round(r.pressure * 100)}%" |> String.pad_trailing(9)
      pure = "#{r.pure}%" |> String.pad_trailing(5)
      borrow = "#{r.borrowing}%" |> String.pad_trailing(7)
      adopt = "#{r.adoption}%" |> String.pad_trailing(6)
      div = Float.round(r.max_divergence, 3) |> Float.to_string() |> String.pad_trailing(7)
      life = Float.round(r.mean_hybrid_lifetime, 1) |> Float.to_string()
      
      Logger.info("#{influence} | #{pure} | #{borrow} | #{adopt} | #{div} | #{life}")
    end)
    
    Logger.info("==================================================")
    
    # Identify transition
    transition_point = Enum.find(results, fn r -> r.adoption > 15 end)
    
    if transition_point do
      Logger.info("🔥 CRITICAL PHASE TRANSITION DETECTED AT #{Float.round(transition_point.pressure * 100)}% MENTOR INFLUENCE.")
      Logger.info("   Attractor basins collapse and permanent adoption dominates.")
    else
      Logger.info("🛡️ NO PHASE TRANSITION DETECTED.")
      Logger.info("   Epistemic inertia survived the maximum parameter bounds.")
    end
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
    Enum.zip(parent_w, mentor_w)
    |> Enum.map(fn {p, m} -> (p * parent_retention) + (m * (1.0 - parent_retention)) end)
  end

  defp mutate_weights(weights) do
    Enum.map(weights, fn w -> max(0.0, min(1.0, w + (:rand.uniform() - 0.5) * 0.15)) end)
  end

  defp cosine_distance(vec1, vec2) do
    dot_product = Enum.zip(vec1, vec2) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
    mag1 = :math.sqrt(Enum.sum(Enum.map(vec1, &(&1 * &1))))
    mag2 = :math.sqrt(Enum.sum(Enum.map(vec2, &(&1 * &1))))
    similarity = if mag1 == 0 or mag2 == 0, do: 0.0, else: dot_product / (mag1 * mag2)
    1.0 - similarity
  end

  defp cosine_similarity(vec1, vec2), do: 1.0 - cosine_distance(vec1, vec2)

  defp generate_established_cultures() do
    Enum.map(1..@population_size, fn i ->
      {weights, niche} = case rem(i, 3) do
        0 -> {[0.85, 0.30, 0.30, 0.30], :compression}
        1 -> {[0.30, 0.85, 0.30, 0.30], :exploration}
        2 -> {[0.30, 0.30, 0.85, 0.30], :prediction}
      end
      %{
        id: "culture_init_#{i}", lineage_id: "lineage_#{i}", parent_id: nil, mentor_lineage_id: nil,
        ancestral_weights: weights, original_niche: niche, heuristic_weights: weights, fitness: 0.0, metrics: %{}
      }
    end)
  end

  defp initialize_lineage_registry(pop) do
    Map.new(pop, fn agent -> 
      {agent.lineage_id, %{
        parent_id: nil, mentor_lineage_id: nil, birth_epoch: 0, ancestral_weights: agent.ancestral_weights,
        original_niche: agent.original_niche, last_known_centroid: agent.heuristic_weights,
        current_niche: agent.original_niche, niche_change_epoch: 0, hybrid_duration_epochs: 0, is_currently_hybrid: false
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
end

Tiannara.REA.BasinEscapeTest.run_basin_escape_battery()
