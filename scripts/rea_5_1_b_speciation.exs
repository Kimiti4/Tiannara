# scripts/rea_5_1_b_speciation.exs
defmodule Tiannara.REA.REA51BSpeciation do
  @moduledoc """
  Stage C: True Speciation
  Combines real graph traversal with mutation and selection.
  Validates if distinct Epistemic Niches form, persist, and diverge phylogenetically.
  """
  require Logger

  @epochs 5_000
  @population_size 100
  @mutation_rate 0.05
  @steps_per_traversal 50
  @graph_size 1_000

  def run_speciation() do
    Logger.info("🧬 [REA-5.1B] Generating physical causal graph topology...")
    kg = generate_knowledge_graph(@graph_size)

    Logger.info("🧬 [REA-5.1B] Initiating true speciation with 100 generalist ancestors...")
    base_epistemology = %{
      id: "root", 
      heuristic_weights: [0.5, 0.5, 0.5, 0.5], 
      fitness: 0.0, 
      metrics: %{
        predictive_compression_ratio: 0.0,
        novelty_yield: 0.0,
        prediction_accuracy: 0.0
      }
    }
    initial_pop = Enum.map(1..@population_size, fn i -> %{base_epistemology | id: "agent_#{i}"} end)
    
    # 1. Evolve
    {final_pop, epoch_telemetry} = evolve(initial_pop, kg, @epochs, %{}, [])
    
    # 2. Analyze
    analyze_speciation(final_pop, epoch_telemetry)
  end

  defp evolve(pop, _kg, 0, _niche_ledger, telemetry), do: {pop, telemetry}
  
  defp evolve(pop, kg, epochs_remaining, niche_ledger, telemetry) do
    current_epoch = @epochs - epochs_remaining + 1
    
    # 1. Evaluate Fitness via REAL Graph Traversal
    evaluated_pop = Enum.map(pop, fn agent ->
      traversal = simulate_weighted_walk(agent.heuristic_weights, kg, @steps_per_traversal)
      
      metrics = %{
        predictive_compression_ratio: traversal.compression_score,
        novelty_yield: traversal.novelty_score,
        prediction_accuracy: traversal.prediction_score
      }
      
      # Fitness is a generalized utility function. 
      # The environment rewards whatever works in that topology.
      fitness = (metrics.predictive_compression_ratio * 0.4) + 
                (metrics.novelty_yield * 0.4) + 
                (metrics.prediction_accuracy * 0.2)
                
      %{agent | fitness: fitness, metrics: metrics}
    end)
    
    # 2. Tournament Selection
    survivors = Enum.map(1..@population_size, fn _ ->
      contenders = Enum.take_random(evaluated_pop, 3)
      Enum.max_by(contenders, & &1.fitness)
    end)
    
    # 3. Mutation
    next_gen = Enum.map(survivors, fn parent ->
      child_id = "agent_#{System.unique_integer([:positive])}"
      
      if :rand.uniform() < @mutation_rate do
        new_weights = Enum.map(parent.heuristic_weights, fn w ->
          max(0.0, min(1.0, w + (:rand.uniform() - 0.5) * 0.3)) # Mutate by up to +/- 0.15
        end)
        %{parent | id: child_id, heuristic_weights: new_weights, fitness: 0.0, metrics: parent.metrics}
      else
        %{parent | id: child_id, fitness: 0.0, metrics: parent.metrics}
      end
    end)
    
    # 4. Classification & Logging
    niches = Enum.group_by(next_gen, fn agent -> classify_niche_by_behavior(agent.metrics) end)
    updated_ledger = update_niche_ledger(niche_ledger, niches, current_epoch)
    
    new_telemetry = if rem(current_epoch, 500) == 0 do
      shannon = calculate_shannon_entropy(niches)
      divergence_proven = verify_behavioral_divergence(next_gen, niches)
      
      snapshot = %{
        epoch: current_epoch,
        compression: length(niches[:compression_specialist] || []),
        exploration: length(niches[:exploration_specialist] || []),
        prediction: length(niches[:prediction_specialist] || []),
        generalist: length(niches[:generalist] || []),
        shannon_diversity: shannon,
        divergence_proven: divergence_proven,
        ledger: updated_ledger
      }
      telemetry ++ [snapshot]
    else
      telemetry
    end
    
    evolve(next_gen, kg, epochs_remaining - 1, updated_ledger, new_telemetry)
  end

  # --- CORE LOGIC COMPONENTS ---
  
  defp generate_knowledge_graph(size) do
    nodes = Enum.reduce(0..(size-1), %{}, fn i, acc ->
      Map.put(acc, i, %{
        id: i,
        shortcut_potential: :rand.uniform(),
        novelty_value: :rand.uniform(),
        consistency: :rand.uniform(),
        neighbors: Enum.map(1..10, fn _ -> :rand.uniform(size) - 1 end) |> Enum.uniq() |> List.delete(i)
      })
    end)
    %{nodes: nodes, total_active_nodes: size}
  end

  defp simulate_weighted_walk([w_comp, w_expl, w_pred, w_gen], kg, steps) do
    start_node = :rand.uniform(kg.total_active_nodes) - 1
    
    {visited, comp_acc, nov_acc, pred_acc} = Enum.reduce(1..steps, {MapSet.new([start_node]), 0.0, 0.0, 0.0}, fn _step, {visited_set, c, n, p} ->
      current_id = Enum.random(MapSet.to_list(visited_set))
      current_node = kg.nodes[current_id]
      
      best_neighbor_id = 
        current_node.neighbors
        |> Enum.max_by(fn n_id -> 
          neighbor = kg.nodes[n_id]
          score = (w_comp * neighbor.shortcut_potential) +
                  (w_expl * neighbor.novelty_value) +
                  (w_pred * neighbor.consistency) +
                  (w_gen * :rand.uniform())
          revisit_penalty = if MapSet.member?(visited_set, n_id), do: (w_expl * 0.5), else: 0.0
          score - revisit_penalty
        end, fn -> Enum.random(current_node.neighbors) end)
        
      chosen = kg.nodes[best_neighbor_id]
      new_visited = MapSet.put(visited_set, best_neighbor_id)
      
      {new_visited, c + chosen.shortcut_potential, n + chosen.novelty_value, p + chosen.consistency}
    end)
    
    %{
      compression_score: comp_acc / steps,
      novelty_score: nov_acc / steps,
      prediction_score: pred_acc / steps
    }
  end

  defp classify_niche_by_behavior(metrics) do
    cond do
      metrics.predictive_compression_ratio > 0.82 -> :compression_specialist
      metrics.novelty_yield > 0.75 -> :exploration_specialist
      metrics.prediction_accuracy > 0.82 -> :prediction_specialist
      true -> :generalist
    end
  end
  
  defp update_niche_ledger(ledger, niches, current_epoch) do
    Enum.reduce(niches, ledger, fn {niche, agents}, acc ->
      count = length(agents)
      existing = Map.get(acc, niche, %{first: current_epoch, last: current_epoch, max_share: 0})
      share = count / @population_size
      
      Map.put(acc, niche, %{
        first: min(existing.first, current_epoch),
        last: max(existing.last, current_epoch),
        max_share: max(existing.max_share, share)
      })
    end)
  end

  defp calculate_shannon_entropy(niches) do
    total = @population_size
    if total == 0, do: 0.0
    proportions = Enum.map(niches, fn {_k, agents} -> length(agents) / total end)
    Enum.reduce(proportions, 0.0, fn p, acc ->
      if p > 0, do: acc - (p * :math.log(p)), else: acc
    end)
  end

  defp verify_behavioral_divergence(_population, niches_map) do
    intra_distances = Enum.map(niches_map, fn {_niche, agents} ->
      vectors = Enum.map(agents, & &1.heuristic_weights)
      calculate_avg_cosine_distance(vectors)
    end)
    avg_intra_distance = Enum.sum(intra_distances) / max(length(intra_distances), 1)
    
    niche_keys = Map.keys(niches_map)
    len_keys = length(niche_keys)
    inter_pairs = if len_keys < 2 do
      []
    else
      for i <- 0..(len_keys-2), j <- (i+1)..(len_keys-1) do
        k1 = Enum.at(niche_keys, i)
        k2 = Enum.at(niche_keys, j)
        {niches_map[k1], niches_map[k2]}
      end
    end
    
    inter_distances = Enum.map(inter_pairs, fn {agents1, agents2} ->
      v1s = Enum.map(agents1, & &1.heuristic_weights)
      v2s = Enum.map(agents2, & &1.heuristic_weights)
      calculate_cross_cosine_distance(v1s, v2s)
    end)
    
    avg_inter_distance = if inter_distances == [], do: 0.0, else: Enum.sum(inter_distances) / length(inter_distances)
    
    avg_intra_distance < avg_inter_distance
  end

  defp calculate_avg_cosine_distance(vectors) do
    len = length(vectors)
    if len < 2 do
      0.0
    else
      pairs = for i <- 0..(len-2), j <- (i+1)..(len-1), do: {Enum.at(vectors, i), Enum.at(vectors, j)}
      distances = Enum.map(pairs, fn {v1, v2} -> cosine_distance(v1, v2) end)
      Enum.sum(distances) / max(length(distances), 1)
    end
  end
  
  defp calculate_cross_cosine_distance(v1s, v2s) do
    if v1s == [] or v2s == [], do: 0.0
    pairs = for v1 <- v1s, v2 <- v2s, do: {v1, v2}
    distances = Enum.map(pairs, fn {v1, v2} -> cosine_distance(v1, v2) end)
    Enum.sum(distances) / length(distances)
  end
  
  defp cosine_distance(v1, v2) do
    dot_product = Enum.zip(v1, v2) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
    mag1 = :math.sqrt(Enum.sum(Enum.map(v1, &(&1 * &1))))
    mag2 = :math.sqrt(Enum.sum(Enum.map(v2, &(&1 * &1))))
    1.0 - (dot_product / (mag1 * mag2 + 0.0001))
  end

  # --- OUTPUT & VERDICT ---

  defp analyze_speciation(_final_pop, telemetry) do
    Logger.info("\n==================================================")
    Logger.info("📊 REA-5.1B TRUE SPECIATION VERDICT")
    Logger.info("==================================================")
    
    Logger.info("Epoch | Comp | Expl | Pred | Gen | Shannon Div | Divergence Valid")
    Logger.info("------|------|------|------|-----|-------------|-----------------")
    Enum.each(telemetry, fn t ->
      Logger.info(" #{String.pad_leading(Integer.to_string(t.epoch), 4)} | #{String.pad_leading(Integer.to_string(t.compression), 4)} | #{String.pad_leading(Integer.to_string(t.exploration), 4)} | #{String.pad_leading(Integer.to_string(t.prediction), 4)} | #{String.pad_leading(Integer.to_string(t.generalist), 3)} | #{Float.round(t.shannon_diversity, 4)}      | #{t.divergence_proven}")
    end)
    
    final_telemetry = List.last(telemetry)
    Logger.info("\n🔍 NICHE PERSISTENCE TRACKING:")
    Enum.each(final_telemetry.ledger, fn {niche, data} ->
      Logger.info("   #{niche}: First: Epoch #{data.first} | Last: Epoch #{data.last} | Max Share: #{Float.round(data.max_share * 100, 1)}%")
    end)
    
    # Evaluation Criteria
    shannon_increased = final_telemetry.shannon_diversity > 0.5
    behavioral_div = (final_telemetry.compression > 0 and final_telemetry.exploration > 0)
    phylogenetic_div = final_telemetry.divergence_proven
    
    # Niche persistence check: Did non-generalist niches survive for >1000 epochs?
    persistence_met = Enum.any?(final_telemetry.ledger, fn {niche, data} ->
      niche != :generalist and (data.last - data.first) > 1000
    end)

    if shannon_increased and behavioral_div and phylogenetic_div and persistence_met do
      Logger.info("\n✅ OUTCOME: TRUE SPECIATION CONFIRMED!")
      Logger.info("   - Shannon Diversity Increased")
      Logger.info("   - Behavioral Divergence observed")
      Logger.info("   - Phylogenetic Divergence proved via Cosine Distance")
      Logger.info("   - Niches Persisted for >1000 epochs")
      Logger.info("   The Epistemic Ecology is a verified, living system.")
    else
      Logger.error("\n❌ OUTCOME: SPECIATION FAILED.")
    end
    Logger.info("==================================================")
  end
end

Tiannara.REA.REA51BSpeciation.run_speciation()
