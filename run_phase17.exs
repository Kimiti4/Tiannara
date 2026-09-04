defmodule Tiannara.ASC.Immunity.Phase17Campaign do
  @moduledoc """
  Phase 17 Demonstration: Civilizational Self-Modeling & Proprioception.
  Constructs the Epistemic Mirror and demonstrates the Graduated Response Protocol
  handling a Single Point of Failure and a Dependency Cascade.
  """
  alias Tiannara.ASC.Immunity.ImmuneSystem
  alias Tiannara.ASC.SelfModel.CivilizationGraph
  alias Tiannara.ASC.SelfModel.SystemicRiskScanner
  require Logger

  def run do
    Logger.info("🪞 [Phase 17] Initiating Civilizational Self-Modeling Campaign")
    
    # Start Registries
    Tiannara.ASC.Ecology.CapabilityRegistry.start_link([])

    # We skip seeding the local pathogens from Phase 16 to focus on Phase 17's output.
    # We will invoke the mirror directly first to show its anatomy mapping.
    
    mirror = CivilizationGraph.build_mirror()
    Logger.info("📊 [SelfModel] Mapped #{length(mirror.capabilities)} capabilities, #{length(mirror.laws)} laws, #{length(mirror.programs)} research programs.")
    Logger.info("📊 [SelfModel] Cognitive Load: #{Float.round(mirror.cognitive_load * 100, 1)}%")

    Logger.info("\n--- EXECUTING PHASE 17 IMMUNE CYCLE (MACRO-SCAN ONLY) ---")
    
    # We run the SystemicRiskScanner directly to avoid the noise of Phase 16 local pathogens in this demo.
    macro_threats = SystemicRiskScanner.scan_macro_risks(mirror)
    
    if Enum.empty?(macro_threats) do
      Logger.info("✅ [SystemicRisk] No macro-level vulnerabilities detected.")
    else
      Logger.warning("🚨 [ImmuneSystem] Detected #{length(macro_threats)} macro-level threats. Initiating graduated response...")
      
      Enum.each(macro_threats, fn threat ->
        response = Tiannara.ASC.Immunity.GraduatedResponseProtocol.prescribe_response(threat, %{previous_warnings: 0})
        Tiannara.ASC.Immunity.GraduatedResponseProtocol.execute_response(response, threat)
      end)
    end
    
    Logger.info("\n🏆 [Phase 17] Self-Modeling Campaign Complete. Anaphylactic shock prevented.")
  end
end

Tiannara.ASC.Immunity.Phase17Campaign.run()
