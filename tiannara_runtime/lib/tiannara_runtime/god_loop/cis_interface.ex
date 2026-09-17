defmodule Tiannara.GodLoop.CISInterface do
  @moduledoc """
  God-Loop: CIS Interface.
  
  Bridge allowing MCAL/OPC to force CIS to adjust immune pressure.
  Prevents Immune Tyranny.
  """
  
  require Logger

  @doc """
  Mutates CIS immune constraints based on pressure gradients and physics state.
  """
  def self_adjust(cis_state, opc_state, gradients) do
    Logger.debug("🦠 [God-Loop CIS Interface] Evaluating rewrite triggers for immune constraints...")
    
    new_state = cond do
      gradients.stability >= 0.8 ->
        Logger.error("🦠 [God-Loop CIS Interface] REWRITE TRIGGERED: Immune Tyranny detected (System too rigid). Relaxing immune bounds to allow survival novelty.")
        Map.put(cis_state, :rigidity, 0.2)
        
      Map.get(opc_state, :paradox_density, 0.0) >= 0.9 ->
        Logger.warning("🦠 [God-Loop CIS Interface] REWRITE TRIGGERED: Paradox density critical. Tightening immune constraints.")
        Map.put(cis_state, :rigidity, 0.9)
        
      true ->
        # Natural immune relaxation
        rig = Map.get(cis_state, :rigidity, 0.5)
        Map.put(cis_state, :rigidity, min(0.8, rig * 1.1))
    end
    
    new_state
  end
end
