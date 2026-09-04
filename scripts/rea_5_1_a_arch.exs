# scripts/rea_5_1_a_arch.exs
defmodule Tiannara.REA.REA51A_ARCH do
  @moduledoc """
  Stage A: Architecture Validation (Simulated Traversal)
  Validates telemetry pipeline, Shannon entropy, niche persistence, and divergence logic.
  Does NOT prove scientific speciation.
  """
  require Logger

  @epochs 5_000
  @population_size 100

  def run_architecture_validation() do
    Logger.info("🧬 [REA-5.1A-ARCH] Validating Epistemic Ecology Telemetry Architecture...")
    
    # 1. Initialize dummy population
    base_epistemology = %{id: "root", heuristic_weights: [0.5, 0.5, 0.5, 0.5], metrics: %{}}
    initial_pop = Enum.map(1..@population_size, fn i -> %{base_epistemology | id: "agent_#{i}"} end)
    
    # 2. Simulate 5000 epochs of execution and capture telemetry
    telemetry = simulate_evolution_loop(initial_pop, @epochs, %{}, [])
    
    # 3. Validate Telemetry Pipeline
    Logger.info("✅ Architecture Validation Complete. Running Pipeline Diagnostics...")
    validate_telemetry_pipeline(telemetry)
  end

  defp simulate_evolution_loop(_pop, 0, _niche_ledger, telemetry), do: telemetry
  
  defp simulate_evolution_loop(pop, epochs_remaining, niche_ledger, telemetry) do
    current_epoch = @epochs - epochs_remaining + 1
    
    # Mocking behavior-based classification and weights for the architecture test
    # We will simulate a drift towards specific niches over time
    mocked_pop = Enum.map(pop, fn agent ->
      niche = case rem(:erlang.phash2(agent.id, 100) + current_epoch, 100) do
        x when x < 30 -> :compression_specialist
        x when x < 60 -> :exploration_specialist
        x when x < 90 -> :prediction_specialist
        _ -> :generalist
      end
      
      # Mock weights that cluster by niche
      weights = case niche do
        :compression_specialist -> [0.9, 0.3, 0.3, 0.3]
        :exploration_specialist -> [0.3, 0.9, 0.3, 0.3]
        :prediction_specialist -> [0.3, 0.3, 0.9, 0.3]
        :generalist -> [0.5, 0.5, 0.5, 0.5]
      end
      
      %{agent | heuristic_weights: weights, metrics: %{mocked_niche: niche}}
    end)
    
    niches = Enum.group_by(mocked_pop, & &1.metrics.mocked_niche)
    
    # Update Niche Ledger (Persistence Tracking)
    updated_ledger = update_niche_ledger(niche_ledger, niches, current_epoch)
    
    # Snapshot Telemetry every 500 epochs
    new_telemetry = if rem(current_epoch, 500) == 0 do
      shannon = calculate_shannon_entropy(niches)
      divergence_proven = verify_behavioral_divergence(mocked_pop, niches)
      
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
    
    simulate_evolution_loop(mocked_pop, epochs_remaining - 1, updated_ledger, new_telemetry)
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
    # True Inter-Niche vs Intra-Niche Cosine Distance Proof
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

  defp validate_telemetry_pipeline(telemetry) do
    Logger.info("\n==================================================")
    Logger.info("📊 REA-5.1A-ARCH TELEMETRY VALIDATION")
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
    Logger.info("==================================================")
  end
end

Tiannara.REA.REA51A_ARCH.run_architecture_validation()
