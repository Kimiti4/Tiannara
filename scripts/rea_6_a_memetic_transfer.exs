# scripts/rea_6_a_memetic_transfer.exs
defmodule Tiannara.REA.MemeticTransferTest do
  @moduledoc """
  Phase REA-6A: Memetic Transfer (Final Corrected).
  
  Tests whether epistemic lineages can exchange ideas (Horizontal Memetic Transfer)
  and form stable, persistent hybrid cultures without losing their core identity.
  
  FINAL CORRECTIONS APPLIED:
  1. Archive extinct mentor traditions (use `last_known_centroid`).
  2. Require persistence before classifying adoption (`niche_history`).
  3. Measure hybrid lifetime (`hybrid_duration_epochs`).
  """
  require Logger

  @epochs 3_000
  @population_size 100
  @mutation_rate 0.05
  @hmt_rate 0.15 
  
  @baseline_comp 0.40
  @baseline_expl 0.35
  @baseline_pred 0.45
  
  @mentor_influence_threshold 0.40
  @adoption_persistence_threshold 300

  def run_memetic_transfer_test() do
    Logger.info("🌍 [REA-6A] Initiating Memetic Transfer & Cultural Persistence Pilot...")
    
    kg = generate_knowledge_graph(1_000)
    base_pop = generate_established_cultures()
    lineage_registry = initialize_lineage_registry(base_pop)
    
    rep_ids = select_representative_lineages(base_pop)
    Logger.info("🔬 Tracking Representative Lineages: #{inspect(rep_ids)}")
    
    {final_pop, telemetry, final_registry} = evolve_with_hmt(
      base_pop, kg, @epochs, lineage_registry, rep_ids, []
    )
    
    analyze_cultural_persistence(final_pop, telemetry, final_registry)
  end

  defp evolve_with_hmt(pop, _kg, 0, registry, _rep_ids, telemetry), do: {pop, telemetry, registry}
  
  defp evolve_with_hmt(pop, kg, epochs_remaining, registry, rep_ids, telemetry) do
    current_epoch = @epochs - epochs_remaining + 1
    
    # 1. Evaluate Fitness & Metrics
    evaluated_pop = Enum.map(pop, fn agent ->
      traversal = simulate_weighted_walk(agent.heuristic_weights, kg, 50)
      
      metrics = %{
        compression_score: traversal.compression_score,
        exploration_score: traversal.novelty_score,
        prediction_score: traversal.prediction_score
      }
      
      fitness = (metrics.compression_score * 0.33) + 
                (metrics.exploration_score * 0.33) + 
                (metrics.prediction_score * 0.34)
                
      %{agent | fitness: fitness, metrics: metrics}
    end)

    # 1.5 Update Registry with Centroids, Niche History, and Hybrid Lifetimes
    updated_registry = update_lineage_registry(evaluated_pop, registry, current_epoch)
    
    # 2. Tournament Selection
    survivors = Enum.map(1..@population_size, fn _ ->
      contenders = Enum.take_random(evaluated_pop, 3)
      Enum.max_by(contenders, & &1.fitness)
    end)
    
    # 3. Reproduction with Horizontal Memetic Transfer (HMT)
    {next_gen, final_registry} = Enum.map_reduce(survivors, updated_registry, fn parent, current_registry ->
      child_lineage_id = parent.lineage_id
      child_id = "agent_#{System.unique_integer([:positive])}"
      
      {child_weights, mentor_lineage_id} = if :rand.uniform() < @hmt_rate do
        mentor = find_mentor_from_different_behavioral_niche(survivors, parent)
        if mentor do
          hybrid_weights = blend_weights(parent.heuristic_weights, mentor.heuristic_weights, 0.7)
          {hybrid_weights, mentor.lineage_id}
        else
          {mutate_weights(parent.heuristic_weights), nil}
        end
      else
        {mutate_weights(parent.heuristic_weights), nil}
      end
      
      child = %{
        id: child_id,
        lineage_id: child_lineage_id,
        parent_id: parent.id,
        mentor_lineage_id: mentor_lineage_id,
        ancestral_weights: parent.ancestral_weights,
        original_niche: parent.original_niche,
        heuristic_weights: child_weights,
        fitness: 0.0,
        metrics: %{}
      }
      
      # If new lineage (won't happen here as children keep parent lineage), add to registry.
      # But children share the lineage_id, so we just return the child.
      {child, current_registry}
    end)
    
    # 4. Record Telemetry
    new_telemetry = if rem(current_epoch, 300) == 0 do
      [record_cultural_snapshot(evaluated_pop, current_epoch, updated_registry, rep_ids) | telemetry]
    else
      telemetry
    end
    
    evolve_with_hmt(next_gen, kg, epochs_remaining - 1, final_registry, rep_ids, new_telemetry)
  end

  # =========================================================================
  # REGISTRY MAINTENANCE
  # =========================================================================

  defp update_lineage_registry(evaluated_pop, registry, current_epoch) do
    # Group by lineage_id
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
        
        {new_niche, new_history, new_change_epoch} = if dominant_niche != data.current_niche do
          {dominant_niche, [{current_epoch, dominant_niche} | data.niche_history], current_epoch}
        else
          {data.current_niche, data.niche_history, data.niche_change_epoch}
        end
        
        %{data | 
          last_known_centroid: centroid,
          current_niche: new_niche,
          niche_history: new_history,
          niche_change_epoch: new_change_epoch,
          hybrid_duration_epochs: new_hybrid_epochs,
          is_currently_hybrid: is_hybrid
        }
      end)
    end)
  end

  # =========================================================================
  # DYNAMIC THRESHOLDS & STRICT BEHAVIORAL CLASSIFICATION
  # =========================================================================

  defp record_cultural_snapshot(pop, epoch, registry, rep_ids) do
    comp_scores = Enum.map(pop, & &1.metrics.compression_score)
    expl_scores = Enum.map(pop, & &1.metrics.exploration_score)
    pred_scores = Enum.map(pop, & &1.metrics.prediction_score)
    
    comp_thresh = max(mean(comp_scores) + 0.5 * std_dev(comp_scores), @baseline_comp)
    expl_thresh = max(mean(expl_scores) + 0.5 * std_dev(expl_scores), @baseline_expl)
    pred_thresh = max(mean(pred_scores) + 0.5 * std_dev(pred_scores), @baseline_pred)
    
    {hybrid_ids, borrowing_ids, adoption_ids, pure_ids, rep_curves, drift_metrics} = 
      Enum.reduce(pop, {[], [], [], [], [], []}, fn agent, {h, b, a, p, rc, dm} ->
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
        
        # Check adoption persistence
        is_adoption = current_niche != original_niche and (epoch - reg_data.niche_change_epoch >= @adoption_persistence_threshold)
        
        cond do
          active_count >= 2 -> 
            { [agent.lineage_id | h], b, a, p, rc, dm }
            
          is_adoption -> 
            { h, b, [agent.lineage_id | a], p, rc, dm }
            
          current_niche == original_niche and is_borrowing -> 
            { h, [agent.lineage_id | b], a, p, rc, dm }
            
          true -> 
            { h, b, a, [agent.lineage_id | p], rc, dm }
        end
        |> then(fn {nh, nb, na, np, nrc, ndm} ->
          new_rc = if agent.lineage_id in rep_ids do
            [%{
              lineage_id: agent.lineage_id,
              epoch: epoch,
              comp: metrics.compression_score,
              expl: metrics.exploration_score,
              pred: metrics.prediction_score,
              divergence: divergence_score,
              mentor_influence: mentor_influence
            } | nrc]
          else
            nrc
          end
          
          new_dm = if agent.mentor_lineage_id != nil do
            [%{
              lineage_id: agent.lineage_id,
              epoch: epoch,
              divergence: divergence_score,
              mentor_influence: mentor_influence
            } | ndm]
          else
            ndm
          end
          
          {nh, nb, na, np, new_rc, new_dm}
        end)
      end)
    
    %{
      epoch: epoch,
      hybrid_count: length(hybrid_ids),
      borrowing_count: length(borrowing_ids),
      adoption_count: length(adoption_ids),
      pure_count: length(pure_ids),
      representative_curves: rep_curves,
      drift_metrics: drift_metrics
    }
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

  # =========================================================================
  # ANALYSIS & VERDICT
  # =========================================================================

  defp analyze_cultural_persistence(final_pop, telemetry, registry) do
    Logger.info("\n==================================================")
    Logger.info("📊 REA-6A MEMETIC TRANSFER VERDICT (FINAL CORRECTED)")
    Logger.info("==================================================")
    
    # 1. HYBRID LIFETIMES
    active_lineages = Enum.uniq(Enum.map(final_pop, & &1.lineage_id))
    hybrid_lifetimes = Enum.map(active_lineages, fn lid -> registry[lid].hybrid_duration_epochs end)
                       |> Enum.filter(& &1 > 0)
                       |> Enum.sort()
                       
    Logger.info("1. Hybrid Lifetimes (Epochs Spent as Hybrid):")
    if length(hybrid_lifetimes) > 0 do
      mean_lifetime = Enum.sum(hybrid_lifetimes) / length(hybrid_lifetimes)
      median_lifetime = Enum.at(hybrid_lifetimes, div(length(hybrid_lifetimes), 2))
      max_lifetime = List.last(hybrid_lifetimes)
      Logger.info("   - Median Hybrid Lifetime: #{median_lifetime} epochs")
      Logger.info("   - Mean Hybrid Lifetime:   #{Float.round(mean_lifetime, 1)} epochs")
      Logger.info("   - Max Hybrid Lifetime:    #{max_lifetime} epochs")
    else
      Logger.info("   - No lineage achieved hybrid status.")
    end
    
    # 2. REPRESENTATIVE BEHAVIORAL DRIFT CURVES
    Logger.info("\n2. Representative Behavioral Drift Curves:")
    rep_lineages = telemetry |> List.last() |> Map.get(:representative_curves, []) |> Enum.map(& &1.lineage_id) |> Enum.uniq()
    
    chronological_telemetry = Enum.reverse(telemetry)
    Enum.each(rep_lineages, fn lid ->
      Logger.info("   📈 Lineage #{lid} Trajectory:")
      Enum.each(chronological_telemetry, fn t ->
        data = Enum.find(t.representative_curves, & &1.lineage_id == lid)
        if data do
          Logger.info("      Epoch #{t.epoch} | Comp: #{Float.round(data.comp, 3)} | Expl: #{Float.round(data.expl, 3)} | Pred: #{Float.round(data.pred, 3)} | Div: #{Float.round(data.divergence, 3)}")
        end
      end)
    end)
    
    # 3. DIVERGENCE METRICS
    Logger.info("\n3. Divergence Score Summary (Baseline for REA-6B Speciation):")
    final_drift = List.first(telemetry).drift_metrics
    if length(final_drift) > 0 do
      scores = Enum.map(final_drift, & &1.divergence)
      sorted_scores = Enum.sort(scores)
      mean_div = Enum.sum(scores) / length(scores)
      p95_idx = round(length(sorted_scores) * 0.95) |> max(1) |> min(length(sorted_scores) - 1)
      p95_div = Enum.at(sorted_scores, p95_idx)
      max_div = List.last(sorted_scores)
      
      Logger.info("   - Mean Divergence:   #{Float.round(mean_div, 3)}")
      Logger.info("   - 95th Percentile:   #{Float.round(p95_div, 3)}")
      Logger.info("   - Maximum Divergence: #{Float.round(max_div, 3)}")
    end
    
    # 4. CULTURAL OUTCOME BREAKDOWN
    final_snapshot = List.first(telemetry)
    Logger.info("\n4. Cultural Outcome Breakdown (Epoch 3000):")
    Logger.info("   - True Hybridization (Multi-niche behavior): #{final_snapshot.hybrid_count}")
    Logger.info("   - Cultural Borrowing (Identity retained, technique adopted): #{final_snapshot.borrowing_count}")
    Logger.info("   - Knowledge Adoption (Identity changed, persisted > 300 epochs): #{final_snapshot.adoption_count}")
    Logger.info("   - Pure/Unchanged Lineages: #{final_snapshot.pure_count}")
    
    Logger.info("\n🏆 FINAL SYNTHESIS:")
    cond do
      final_snapshot.borrowing_count > max(final_snapshot.adoption_count, final_snapshot.hybrid_count) ->
        Logger.info("✅ CONCLUSION: CULTURAL BORROWING DOMINANT.")
        Logger.info("   Lineages successfully adopted foreign techniques while maintaining core identity.")
        
      final_snapshot.adoption_count > max(final_snapshot.borrowing_count, final_snapshot.hybrid_count) ->
        Logger.info("🔄 CONCLUSION: KNOWLEDGE ADOPTION DOMINANT.")
        Logger.info("   Lineages frequently and persistently abandoned original identities to adopt new niches.")
        
      final_snapshot.hybrid_count > 15 ->
        Logger.info("✅ CONCLUSION: STABLE CULTURAL PLURALISM CONFIRMED.")
        Logger.info("   Lineages successfully exchanged ideas and maintained active hybrid identities.")
        
      true ->
        Logger.info("🛡️ CONCLUSION: CULTURAL IMMUNE REJECTION / PURE ECOLOGY.")
        Logger.info("   Foreign influence failed to stick. Niches remain pure and distinct.")
    end
    Logger.info("==================================================")
  end

  # =========================================================================
  # HELPER FUNCTIONS
  # =========================================================================

  defp select_representative_lineages(pop) do
    comp = Enum.find(pop, & &1.original_niche == :compression)
    expl = Enum.find(pop, & &1.original_niche == :exploration)
    pred = Enum.find(pop, & &1.original_niche == :prediction)
    
    Enum.filter([comp, expl, pred], & &1 != nil) |> Enum.map(& &1.lineage_id)
  end

  defp calculate_average_weights(agents) do
    num_agents = length(agents)
    if num_agents == 0 do
      [0.5, 0.5, 0.5, 0.5]
    else
      num_weights = length(hd(agents).heuristic_weights)
      Enum.map(0..(num_weights - 1), fn i ->
        Enum.sum(Enum.map(agents, fn agent -> Enum.at(agent.heuristic_weights, i) end)) / num_agents
      end)
    end
  end

  defp mean(list), do: if(length(list) == 0, do: 0.0, else: Enum.sum(list) / length(list))
  
  defp std_dev(list) do
    m = mean(list)
    if length(list) == 0 do
      0.0
    else
      variance = Enum.sum(Enum.map(list, fn x -> :math.pow(x - m, 2) end)) / length(list)
      :math.sqrt(variance)
    end
  end

  defp get_dominant_niche(metrics) do
    cond do
      metrics.compression_score > 0.75 -> :compression
      metrics.exploration_score > 0.60 -> :exploration
      metrics.prediction_score > 0.80 -> :prediction
      true -> :generalist
    end
  end

  defp find_mentor_from_different_behavioral_niche(population, agent) do
    agent_niche = get_dominant_niche(agent.metrics)
    potential_mentors = Enum.filter(population, fn other ->
      other.id != agent.id and get_dominant_niche(other.metrics) != agent_niche
    end)
    if Enum.empty?(potential_mentors), do: nil, else: Enum.random(potential_mentors)
  end

  defp blend_weights(parent_w, mentor_w, retention_factor) do
    Enum.zip(parent_w, mentor_w)
    |> Enum.map(fn {p, m} -> (p * retention_factor) + (m * (1.0 - retention_factor)) end)
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

  defp cosine_similarity(vec1, vec2) do
    1.0 - cosine_distance(vec1, vec2)
  end

  defp generate_established_cultures() do
    Enum.map(1..@population_size, fn i ->
      {weights, niche} = case rem(i, 3) do
        0 -> {[0.85, 0.30, 0.30, 0.30], :compression}
        1 -> {[0.30, 0.85, 0.30, 0.30], :exploration}
        2 -> {[0.30, 0.30, 0.85, 0.30], :prediction}
      end
      %{
        id: "culture_init_#{i}", 
        lineage_id: "lineage_#{i}",
        parent_id: nil,
        mentor_lineage_id: nil,
        ancestral_weights: weights,
        original_niche: niche, 
        heuristic_weights: weights, 
        fitness: 0.0, 
        metrics: %{}
      }
    end)
  end

  defp initialize_lineage_registry(pop) do
    Map.new(pop, fn agent -> 
      {agent.lineage_id, %{
        parent_id: nil,
        mentor_lineage_id: nil,
        birth_epoch: 0,
        ancestral_weights: agent.ancestral_weights,
        original_niche: agent.original_niche,
        last_known_centroid: agent.heuristic_weights,
        current_niche: agent.original_niche,
        niche_history: [{0, agent.original_niche}],
        niche_change_epoch: 0,
        hybrid_duration_epochs: 0,
        is_currently_hybrid: false
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
    
    %{
      compression_score: comp_acc / steps, 
      novelty_score: nov_acc / steps, 
      prediction_score: pred_acc / steps
    }
  end
end

Tiannara.REA.MemeticTransferTest.run_memetic_transfer_test()
