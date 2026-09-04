defmodule Tiannara.ASC.Evolution.CapabilitySynthesizer do
  @moduledoc """
  Phase 13: Unprompted Capability Creation.
  Analyzes deep civilizational friction and invents new cognitive tools 
  or agent roles that humans never explicitly specified.
  """
  alias Tiannara.ASC.Ecology.{Capability, CapabilityRegistry}
  require Logger

  def analyze_and_invent(friction_telemetry) do
    Logger.info("🧠 [Synthesizer] Analyzing deep systemic friction for unprompted invention...")
    
    bottleneck = diagnose_deep_bottleneck(friction_telemetry)
    
    case bottleneck do
      :historical_regression ->
        invent_capability(%Capability{
          id: "cap_archaeologist",
          name: "Technical Debt Archaeologist",
          type: :agent_role,
          trigger_condition: %{mission_age: :legacy},
          implementation: &simulate_archaeologist/1,
          lineage: :unprompted_synthesis
        })
        
      :unforeseen_downstream_impact ->
        invent_capability(%Capability{
          id: "cap_risk_sim",
          name: "Deployment Risk Simulator",
          type: :cognitive_tool,
          trigger_condition: %{patch_scope: :cross_boundary},
          implementation: &simulate_risk_tool/1,
          lineage: :unprompted_synthesis
        })
        
      :none ->
        Logger.info("✅ [Synthesizer] No novel capabilities required at this epoch.")
    end
  end

  defp invent_capability(%Capability{} = cap) do
    Logger.info("""
    💡 [Synthesizer] UNPROMPTED INVENTION: #{cap.name}
       Type: #{cap.type}
       Lineage: #{cap.lineage}
       Reason: Detected systemic friction that existing roles cannot resolve.
    """)
    CapabilityRegistry.register(cap)
  end
  
  defp diagnose_deep_bottleneck(telemetry) do
    # Simulated deep analysis of mission failures
    cond do
      telemetry.legacy_codebase_failures > 0.4 -> :historical_regression
      telemetry.cross_domain_regressions > 0.3 -> :unforeseen_downstream_impact
      true -> :none
    end
  end

  # Simulated implementations of unprompted inventions
  def simulate_archaeologist(task) do
    Logger.info("      🏺 [Archaeologist] Excavating ADRs and legacy debt to inform Coder...")
    Map.put(task, :context_enriched, true)
  end

  def simulate_risk_tool(task) do
    Logger.info("      📉 [Risk Simulator] Simulating downstream blast radius of patch...")
    Map.put(task, :risk_mitigated, true)
  end
end
