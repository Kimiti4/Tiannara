defmodule Tiannara.ASC.Laws.GovernanceReportCampaign do
  @moduledoc """
  Phase 5I: Generates a comprehensive governance report showing the full
  lifecycle of all laws, from candidate to canonical (or refuted).
  """
  
  alias Tiannara.ASC.Laws.{Registry, CanonicalPromotionEngine}
  alias Tiannara.ASC.Runtime
  require Logger

  def run do
    Logger.info("📜 [Phase 5I] Initiating Canonical Governance Report")
    :ok = Runtime.bootstrap()
    
    # Run the governance evaluation
    CanonicalPromotionEngine.evaluate_governance()
    
    # Generate the report
    generate_governance_report()
  end

  defp generate_governance_report do
    canonical = Registry.get_laws_by_status(:canonical_principle)
    established = Registry.get_laws_by_status(:established_law)
    candidate = Registry.candidates()
    refuted = Registry.get_laws_by_status(:refuted)
    
    audit_log = Registry.get_governance_audit_log()
    
    Logger.info("""
    ======================================================================
    📜 PHASE 5I: CANONICAL GOVERNANCE REPORT
    ======================================================================
    
    👑 CANONICAL PRINCIPLES (#{length(canonical)})
    ----------------------------------------------------------------------
    """)
    
    Enum.each(canonical, fn law ->
      Logger.info("  #{law.statement}")
      Logger.info("    Confidence: #{Float.round(law.confidence, 3)} | Utility: #{Float.round(law.utility_score, 2)}")
      Logger.info("    Survived: #{law.campaigns_survived}/#{law.campaigns_tested} campaigns")
    end)
    
    Logger.info("""
    
    🏛️ ESTABLISHED LAWS (#{length(established)})
    ----------------------------------------------------------------------
    """)
    
    Enum.each(established, fn law ->
      Logger.info("  #{law.statement}")
      Logger.info("    Confidence: #{Float.round(law.confidence, 3)} | Utility: #{Float.round(law.utility_score, 2)}")
      Logger.info("    Survived: #{law.campaigns_survived}/#{law.campaigns_tested} campaigns")
    end)
    
    Logger.info("""
    
    🧪 CANDIDATE LAWS (#{length(candidate)})
    ----------------------------------------------------------------------
    """)
    
    Enum.each(candidate, fn law ->
      Logger.info("  #{law.statement}")
      Logger.info("    Confidence: #{Float.round(law.confidence, 3)} | Utility: #{Float.round(law.utility_score, 2)}")
    end)
    
    Logger.info("""
    
    ❌ REFUTED LAWS (#{length(refuted)})
    ----------------------------------------------------------------------
    """)
    
    Enum.each(refuted, fn law ->
      Logger.info("  #{law.statement}")
      Logger.info("    Failed: #{law.contradiction_count} contradictions | Utility: #{Float.round(law.utility_score, 2)}")
    end)
    
    Logger.info("""
    
    📋 GOVERNANCE AUDIT LOG (Last 10 Events)
    ----------------------------------------------------------------------
    """)
    
    audit_log
    |> Enum.take(10)
    |> Enum.each(fn event ->
      Logger.info("  [#{event.reason}] #{event.statement}")
      Logger.info("    #{event.previous_status} → #{event.new_status}")
    end)
    
    Logger.info("""
    ======================================================================
    """)
  end
end
