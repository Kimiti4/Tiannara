defmodule Tiannara.TWP.WavefunctionPruner do
  @moduledoc """
  Evaluates branch survivability based on probability and relevance.
  """
  require Logger
  alias Tiannara.TWP.ObserverBiasAnalyzer
  alias Tiannara.TWP.BranchCompressor
  alias Tiannara.TWP.ArchiveManager
  alias Tiannara.TWP.TimelineLineageTracker

  def evaluate_survival(branch_id, branch_state) do
    # 1. Bias Check
    case ObserverBiasAnalyzer.check_bias(branch_state) do
      {:ok, :unbiased} ->
        prob = Map.get(branch_state, :probability, 1.0)
        
        cond do
          prob > 0.5 -> 
            {:ok, :survives}
          prob > 0.1 ->
            TimelineLineageTracker.record_ancestry(branch_id, :compressed)
            BranchCompressor.compress(branch_id, branch_state)
          true ->
            TimelineLineageTracker.record_ancestry(branch_id, :archived)
            ArchiveManager.archive(branch_id, branch_state)
        end
        
      {:error, :bias_detected} ->
        Logger.warning("⚖️ [TWP] Observer bias detected. Protecting epistemically valid branch from pruning.")
        {:ok, :survives_protected}
    end
  end
  
  def check_monoculture(active_branches) do
    # Test 9: Timeline Monoculture
    diversity = length(Enum.uniq_by(active_branches, &(&1.topology_hash))) / max(1, length(active_branches))
    Tiannara.Metrics.Aggregator.push_event([:tiannara, :twp, :timeline_diversity], diversity)
    
    if diversity < 0.1 do
      Logger.warning("⚠️ [TWP] Timeline Monoculture Detected! Pruning pressure too high.")
    end
  end
end
