defmodule Tiannara.MCAL.CrossWorldMapper do
  @moduledoc """
  MCAL: Cross-World Mapper.
  
  Maps cognition across civilizations/worlds. Prevents "Cumulative Drift Collapse"
  by anchoring local reality variations against a global coherent semantic space.
  """
  
  require Logger

  @doc """
  Maps and compares semantic structures across a list of world states.
  """
  def map(world_states) when is_list(world_states) do
    Logger.debug("🌐 [MCAL Cross-World] Analyzing semantic divergence across #{length(world_states)} worlds...")
    
    Enum.map(world_states, fn world ->
      %{
        world_id: world.id,
        similarity_to_others: cosine_similarity(world, world_states),
        divergence_score: compute_divergence(world),
        shared_invariants: extract_invariants(world)
      }
    end)
  end
  
  def map(trace_state) when not is_list(trace_state) do
    Logger.debug("🌐 [MCAL Cross-World] Tracing single mutation impact against global baseline...")
    %{
      similarity_to_others: max(0.0, Map.get(trace_state, :confidence, 0.5)),
      divergence_score: min(1.0, (Map.get(trace_state, :divergence, 0.0) || 0.0) / 100.0),
      shared_invariants: [:causal_arrow, :energy_conservation]
    }
  end

  defp cosine_similarity(world, all_worlds) do
    other_worlds = Enum.reject(all_worlds, fn w -> w.id == world.id end)
    if other_worlds == [] do
      1.0
    else
      Enum.reduce(other_worlds, 0.0, fn w, acc ->
        acc + compute_pairwise_similarity(world, w)
      end) / length(other_worlds)
    end
  end

  defp compute_pairwise_similarity(world_a, world_b) do
    confidence_a = Map.get(world_a, :confidence, 0.5)
    confidence_b = Map.get(world_b, :confidence, 0.5)
    divergence_a = Map.get(world_a, :divergence, 0.0)
    divergence_b = Map.get(world_b, :divergence, 0.0)
    conf_sim = 1.0 - abs(confidence_a - confidence_b)
    div_sim = 1.0 - min(1.0, abs(divergence_a - divergence_b) / 100.0)
    conf_sim * 0.6 + div_sim * 0.4
  end
  
  defp compute_divergence(world) do
    base = Map.get(world, :divergence, 0.0)
    entropy = Map.get(world, :entropy, 0.0)
    min(1.0, (abs(base) + abs(entropy) * 0.5) / 100.0)
  end
  
  defp extract_invariants(world) do
    invariants = [:causal_arrow, :energy_conservation]
    if Map.get(world, :divergence, 0.0) > 50.0 do
      [:temporal_ordering | invariants]
    else
      invariants
    end
  end
end
