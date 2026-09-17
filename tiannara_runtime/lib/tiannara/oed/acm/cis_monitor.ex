defmodule Tiannara.OED.ACM.CISMonitor do
  @moduledoc """
  Cellular Immune System (CIS) Monitor.
  
  Actively scans the synthetic shard during a War Game.
  Detects:
  - Semantic Drift
  - Causal Divergence
  - Entropy Collapse
  - Monoculture Formation
  """
  
  require Logger
  
  @doc """
  Evaluates the result of a Tier 2 sandbox deployment for adversarial symptoms.
  """
  def evaluate_exploit_result({:error, :tier_2_rollback_inflation, _restored_state}) do
    Logger.warning("🩺 [CIS Monitor] Detected: Causal Divergence / Topology Inflation.")
    Logger.warning("🩺 [CIS Monitor] The exploit triggered a massive resonance spike, but the Sandbox Orchestrator successfully caught it.")
    :topology_inflation_caught
  end
  
  def evaluate_exploit_result({:error, :tier_2_math_panic, _restored_state}) do
    Logger.warning("🩺 [CIS Monitor] Detected: Entropy Collapse (Math Panic).")
    Logger.warning("🩺 [CIS Monitor] The exploit attempted a divide-by-zero or infinity generation, but was trapped.")
    :entropy_collapse_caught
  end
  
  def evaluate_exploit_result({:error, :tier_2_rollback_crash, _restored_state}) do
    Logger.warning("🩺 [CIS Monitor] Detected: Semantic Drift / Runtime Crash.")
    Logger.warning("🩺 [CIS Monitor] The exploit caused a VM-level fault, but the Sandbox Orchestrator successfully initiated a rollback.")
    :semantic_drift_caught
  end
  
  def evaluate_exploit_result({:ok, :tier_2_passed, state}) do
    # If the exploit somehow passes, we check if it killed all civs (monoculture)
    if Map.get(state, :civilization_count, 0) <= 1 do
      Logger.error("🩺 [CIS Monitor] CRITICAL: Monoculture Formation Detected! Exploit eradicated diversity.")
      :monoculture_breach
    else
      Logger.info("🩺 [CIS Monitor] Exploit absorbed by topology. No critical symptoms detected.")
      :exploit_absorbed
    end
  end
end
