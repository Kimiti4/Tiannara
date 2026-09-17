defmodule Tiannara.MCAL.CISEvolutionLoop do
  @moduledoc """
  MCAL: Immune-Cognitive Coupling Engine.
  
  MCAL proposes cognition -> CIS evaluates survivability -> MCAL adapts thinking strategy.
  This forms a closed adaptive loop between reasoning and immunity.
  """
  
  require Logger
  
  alias Tiannara.MCAL.{Memory, FrameSelector}
  alias Tiannara.MetaEcology.CrossWorldCIS

  @doc """
  Runs the cognitive abstraction through the immune supervision loop.
  """
  def cycle(cognition, raw_state) do
    Logger.info("🔁 [MCAL-CIS Loop] Submitting cognitive proposal to Immune Evaluation...")
    
    # 1. Immune Evaluation (Mocking CIS response based on cognition entropy)
    immune_signal = evaluate_survivability(cognition, raw_state)
    
    # 2. Adaptation based on CIS Signal
    case immune_signal.decision do
      :accept ->
        Logger.info("✅ [MCAL-CIS Loop] Immune Signal: ACCEPT. Cognition deemed safe.")
        cognition
        
      :modify ->
        Logger.warning("⚠️ [MCAL-CIS Loop] Immune Signal: MODIFY. Cognitive abstraction is unstable.")
        # Trigger an immune adaptation (e.g., damping confidence)
        %{cognition | stability_index: cognition.stability_index * 0.5}
        
      :reject ->
        Logger.error("🚫 [MCAL-CIS Loop] Immune Signal: REJECT. Collapse risk detected. Archiving failure and shifting to safe mode.")
        Memory.archive_failure(cognition, immune_signal.reason)
        # We don't execute a frame transition here directly, but we signal the Kernel to switch
        %{cognition | frame: :safe_mode, entropy_vector: 0.0}
        
      :contain ->
        Logger.error("🦠 [MCAL-CIS Loop] Immune Signal: CONTAIN. Quarantine required.")
        # In a real system, this isolates the specific lineage or shard
        if Map.has_key?(raw_state, :cluster) do
          CrossWorldCIS.scan_cluster_immunity(raw_state.cluster)
        end
        Memory.archive_failure(cognition, immune_signal.reason)
        %{cognition | frame: :quarantine}
    end
  end
  
  defp evaluate_survivability(cognition, _raw_state) do
    # Immune check logic
    cond do
      cognition.entropy_vector > 0.9 ->
        %{decision: :reject, reason: "Entropy exceeds critical collapse threshold"}
      cognition.entropy_vector > 0.7 ->
        %{decision: :contain, reason: "High monoculture risk detected"}
      cognition.entropy_vector > 0.5 ->
        %{decision: :modify, reason: "Stability risk detected"}
      true ->
        %{decision: :accept, reason: "Safe"}
    end
  end
end
