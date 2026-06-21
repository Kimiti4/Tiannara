defmodule Tiannara.ASC.Reality.Observatory do
  @moduledoc """
  Phase 8B: Instrumentation layer for physical engineering events.
  Records real-world interactions with repositories, builds, and tests.
  """
  
  require Logger

  def record_patch_proposed(proposal_id, purpose) do
    Logger.info("🔭 [Reality.Observatory] Patch Proposed: #{proposal_id} | Purpose: #{purpose}")
  end

  def record_build_outcome(proposal_id, true), do: Logger.info("🔭 [Reality.Observatory] Build SUCCEEDED for #{proposal_id}")
  def record_build_outcome(proposal_id, false), do: Logger.warning("🔭 [Reality.Observatory] Build FAILED for #{proposal_id}")

  def record_regression_analysis(proposal_id, result) do
    status = if result == :approve, do: "APPROVED", else: "REJECTED"
    Logger.info("🔭 [Reality.Observatory] Regression Analysis for #{proposal_id}: #{status}")
  end

  def record_deployment_outcome(proposal_id, true) do
    Logger.info("🚀🔭 [Reality.Observatory] SUCCESSFUL DEPLOYMENT: #{proposal_id} merged to mainline.")
  end
  def record_deployment_outcome(proposal_id, false) do
    Logger.info("♻️🔭 [Reality.Observatory] ROLLBACK: #{proposal_id} discarded.")
  end
end
