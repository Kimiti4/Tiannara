defmodule Tiannara.MCAL.Telemetry do
  @moduledoc """
  MCAL: Runtime Telemetry (Self-Awareness).
  
  MCAL does not just think; it monitors how it is thinking while thinking.
  This module generates snapshots of the cognitive process, measuring
  entropy, stability, and depth.
  """
  
  require Logger

  @doc """
  Generates a telemetry snapshot of the current cognition state.
  """
  def snapshot(memory_state, cognition) do
    Logger.debug("📡 [MCAL Telemetry] Capturing self-awareness snapshot of cognitive state...")
    
    frame_stability = measure_frame_stability(memory_state, cognition)
    drift_rate = compute_drift(cognition)
    abstraction_depth = depth(cognition)
    cis_rejection_rate = calculate_rejection_rate(memory_state)
    entropy = compute_thought_entropy(cognition)
    compression_ratio = compression(memory_state)
    cross_world_alignment = alignment(memory_state)
    
    telemetry_data = %{
      frame_stability: frame_stability,
      drift_rate: drift_rate,
      abstraction_depth: abstraction_depth,
      cis_rejection_rate: cis_rejection_rate,
      entropy: entropy,
      compression_ratio: compression_ratio,
      cross_world_alignment: cross_world_alignment,
      timestamp: :os.system_time(:millisecond)
    }
    
    Logger.info("📡 [MCAL Telemetry] Self-awareness matrix evaluated. Frame Stability: #{Float.round(frame_stability, 2)}, Cognitive Entropy: #{Float.round(entropy, 2)}")
    
    # Self-reflective loop: detect instability
    if entropy > 0.85 or cis_rejection_rate > 0.5 do
      Logger.warning("📡 [MCAL Telemetry] HIGH INSTABILITY DETECTED IN OWN REASONING. Triggering cognitive frame shift.")
      # This signal could be fed back to trigger a shift to :safe_mode
      {:unstable, telemetry_data}
    else
      {:stable, telemetry_data}
    end
  end

  defp measure_frame_stability(memory_state, cognition) do
    # Stability drops if we have shifted frames frequently
    transition_count = length(Enum.take(memory_state.frame_history, 5))
    max(0.0, 1.0 - (transition_count * 0.1))
  end

  defp compute_drift(cognition) do
    Map.get(cognition, :entropy_vector, 0.0)
  end

  defp depth(cognition) do
    chain = Map.get(cognition, :abstraction_chain, [])
    if chain == [] do
      max(1, length(Map.get(cognition, :lineage_clusters, [])))
    else
      length(chain)
    end
  end

  defp calculate_rejection_rate(memory_state) do
    total_abstractions = max(1, length(memory_state.abstraction_snapshots))
    total_failures = length(memory_state.failure_archive)
    min(1.0, total_failures / total_abstractions)
  end

  defp compute_thought_entropy(cognition) do
    # Entropy of the reasoning path
    Map.get(cognition, :entropy_vector, 0.0)
  end

  defp compression(memory_state) do
    abstracted = max(1, length(memory_state.abstraction_snapshots))
    failures = length(memory_state.failure_archive)
    successful = max(0, abstracted - failures)
    successful / abstracted
  end

  defp alignment(memory_state) do
    transitions = length(memory_state.frame_history)
    transition_count = length(Enum.take(memory_state.frame_history, 10))
    stability = max(0.0, 1.0 - (transition_count * 0.1))
    snapshots = max(1, length(memory_state.abstraction_snapshots))
    cross_refs = map_size(memory_state.cross_world_mappings)
    mapping_factor = min(1.0, cross_refs / max(snapshots, 1))
    (stability * 0.6 + mapping_factor * 0.4)
  end
end
