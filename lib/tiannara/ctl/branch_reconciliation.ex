defmodule Tiannara.CTL.BranchReconciliation do
  @moduledoc """
  Safely merges branches if causal stress is acceptable.
  """
  require Logger
  alias Tiannara.CTL.CausalStressTensor
  alias Tiannara.CTL.ParadoxResolver
  alias Tiannara.CTL.HistoryIsolation
  alias Tiannara.CTL.CausalIntegrityPipeline

  def attempt_merge(branch_id, branch_h, base_h) do
    # 1. Pipeline Validation
    case CausalIntegrityPipeline.validate_for_merge(branch_h, base_h) do
      {:ok, :approved} ->
        # 2. Stress Tensor
        case CausalStressTensor.evaluate_stress(branch_h, base_h) do
          {:ok, _stress} ->
            execute_merge(branch_id)
            
          {:error, :stress_exceeded, _stress} ->
            # 3. Paradox Resolver
            case ParadoxResolver.resolve(branch_h, base_h) do
              {:ok, :resolved} ->
                execute_merge(branch_id)
              {:error, _reason} ->
                HistoryIsolation.isolate(branch_id)
            end
        end
        
      {:error, reason} ->
        Logger.error("🚫 [CTL] Merge Rejected by Integrity Pipeline: #{reason}")
        HistoryIsolation.isolate(branch_id)
    end
  end
  
  defp execute_merge(branch_id) do
    Logger.info("🔗 [CTL] Merging Branch #{branch_id} into Reality Graph...")
    Tiannara.Metrics.Aggregator.push_event([:tiannara, :ctl, :reconciliation_success], 1)
    {:ok, :merged}
  end
end
