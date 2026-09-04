# scripts/rea_5_4_resource_partitioning.exs
defmodule Tiannara.REA.ResourcePartitioningAudit do
  @moduledoc """
  Phase REA-5.4: Knowledge-Space Resource Partitioning Audit.
  
  Tracks visit frequencies in a late-game rolling window (Epochs 2501-3000)
  to calculate Weighted Jaccard and Cosine Similarity, proving whether niches
  are spatially partitioned or engaged in pure winner-take-all competition.
  """
  require Logger

  @epochs 3_000
  @population_size 100
  @mutation_rate 0.05
  @window_start 2501 # Only track occupancy after speciation has fully matured

  def run_audit() do
    Logger.info("🗺️ [REA-5.4] Initiating Resource Partitioning Audit (Maturity Window: Epochs #{@window_start}-#{@epochs})...")
    
    kg = generate_knowledge_graph(1_000)
    base_pop = generate_diverse_initial_population()
    
    niche_frequencies = %{
      compression: %{},
      exploration: %{},
      prediction: %{},
      generalist: %{}
    }
    
    {_final_pop, final_frequencies} = evolve_and_track(
      base_pop, kg, @epochs, niche_frequencies
    )
    
    analyze_partitioning(final_frequencies)
  end

  defp evolve_and_track(pop, _kg, 0, niche_maps), do: {pop, niche_maps}
  
  defp evolve_and_track(pop, kg, epochs_remaining, niche_maps) do
    current_epoch = @epochs - epochs_remaining + 1
    
    # If we hit the window start, reset the maps so we only track late-game mature occupancy
    working_maps = if current_epoch == @window_start do
      Logger.info("   [Epoch #{@window_start}] Speciation matured. Beginning occupancy tracking...")
      %{compression: %{}, exploration: %{}, prediction: %{}, generalist: %{}}
    else
      niche_maps
    end
    
    # 1. Evaluate Fitness & Track Visited Regions
    {evaluated_pop, updated_maps} = 
      Enum.map_reduce(pop, working_maps, fn agent, current_maps ->
        traversal = simulate_weighted_walk(agent.heuristic_weights, kg, 50)
        
        metrics = %{
          predictive_compression_ratio: traversal.compression_score,
          novelty_yield: traversal.novelty_score,
          prediction_accuracy: traversal.prediction_score
        }
        
        niche = classify_niche_by_behavior(metrics)
        fitness = (metrics.predictive_compression_ratio * 0.4) + 
                  (metrics.novelty_yield * 0.4) + 
                  (metrics.prediction_accuracy * 0.2)
                  
        # Add visited regions to the niche's frequency map ONLY if in the tracking window
        new_maps = if current_epoch >= @window_start do
          Map.update!(current_maps, niche, fn existing_freqs ->
            Enum.reduce(traversal.visited_nodes, existing_freqs, fn node, acc ->
              Map.update(acc, node, 1, &(&1 + 1))
            end)
          end)
        else
          current_maps
        end
        
        {%{agent | fitness: fitness, metrics: metrics}, new_maps}
      end)
    
    # 2. Tournament Selection
    survivors = Enum.map(1..@population_size, fn _ ->
      contenders = Enum.take_random(evaluated_pop, 3)
      Enum.max_by(contenders, & &1.fitness)
    end)
    
    # 3. Mutation
    next_gen = Enum.map(survivors, fn parent ->
      if :rand.uniform() < @mutation_rate do
        new_weights = Enum.map(parent.heuristic_weights, fn w ->
          max(0.0, min(1.0, w + (:rand.uniform() - 0.5) * 0.2))
        end)
        %{parent | id: "agent_#{System.unique_integer([:positive])}", heuristic_weights: new_weights, fitness: 0.0, metrics: %{}}
      else
        %{parent | id: "agent_#{System.unique_integer([:positive])}", fitness: 0.0, metrics: %{}}
      end
    end)
    
    evolve_and_track(next_gen, kg, epochs_remaining - 1, updated_maps)
  end

  defp classify_niche_by_behavior(metrics) do
    cond do
      metrics.predictive_compression_ratio >= 0.844 -> :compression
      metrics.novelty_yield >= 0.718 -> :exploration
      metrics.prediction_accuracy >= 0.725 -> :prediction
      true -> :generalist
    end
  end

  defp analyze_partitioning(niche_freqs) do
    Logger.info("\n==================================================")
    Logger.info("📊 REA-5.4 RESOURCE PARTITIONING VERDICT")
    Logger.info("==================================================")
    
    niches = [:compression, :exploration, :prediction, :generalist]
    
    Logger.info("Total Unique Regions Visited & Total Visits per Niche (Epochs #{@window_start}-#{@epochs}):")
    Enum.each(niches, fn niche ->
      freq_map = niche_freqs[niche]
      unique_nodes = map_size(freq_map)
      total_visits = Enum.sum(Map.values(freq_map))
      Logger.info("  - #{String.pad_trailing(String.capitalize(to_string(niche)), 12)}: #{unique_nodes} regions | #{total_visits} total visits")
    end)
    
    Logger.info("\n📐 Spatial Overlap Matrices (Weighted Jaccard & Cosine Similarity):")
    Logger.info("Format: Niche A ↔ Niche B = [W-Jaccard] | [Cosine]")
    Logger.info("--------------------------------------------------")
    
    for niche_a <- niches, niche_b <- niches, niche_a < niche_b do
      map_a = niche_freqs[niche_a]
      map_b = niche_freqs[niche_b]
      
      # Only compare if both niches survived in the tracking window
      if map_size(map_a) > 0 and map_size(map_b) > 0 do
        all_nodes = MapSet.union(MapSet.new(Map.keys(map_a)), MapSet.new(Map.keys(map_b)))
        
        # Weighted Jaccard (Ruzicka)
        {sum_min, sum_max} = Enum.reduce(all_nodes, {0.0, 0.0}, fn node, {min_acc, max_acc} ->
          a_val = Map.get(map_a, node, 0)
          b_val = Map.get(map_b, node, 0)
          {min_acc + min(a_val, b_val), max_acc + max(a_val, b_val)}
        end)
        w_jaccard = if sum_max == 0, do: 0.0, else: sum_min / sum_max
        
        # Cosine Similarity
        {dot_product, mag_a_sq, mag_b_sq} = Enum.reduce(all_nodes, {0.0, 0.0, 0.0}, fn node, {dp, ma, mb} ->
          a_val = Map.get(map_a, node, 0)
          b_val = Map.get(map_b, node, 0)
          {dp + (a_val * b_val), ma + (a_val * a_val), mb + (b_val * b_val)}
        end)
        cosine = if mag_a_sq == 0 or mag_b_sq == 0, do: 0.0, else: dot_product / (:math.sqrt(mag_a_sq) * :math.sqrt(mag_b_sq))
        
        Logger.info("  #{String.pad_trailing(to_string(niche_a), 12)} ↔ #{String.pad_trailing(to_string(niche_b), 12)} = J: #{Float.round(w_jaccard, 3)} | C: #{Float.round(cosine, 3)}")
      end
    end
    
    Logger.info("\n==================================================")
    Logger.info("🔍 INTERPRETATION GUIDE:")
    Logger.info("• High Overlap (> 0.60): Pure competition. Niches intensively mine the exact same regions.")
    Logger.info("• Medium Overlap (0.30 - 0.60): Partial partitioning. Some shared routes, but distinct hubs.")
    Logger.info("• Low Overlap (< 0.30): Hidden spatial ecology. True territorial division.")
    Logger.info("==================================================")
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
    
    %{
      compression_score: comp_acc / steps, 
      novelty_score: nov_acc / steps, 
      prediction_score: pred_acc / steps,
      visited_nodes: MapSet.to_list(visited)
    }
  end

  defp generate_diverse_initial_population do
    Enum.map(1..@population_size, fn i ->
      weights = case rem(i, 4) do
        0 -> [0.8, 0.3, 0.3, 0.3]
        1 -> [0.3, 0.8, 0.3, 0.3]
        2 -> [0.3, 0.3, 0.8, 0.3]
        3 -> [0.5, 0.5, 0.5, 0.5]
      end
      %{id: "init_#{i}", heuristic_weights: weights, fitness: 0.0, metrics: %{}}
    end)
  end
end

Tiannara.REA.ResourcePartitioningAudit.run_audit()
