defmodule Tiannara.REA.Phase11_6.Operational do
  @moduledoc """
  Operational Phase 11.6 — The Inverted-U Hypothesis in Practice.
  
  This module implements the "Structured Forgetting Engine" for Tiannara.
  It tests whether selective retention of memory (Experiments, Specialist History, World Model)
  outperforms pure preservation or pure renewal.
  """
  require Logger
  alias Tiannara.Sentinel.OperationalObservatory

  @doc """
  Adaptive Retention Engine: Calculates the dynamic_estimate() for retention levels
  based on memory class and operational history.
  """
  def dynamic_estimate(memory_class) do
    # Default targets based on Phase 11.6B hypotheses
    targets = %{
      experiment_logs: 0.65,
      failures: 0.95,
      architecture: 0.83,
      telemetry: 0.05,
      specialist_context: 0.55
    }

    base_optimum = Map.get(targets, memory_class, 0.60)
    
    # In a real operational cycle, this would adjust based on 
    # DVR and GHL trends from the Operational Observatory.
    # For now, we use the base hypothesis.
    base_optimum
  end

  @doc """
  Runs a memory retention experiment on a target subsystem.
  """
  def run_retention_experiment(target, level_override \\ nil) do
    # Use dynamic estimate if no override is provided
    level = level_override || dynamic_estimate(target)
    
    Logger.info("[Phase 11.6B] Applying adaptive retention to #{target} at #{level * 100}%.")
    
    case target do
      :experiment_logs -> perform_sentinel_retention(level)
      :failures -> perform_failure_retention(level)
      :architecture -> perform_world_model_retention(level)
      :specialists -> perform_specialist_retention(level)
      _ -> {:error, :unknown_target}
    end
  end

  defp perform_failure_retention(level) do
    Logger.info("[Phase 11.6B] Applying #{level * 100}% retention to Failure Logs (High Stability).")
    {:ok, %{retention: level, target: :failures}}
  end

  @doc """
  Structured Forgetting Engine: Filters data based on value and retention level.
  Instead of simple random forgetting, it prioritizes high-value discoveries.
  """
  def filter_by_value(data, retention_level) do
    # Sort by value (e.g., Promotion Value Score)
    sorted_data = Enum.sort_by(data, &OperationalObservatory.calculate_promotion_score(&1.metrics), :desc)
    
    # Take the top percentage defined by retention_level
    count = round(length(data) * retention_level)
    Enum.take(sorted_data, count)
  end

  # --- Experiment A: Sentinel Retention ---
  defp perform_sentinel_retention(level) do
    # Logic to filter historical experiments in the Sentinel's memory
    # In practice, this would modify the query results from the Epistemology Archive
    Logger.info("[Phase 11.6] Applying #{level * 100}% retention to Sentinel Experiment Memory.")
    {:ok, %{retention: level, target: :sentinel}}
  end

  # --- Experiment B: Specialist Memory Retention ---
  defp perform_specialist_retention(level) do
    # Asymmetric memory retention for specialists
    # Architect: 1.0 (100%), Engineer: 0.5 (50%), Researcher: 0.25 (25%)
    # The 'level' passed here acts as a global multiplier for their default ratios.
    Logger.info("[Phase 11.6] Applying #{level * 100}% scaled retention to Specialist Ecology.")
    
    ratios = %{
      architect: 1.0 * level,
      engineer: 0.5 * level,
      researcher: 0.25 * level
    }
    
    {:ok, %{retention_ratios: ratios, target: :specialists}}
  end

  # --- Experiment C: World Model Compression ---
  defp perform_world_model_retention(level) do
    # Compresses the architecture graph
    Logger.info("[Phase 11.6] Applying #{level * 100}% retention (compression) to World Model Architecture Graph.")
    {:ok, %{retention: level, target: :world_model}}
  end
end
