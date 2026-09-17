defmodule Tiannara.MCAL.CognitionRouter do
  @moduledoc """
  MCAL: Cognition Router.
  
  The final decision point of MCAL. Takes the meta-reasoning state and determines
  whether to trigger AEO (Execution), CIS (Immune Stabilization), or reframe cognition.
  This couples the cognitive layer directly to the ecology immune system.
  """
  
  require Logger
  
  # For integration with Tier 3 / Meta Ecology
  alias Tiannara.MetaEcology.CrossWorldCIS

  @doc """
  Routes the cognitive mandate based on the meta-reasoner's findings.
  This integrates MCAL into the OPC/HSV/CTL stack.
  """
  def route(meta_state, raw_state \\ %{}) do
    Logger.debug("🔀 [MCAL Router] Analyzing cognitive routing pathways for OPC/CTL/HSV stack...")
    
    cond do
      meta_state.pattern_recognition.critical ->
        Logger.error("🔀 [MCAL Router] CRITICAL PATTERN. Routing causal hypothesis to CTL (Causal Validator).")
        # MCAL -> CTL
        :send_to_ctl_validation

      meta_state.uncertainty_map.global > 0.85 ->
        Logger.warning("🔀 [MCAL Router] HIGH ABSTRACTION PRESSURE. Routing to HSV for Collapse Control.")
        # MCAL -> HSV
        :send_to_hsv_evaluation

      meta_state.uncertainty_map.high ->
        Logger.warning("🔀 [MCAL Router] HIGH UNCERTAINTY. Routing cognitive mandate to CIS for stabilization.")
        if Map.has_key?(raw_state, :cluster) do
          CrossWorldCIS.scan_cluster_immunity(raw_state.cluster)
        end
        :send_to_cis_stabilization

      meta_state.recommended_frame_shift != nil ->
        Logger.info("🔀 [MCAL Router] Reframing required. Shifting paradigm to: #{meta_state.recommended_frame_shift}")
        :reframe_and_reprocess

      true ->
        Logger.info("🔀 [MCAL Router] Cognition loop stable. Proposing interpreted physics to OPC.")
        # MCAL -> OPC
        :send_to_opc_compilation
    end
  end
end
