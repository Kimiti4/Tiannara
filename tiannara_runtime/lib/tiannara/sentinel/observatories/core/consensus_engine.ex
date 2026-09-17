defmodule Tiannara.Sentinel.Observatories.Core.ConsensusEngine do
  @moduledoc """
  Fuses observatory signals using reliability-weighted consensus.
  
  PHASE D.1 CONSTRAINT: This module produces evidence ONLY.
  It has NO pathway to RecommendationEngine, TrajectoryGenerator, or InterventionRouter.
  """
  alias Tiannara.Sentinel.Observatories.Core.ReliabilityTracker
  alias Tiannara.Sentinel.Observatories.Types.ObservatorySignal

  @type observatory_signal :: ObservatorySignal.t()
  @type consensus_output :: %{
    action_scores: %{atom() => float()},
    preferred_action: atom(),
    consensus_strength: float(),
    observatory_weights: %{atom() => float()},
    reliability_summary: %{atom() => %{state: atom(), accuracy: float()}},
    timestamp: integer()
  }

  @spec fuse([observatory_signal()]) :: consensus_output()
  def fuse(signals) when is_list(signals) and signals != [] do
    # 1. Compute reliability weights for each observatory
    weights = 
      signals
      |> Enum.map(& &1.observatory)
      |> Enum.uniq()
      |> Map.new(&{&1, ReliabilityTracker.compute_weight(&1)})
    
    # 2. Weight each signal's confidence
    weighted_signals = 
      for signal <- signals do
        weight = Map.get(weights, signal.observatory, 0.3)  # Default low weight for unknown
        fused_conf = signal.confidence * weight
        Map.put(signal, :weighted_confidence, fused_conf)
      end
    
    # 3. Aggregate by recommended action
    action_scores = 
      weighted_signals
      |> Enum.group_by(& &1.recommended_action)
      |> Map.new(fn {action, group} ->
        total = Enum.map(group, & Map.get(&1, :weighted_confidence, 0.0)) |> Enum.sum()
        normalized = min(total / max(length(group), 1), 1.0)
        {action, Float.round(normalized, 3)}
      end)
    
    # 4. Determine preferred action and consensus strength
    {preferred, _max_score} = 
      if map_size(action_scores) > 0,
        do: Enum.max_by(action_scores, &elem(&1, 1)),
        else: {:none, 0.0}
    
    consensus_strength = compute_consensus_strength(action_scores)
    
    # 5. Build reliability summary for dashboard
    reliability_summary = 
      signals
      |> Enum.map(& &1.observatory)
      |> Enum.uniq()
      |> Map.new(fn obs_id ->
        %{state: state, metrics: metrics} = ReliabilityTracker.get_state(obs_id)
        {obs_id, %{state: state, accuracy: metrics.accuracy}}
      end)
    
    %{
      action_scores: action_scores,
      preferred_action: preferred,
      consensus_strength: Float.round(consensus_strength, 3),
      observatory_weights: weights,
      reliability_summary: reliability_summary,
      timestamp: System.system_time(:millisecond)
    }
  end

  defp compute_consensus_strength(action_scores) do
    # Measure concentration: 1.0 = unanimous, 0.0 = uniform distribution
    scores = Map.values(action_scores)
    if length(scores) <= 1, do: 1.0, else:
      (Enum.max(scores) - Enum.min(scores)) / (Enum.sum(scores) / length(scores) + 0.001)
  end

  @doc """
  PHASE D.1 SAFETY: Explicitly blocks any attempt to route consensus to recommendation systems.
  """
  @spec route_to_recommendation(any()) :: {:error, :phase_d1_boundary_violation}
  def route_to_recommendation(_consensus_output) do
    {:error, :phase_d1_boundary_violation}
  end
end
