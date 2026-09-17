defmodule Tiannara.OPC.ConstitutionGateway do
  @moduledoc """
  Stage 3: OPC Constitution Gateway
  
  Subjects the strictly declarative PIS payload to the L0 Substrate Constitution.
  Any PIS that violates conservation or demands unacceptable stabilization
  costs is blocked here, BEFORE it is ever compiled into an AST.
  """
  
  require Logger
  alias Tiannara.Constitution.Kernel, as: ConstitutionKernel
  
  @doc """
  Runs the parsed PIS through the Constitution Kernel.
  """
  def validate_intent(pis_map) do
    Logger.debug("[OPC] Submitting PIS #{pis_map["intent_id"]} to Constitution Kernel...")
    
    # Check 1: Must be reversible
    if not pis_map["reversible"] do
      Logger.error("[OPC] Constitution Violation: Intent is not reversible.")
      {:error, :constitution_reversibility_violation}
    else
      # Check 2: Must be conservation enabled
      if not pis_map["conservation_enabled"] do
        Logger.error("[OPC] Constitution Violation: Intent disables topological conservation.")
        {:error, :constitution_conservation_violation}
      else
        # Check 3: Extract URCL topology constraints and run soft-check
        # If topology pressure is "extreme", Kernel might reject it outright
        # depending on the current global stabilization budget.
        profile = pis_map["resource_profile"]
        if profile["topology_pressure"] == "extreme" or profile["stabilization_cost"] == "high" do
          # We call into the Kernel to see if we have budget.
          # (For now, simulated. In reality, we'd check Kernel.get_available_budget())
          Logger.warning("[OPC] Constitution Warning: High topological pressure requested. Budget verification required.")
          
          # Proceeding for Stage 3, but this is the boundary where the Kernel can hard-deny.
          {:ok, pis_map}
        else
          {:ok, pis_map}
        end
      end
    end
  end
end
