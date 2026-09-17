defmodule Tiannara.Sentinel.Observatories.Core.HealthReport do
  @moduledoc """
  Primary dashboard API for Phase D.1.
  Exposes observatory reliability states and consensus_advantage_live metric.
  """
  alias Tiannara.Sentinel.Observatories.Core.{ReliabilityTracker, MetricsCollector}

  @spec observatory_report() :: map()
  def observatory_report do
    # Get all active observatories
    active_obs = [:runtime, :ecological, :semantic]
    
    # Build observatory details
    observatories = 
      Map.new(active_obs, fn obs_id ->
        %{state: status, metrics: metrics} = ReliabilityTracker.get_state(obs_id)
        reliability = ReliabilityTracker.compute_weight(obs_id)
        diversity = Tiannara.Sentinel.Observatories.EpistemicDiversityTracker.get_diversity_index(obs_id)
        
        {obs_id, %{
          certification: status,
          reliability: Float.round(reliability, 3),
          diversity: Float.round(diversity || 0.0, 3),
          calibration_error: Float.round(metrics.calibration_error, 3),
          drift_velocity: Map.get(metrics, :drift_velocity, 0.0),
          drift_acceleration: Map.get(metrics, :drift_acceleration, 0.0)
        }}
      end)
    
    # Consensus metrics from recent window
    {consensus_strength, disagreement_rate, epistemic_tension} = 
      MetricsCollector.get_recent_consensus_metrics(window_minutes: 60)
    
    # CRITICAL METRIC: consensus_advantage_live
    consensus_advantage = compute_consensus_advantage_live(active_obs)
    
    mesh_diversity = Tiannara.Sentinel.Observatories.EpistemicDiversityTracker.get_mesh_diversity_index()
    disagreement_win_rates = MetricsCollector.get_disagreement_win_rates()
    alignment = Tiannara.Sentinel.Observatories.Core.AlignmentTracker.get_alignment_metrics()

    criteria = %{
      trusted_observatories: count_trusted(observatories) >= 3,
      stable_days: Tiannara.Sentinel.Observatories.Core.ObservatoryArchive.get_stable_days() >= 30,
      consensus_advantage_live: consensus_advantage > 0,
      avg_calibration_error: avg_calibration_error(observatories) < 0.15,
      mesh_diversity_index: mesh_diversity > 0.25,
      disagreement_archives: 0 >= 100, # Placeholder
      shadow_observatory_alignment: alignment.alignment > 0.70
    }
    
    failed_conditions = 
      criteria
      |> Enum.reject(fn {_, passed} -> passed end)
      |> Enum.map(fn {key, _} -> key end)

    promotion_gate = %{
      d2_ready: failed_conditions == [],
      failed_conditions: failed_conditions
    }

    %{
      active_observatories: length(active_obs),
      observatories: observatories,
      consensus_strength: Float.round(consensus_strength, 3),
      disagreement_rate: Float.round(disagreement_rate, 3),
      epistemic_tension: Float.round(epistemic_tension, 3),
      consensus_advantage_live: Float.round(consensus_advantage, 3),
      mesh_diversity_index: mesh_diversity,
      disagreement_win_rates: disagreement_win_rates,
      shadow_observatory_alignment: alignment,
      promotion_gate: promotion_gate
    }
  end

  defp count_trusted(observatories) do
    observatories |> Map.values() |> Enum.count(&(&1.certification == :trusted))
  end

  defp avg_calibration_error(observatories) do
    if map_size(observatories) == 0 do
      1.0
    else
      sum = observatories |> Map.values() |> Enum.map(& &1.calibration_error) |> Enum.sum()
      sum / map_size(observatories)
    end
  end

  defp compute_consensus_advantage_live(active_obs) do
    # Compare consensus prediction accuracy vs best single observatory
    # Over recent live telemetry window
    recent_cases = MetricsCollector.get_recent_evaluation_cases()
    
    if length(recent_cases) < 10 do
      0.0  # Insufficient data
    else
      # Consensus accuracy
      consensus_correct = 
        Enum.count(recent_cases, fn %{consensus_prediction: pred, observed: obs} -> 
          pred == obs 
        end)
      consensus_acc = consensus_correct / length(recent_cases)
      
      # Best single observatory accuracy
      best_single_acc = 
        active_obs
        |> Enum.map(fn obs_id ->
          correct = Enum.count(recent_cases, fn %{observatory_predictions: preds, observed: obs} -> 
            Map.get(preds, obs_id) == obs 
          end)
          correct / length(recent_cases)
        end)
        |> Enum.max(fn -> 0.0 end)
      
      # Advantage = consensus_acc - best_single_acc
      # Positive = consensus improves over best single observer
      consensus_acc - best_single_acc
    end
  end
end
