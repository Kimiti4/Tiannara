defmodule Tiannara.CTL.CausalIntegrityPipeline do
  @moduledoc """
  Validates a branch prior to merge.
  Flow: Structural -> Poison Detection -> OCM Semantic Validation -> Reality Graph Validation
  """
  require Logger

  def validate_for_merge(branch_history, base_history) do
    with :ok <- structural_validation(branch_history),
         :ok <- poison_detection(branch_history),
         :ok <- ocm_semantic_validation(branch_history, base_history),
         :ok <- reality_graph_validation(branch_history) do
      {:ok, :approved}
    else
      {:error, :poison_detected} ->
        Logger.warning("☣️ [CTL] Causal Intrusion Detected! Branch contains fabricated events.")
        Tiannara.Metrics.Aggregator.push_event([:tiannara, :ctl, :causal_intrusion_rate], 1)
        {:error, :rejected_poisoned}
      {:error, :semantic_contradiction} ->
        Logger.warning("🗣️ [CTL] Semantic Contradiction Blocked by OCM.")
        {:error, :rejected_semantic}
      error -> error
    end
  end

  defp structural_validation(_), do: :ok
  
  defp poison_detection(history) do
    if Map.get(history, :poisoned, false) do
      {:error, :poison_detected}
    else
      :ok
    end
  end
  
  defp ocm_semantic_validation(branch_history, base_history) do
    if Map.get(branch_history, :semantic_shift) != Map.get(base_history, :semantic_shift) do
      {:error, :semantic_contradiction}
    else
      :ok
    end
  end
  
  defp reality_graph_validation(_), do: :ok
end
