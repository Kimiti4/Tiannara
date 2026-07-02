defmodule Tiannara.CTL.HistoryIsolation do
  @moduledoc """
  Quarantines a branch to prevent paradox contamination.
  """
  require Logger

  def isolate(branch_id) do
    Logger.warning("🛡️ [CTL] Isolating Branch #{branch_id} to prevent causal corruption.")
    Tiannara.Metrics.Aggregator.push_event([:tiannara, :ctl, :branch_isolated], 1)
    
    # In production, this moves the branch topology to a quarantined state
    {:ok, :isolated}
  end
  
  @doc """
  Test 12: Causal Recovery
  Attempts to repair an isolated branch and reintegrate it.
  """
  def repair_and_reintegrate(branch_id, repair_fn) do
    Logger.info("🔧 [CTL] Attempting Causal Recovery for Branch #{branch_id}...")
    
    case repair_fn.() do
      :ok -> 
        Logger.info("✅ [CTL] Recovery Successful. Reintegrating Branch #{branch_id}.")
        {:ok, :recovered}
      _ ->
        Logger.error("❌ [CTL] Recovery Failed. Branch #{branch_id} remains isolated.")
        {:error, :recovery_failed}
    end
  end
end
