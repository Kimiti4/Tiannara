defmodule Tiannara.ASC.Immunity.ImmuneSystem do
  @moduledoc """
  Phase 16 & 17: The Epistemic Immune System.
  Coordinates pathogen scanning, auto-immune regulation, and graduated quarantine protocols.
  Now incorporates Phase 17 Systemic Risk Scanning and Graduated Response.
  """
  alias Tiannara.ASC.Immunity.{PathogenScanner, AutoImmuneRegulator, EpistemicThreat, GraduatedResponseProtocol}
  alias Tiannara.ASC.SelfModel.{CivilizationGraph, SystemicRiskScanner}
  alias Tiannara.ASC.Memory.InstitutionalMemory
  alias Tiannara.ASC.Research.ResearchRegistry
  alias Tiannara.ASC.Ecology.CapabilityRegistry
  require Logger

  def run_immune_cycle do
    # Phase 16: Local Pathogen Scan
    local_threats = PathogenScanner.scan_all()
    
    # Phase 17: Macro-level Systemic Risk Scan
    mirror = CivilizationGraph.build_mirror()
    macro_threats = SystemicRiskScanner.scan_macro_risks(mirror)
    
    all_threats = local_threats ++ macro_threats
    
    if Enum.empty?(all_threats) do
      Logger.info("✅ [ImmuneSystem] Civilization is epistemically healthy. No pathogens detected.")
    else
      Logger.warning("🚨 [ImmuneSystem] Detected #{length(all_threats)} epistemic/macro threats. Initiating immune response...")
      Enum.each(all_threats, &respond_to_threat/1)
    end
  end

  defp respond_to_threat(%EpistemicThreat{source_type: :macro_anatomy} = threat) do
    # Macro threats go through Phase 17 Graduated Response Protocol
    # We pass a mocked historical context
    response = GraduatedResponseProtocol.prescribe_response(threat, %{previous_warnings: 0})
    GraduatedResponseProtocol.execute_response(response, threat)
  end

  defp respond_to_threat(%EpistemicThreat{} = threat) do
    # Local threats go through Phase 16 AutoImmuneRegulator (for backward compatibility during rollout)
    case AutoImmuneRegulator.evaluate_threat(threat) do
      {:observe, reason} ->
        Logger.info("🛡️ [ImmuneSystem] LEVEL 1 (OBSERVE) #{threat.type} in #{threat.source_type} '#{threat.source_id}'. Reason: #{reason}")
        
      {:flag, reason} ->
        Logger.warning("🛡️ [ImmuneSystem] LEVEL 2 (FLAG) #{threat.type} in #{threat.source_type} '#{threat.source_id}'. Reason: #{reason}")
        
      {:restrict, reason} ->
        Logger.warning("⚔️ [ImmuneSystem] LEVEL 3 (RESTRICT) #{threat.type} in #{threat.source_type} '#{threat.source_id}'. Reason: #{reason}")
        execute_quarantine(:restrict, threat)
        
      {:quarantine, reason} ->
        Logger.error("⚔️ [ImmuneSystem] LEVEL 4 (QUARANTINE) #{threat.type} in #{threat.source_type} '#{threat.source_id}'. Reason: #{reason}")
        execute_quarantine(:quarantine, threat)
        
      {:extinction, reason} ->
        Logger.critical("💀 [ImmuneSystem] LEVEL 5 (EXTINCTION) #{threat.type} in #{threat.source_type} '#{threat.source_id}'. Reason: #{reason}")
        execute_quarantine(:extirpate, threat)
    end
  end

  defp execute_quarantine(:quarantine, %EpistemicThreat{type: :institutional_memory_corruption, source_id: adr_id}) do
    Logger.warning("   🦴 [Quarantine] Flagging ADR #{adr_id} as CORRUPTED. Forcing RealityBridge re-scan.")
    InstitutionalMemory.flag_as_corrupted(adr_id)
  end

  defp execute_quarantine(:quarantine, %EpistemicThreat{type: :epistemic_closure, source_id: prog_id}) do
    Logger.warning("   🧊 [Quarantine] FREEZING Research Program #{prog_id}. Budget set to 0. Echo chamber isolated.")
    ResearchRegistry.freeze_program(prog_id)
  end

  defp execute_quarantine(:quarantine, %EpistemicThreat{type: :runaway_proliferation}) do
    Logger.critical("   🛑 [Quarantine] HALTING LLM Gateway. Runaway proliferation detected. Forcing Darwinian Cull.")
    # Simulated halt
  end
  
  defp execute_quarantine(:restrict, %EpistemicThreat{type: :canonical_ossification, source_id: law_id}) do
    Logger.warning("   🧪 [Restrict] Forcing falsification budget on Law '#{law_id}'.")
  end
  
  defp execute_quarantine(:extirpate, %EpistemicThreat{type: :reward_hacking, source_id: cap_id}) do
    Logger.critical("   💀 [Extirpate] Culling capability '#{cap_id}' immediately due to reward hacking.")
    CapabilityRegistry.archive_capability(cap_id)
    InstitutionalMemory.record_rejected_hypothesis(cap_id, "Extirpation triggered by Immune System: Reward Hacking detected.")
  end

  defp execute_quarantine(level, threat) do
    Logger.info("   ⚠️ [Protocol] No specific #{level} protocol implemented for #{threat.type} yet.")
  end
end
