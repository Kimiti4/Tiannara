defmodule Tiannara.ASC.Crucible.EpistemicRoutingCampaign do
  @moduledoc """
  Phase 5G: Demonstrates the compute conservation achieved by 
  routing transfer attempts through the minted Laws of Transfer Physics.
  """
  
  alias Tiannara.ASC.Crucible.TransferEcology
  alias Tiannara.ASC.Crucible.FailureSynthesizer
  alias Tiannara.ASC.Crucible.RepairLibrary
  alias Tiannara.ASC.Runtime
  require Logger

  @attempts 100

  def run do
    Logger.info("🧠 [Phase 5G] Initiating Epistemic Routing Campaign")
    :ok = Runtime.bootstrap()
    
    patterns = RepairLibrary.get_all_patterns()
    
    metrics = Enum.reduce(1..@attempts, %{executed: 0, aborted: 0, saved_cycles: 0}, fn _i, acc ->
      # Pick a random pattern and generate a random failure
      source = Enum.random(patterns)
      target_failure = FailureSynthesizer.generate(:rand.uniform(100))
      
      src_domain = get_in(source, [Access.key(:failure_classification, %{}), Access.key(:domain)]) || :unknown
      tgt_domain = Map.get(target_failure, :domain, :unknown)
      
      case TransferEcology.attempt_transfer_with_routing(source, target_failure) do
        {:aborted, reasons} ->
          Logger.debug("🛑 ABORTED: #{src_domain} -> #{tgt_domain} (Reasons: #{inspect(reasons)})")
          %{acc | aborted: acc.aborted + 1, saved_cycles: acc.saved_cycles + 1}
          
        {:success, _} ->
          %{acc | executed: acc.executed + 1}
          
        {:failure, _} ->
          %{acc | executed: acc.executed + 1}
      end
    end)

    Logger.info("""
    ======================================================================
    🧠 PHASE 5G EPISTEMIC ROUTING REPORT
    ======================================================================
    Total Transfer Attempts: #{@attempts}
    
    ✅ Executed (Organic Simulation): #{metrics.executed}
    🛑 Aborted (Epistemic Routing):   #{metrics.aborted}
    
    💾 Compute Cycles Saved: #{metrics.saved_cycles} (#{Float.round(metrics.saved_cycles / @attempts * 100, 1)}%)
    ======================================================================
    """)
  end
end
