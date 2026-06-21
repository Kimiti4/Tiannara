defmodule Tiannara.REA.BroadwayEpistemicPipeline do
  use Broadway
  require Logger

  @doc """
  Broadway batch processor that validates immune interventions via the ESG.
  """
  def handle_batch(:immune_response, messages, _context) do
    Enum.each(messages, fn msg ->
      batched_telemetry = msg.data
      
      # 1. Identify anomalies and propose a batched cure
      anomalies = Tiannara.Meta.Sentinel.ReflexivityObservatory.scan_batch(batched_telemetry)
      proposed_cure = Tiannara.REA.LivingAntibody.propose_batch_strategy(anomalies)
      
      # 2. THE ESG HANDSHAKE: Test the cure in a zero-cost shadow fork
      target_world = hd(anomalies).world_id
      
      {decision, confidence} = Tiannara.Sentinel.EpistemicShadowGraph.validate_intervention(
        target_world, 
        proposed_cure, 
        batched_telemetry
      )
      
      # 3. Decision Gate
      case decision do
        :approved ->
          Logger.info("✅ [BROADWAY+ESG] Batch intervention approved (Confidence: #{confidence}). Committing to live substrate.")
          Tiannara.REA.LivingAntibody.execute_live_strike(proposed_cure)
          
        :rejected ->
          Logger.error("⚠️ [BROADWAY+ESG] Batch intervention rejected (Confidence: #{confidence}). Autoimmune risk detected.")
          Tiannara.Bridge.SingularityVent.trigger_quarantine(target_world)
      end
    end)
    
    messages
  end
end
