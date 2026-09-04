defmodule Tiannara.ASC.Immunity.GraduatedResponseProtocol do
  @moduledoc """
  Phase 17: The biological safeguard against auto-immune collapse.
  Replaces immediate extinction with a graduated, reversible response pipeline.
  """
  alias Tiannara.ASC.Immunity.EpistemicThreat
  require Logger

  @doc """
  Determines the appropriate biological response to an epistemic threat.
  """
  def prescribe_response(%EpistemicThreat{} = threat, historical_context) do
    cond do
      # 1. Terminal threats to physical reality or context limits require immediate amputation
      threat.severity == :terminal or threat.type == :cognitive_overload ->
        {:extirpate, "Terminal threat to host survival. Immediate safe removal required."}
        
      # 2. Malignant threats (Echo chambers, Reality drift) require isolation
      threat.severity == :malignant and threat.source_type != :macro_anatomy ->
        {:quarantine, "Malignant anomaly. Isolate from main pipeline and freeze budget."}
        
      # 3. Repeated offenses (The system has tolerated this before, but it persists)
      historical_context.previous_warnings >= 3 ->
        {:restrict, "Persistent anomaly. Throttling compute/tokens by 50%."}
        
      # 4. Novel or macro-level anomalies require observation, not action
      true ->
        {:observe, "Novel or macro-level anomaly. Increasing telemetry sampling rate."}
    end
  end

  def execute_response({:observe, reason}, threat) do
    Logger.info("👁️ [ImmuneResponse] OBSERVE: #{threat.type} in #{threat.source_type} '#{threat.source_id}'. Reason: #{reason}")
    # Increase logging/debugging for this specific asset
  end

  def execute_response({:restrict, reason}, threat) do
    Logger.warning("🚧 [ImmuneResponse] RESTRICT: #{threat.type} in #{threat.source_type} '#{threat.source_id}'. Reason: #{reason}")
    # Throttle the LLM Gateway token budget for this specific capability/program
  end

  def execute_response({:quarantine, reason}, threat) do
    Logger.error("🧊 [ImmuneResponse] QUARANTINE: #{threat.type} in #{threat.source_type} '#{threat.source_id}'. Reason: #{reason}")
    # Remove from Dynamic Orchestrator pipeline, freeze Research Program budget
  end

  def execute_response({:extirpate, reason}, threat) do
    Logger.critical("✂️ [ImmuneResponse] EXTIRPATE: #{threat.type} in #{threat.source_type} '#{threat.source_id}'. Reason: #{reason}")
    # Safely remove from ETS, write to Fossil Record, trigger garbage collection
    # Note: Extinction is a governance decision that happens after extirpation
  end
end
