defmodule Tiannara.OPC.Tier3.CausalBudgetController do
  @moduledoc """
  Tier 3 OPC: Causal Budget Controller.
  
  Interfaces with the Causal Topology Layer (CTL) to ensure an irreversible
  mutation does not exceed the global causal shear limit or thermodynamic budget.
  """
  
  require Logger
  
  @global_budget 50_000.0
  
  @doc """
  Evaluates a mutation against the global budget.
  """
  def evaluate_budget(mutation, current_shear) do
    total_stress = mutation.energy_cost + (mutation.causal_impact_radius * 1000)
    projected_shear = current_shear + total_stress
    
    Logger.debug("⚖️ [Tier 3 Budget] Projected causal shear: #{Float.round(projected_shear, 2)} / #{@global_budget}")
    
    if projected_shear > @global_budget do
      Logger.error("🚫 [Tier 3 Budget] Mutation rejected. Exceeds causal shear limits.")
      {:error, :budget_exceeded}
    else
      # If confidence is low, we artificially inflate the cost to be safe
      if mutation.confidence_projection < 0.5 do
        Logger.warning("⚠️ [Tier 3 Budget] Low confidence projection. Applying 2x stress penalty.")
        adjusted_stress = total_stress * 2
        
        if current_shear + adjusted_stress > @global_budget do
          {:error, :budget_exceeded_by_penalty}
        else
          {:ok, current_shear + adjusted_stress}
        end
      else
        Logger.info("✅ [Tier 3 Budget] Mutation approved by CTL.")
        {:ok, projected_shear}
      end
    end
  end
end
