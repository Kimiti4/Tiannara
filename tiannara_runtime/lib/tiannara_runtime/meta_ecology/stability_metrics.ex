defmodule Tiannara.MetaEcology.StabilityMetrics do
  @moduledoc """
  Meta-Ecology: Stability Metrics.
  
  Calculates macro-level ecological health across a cluster of worlds.
  - Diversity Index (H)
  - Cross-World Coherence (C)
  - Causal Pressure Balance (P)
  - Entropy Oscillation Stability (S)
  - Niche Utilization Rate (N)
  """
  
  require Logger
  
  @doc """
  Evaluates the stability of a given meta-ecology state.
  Computes all metrics from actual cluster world data.
  """
  def evaluate_cluster_health(cluster_state) do
    worlds = Map.get(cluster_state, :worlds, [])
    
    # Compute Diversity Index (H) from world entropy distribution
    h = compute_diversity_index(worlds)
    
    # Compute Cross-World Coherence (C) from world state correlations
    c = compute_cross_world_coherence(worlds)
    
    # Compute Causal Pressure Balance (P) from inter-world pressure differentials
    p = compute_causal_pressure_balance(worlds)
    
    # Compute Entropy Oscillation Stability (S) from entropy variance over time
    s = compute_entropy_oscillation_stability(worlds)
    
    # Compute Niche Utilization Rate (N) from resource usage across worlds
    n = compute_niche_utilization_rate(worlds)
    
    Logger.debug("📊 [Meta-Ecology] Calculating cluster health... H=#{Float.round(h, 4)}, C=#{Float.round(c, 4)}, P=#{Float.round(p, 4)}, S=#{Float.round(s, 4)}, N=#{Float.round(n, 4)}")
    
    # Stable condition: H is high, C is moderate, P is balanced, S is damped, N is high.
    is_stable = h > 0.6 and c > 0.4 and c < 0.8 and p > 0.3 and p < 0.7 and s > 0.8 and n > 0.6
    
    if is_stable do
      Logger.info("✅ [Meta-Ecology] Cluster is STABLE. Meta-civilizational homeostasis achieved.")
      {:ok, :stable}
    else
      Logger.warning("⚠️ [Meta-Ecology] Cluster is UNSTABLE. Risk of synchronized collapse.")
      {:error, :unstable}
    end
  end

  defp compute_diversity_index(worlds) do
    case length(worlds) do
      0 -> 0.0
      1 -> 1.0
      n ->
        entropies = Enum.map(worlds, fn w -> Map.get(w, :entropy, 0.5) end)
        mean_entropy = Enum.sum(entropies) / n
        variance = Enum.sum(Enum.map(entropies, fn e -> :math.pow(e - mean_entropy, 2) end)) / n
        # Normalize to 0-1 range using sigmoid of variance
        1.0 / (1.0 + variance)
    end
  end

  defp compute_cross_world_coherence(worlds) do
    case length(worlds) do
      0 -> 0.0
      1 -> 1.0
      n ->
        # Compute pairwise coherence based on state similarity
        coherence_pairs = for i <- 0..(n-2), j <- (i+1)..(n-1) do
          wi = Enum.at(worlds, i)
          wj = Enum.at(worlds, j)
          state_similarity = compute_state_similarity(wi, wj)
          state_similarity
        end
        Enum.sum(coherence_pairs) / length(coherence_pairs)
    end
  end

  defp compute_state_similarity(w1, w2) do
    e1 = Map.get(w1, :entropy, 0.5)
    e2 = Map.get(w2, :entropy, 0.5)
    c1 = Map.get(w1, :coherence, 0.5)
    c2 = Map.get(w2, :coherence, 0.5)
    # Cosine-like similarity
    1.0 - (abs(e1 - e2) + abs(c1 - c2)) / 2.0
  end

  defp compute_causal_pressure_balance(worlds) do
    case length(worlds) do
      0 -> 0.5
      n ->
        pressures = Enum.map(worlds, fn w -> Map.get(w, :pressure, 0.5) end)
        mean_p = Enum.sum(pressures) / n
        max_dev = Enum.max(Enum.map(pressures, fn p -> abs(p - mean_p) end))
        # Balance is high when max deviation is low
        1.0 - min(1.0, max_dev)
    end
  end

  defp compute_entropy_oscillation_stability(worlds) do
    case length(worlds) do
      0 -> 0.9
      n ->
        entropy_histories = Enum.map(worlds, fn w -> Map.get(w, :entropy_history, []) end)
        # Measure variance of entropy over time for each world
        stabilities = Enum.map(entropy_histories, fn history ->
          case history do
            [] -> 0.9
            _ ->
              mean = Enum.sum(history) / length(history)
              variance = Enum.sum(Enum.map(history, fn e -> :math.pow(e - mean, 2) end)) / length(history)
              1.0 / (1.0 + variance)
          end
        end)
        Enum.sum(stabilities) / length(stabilities)
    end
  end

  defp compute_niche_utilization_rate(worlds) do
    case length(worlds) do
      0 -> 0.75
      n ->
        # Compute how well resources are distributed across worlds
        resource_usage = Enum.map(worlds, fn w -> Map.get(w, :resource_utilization, 0.5) end)
        mean_usage = Enum.sum(resource_usage) / n
        # Penalize both underutilization and overutilization
        min(mean_usage / 0.8, (1.0 - mean_usage) / 0.2 + mean_usage / 0.8) |> min(1.0)
    end
  end
end
