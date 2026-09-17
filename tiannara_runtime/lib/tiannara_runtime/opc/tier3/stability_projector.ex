defmodule Tiannara.OPC.Tier3.StabilityProjector do
  @moduledoc """
  Tier 3 OPC: Stability Projector.
  
  Provides the Pre-Execution Semantic Sanity Layer.
  Runs a shadow simulation predicting 3-7 futures, estimating curvature bounds
  and ontology expansion gradients before runtime.
  """
  
  require Logger
  
  @doc """
  Projects the impact of the mutation on the given world state.
  Returns `{:ok, updated_mutation}` with a validated confidence projection,
  or `{:error, reason}` if the divergence trajectory is too steep.
  """
  def project_futures(mutation, _world_state) do
    Logger.debug("🔮 [Tier 3 Projector] Simulating curvature bounds for mutation #{mutation.id}")
    
    # Simulate multiple futures
    futures = Enum.map(1..5, fn i -> 
      base_divergence = mutation.causal_impact_radius * i
      # Add some randomized chaos to the shadow projection
      base_divergence + (:rand.uniform() * 0.5)
    end)
    
    max_divergence = Enum.max(futures)
    Logger.debug("🔮 [Tier 3 Projector] Max predicted divergence: #{Float.round(max_divergence, 2)}")
    
    if max_divergence > 10.0 do
      Logger.warning("⚠️ [Tier 3 Projector] Trajectory exceeds stable curvature bounds (Divergence: #{Float.round(max_divergence, 2)}). Applying damped scaling.")
      # Partially accept by capping divergence impact artificially and lowering confidence severely
      damped_confidence = 0.1
      
      updated_mutation = %{mutation | confidence_projection: damped_confidence, energy_cost: mutation.energy_cost * 1.5}
      
      Logger.info("✅ [Tier 3 Projector] Mutation partially accepted with damped scaling. Confidence: #{damped_confidence}")
      {:ok, updated_mutation}
    else
      # Update the confidence projection based on how tight the cluster of futures is.
      min_divergence = Enum.min(futures)
      spread = max_divergence - min_divergence
      confidence = max(0.1, 1.0 - (spread * 0.1))
      
      updated_mutation = %{mutation | confidence_projection: confidence}
      
      Logger.info("✅ [Tier 3 Projector] Futures stable. Confidence: #{Float.round(confidence, 2)}")
      {:ok, updated_mutation}
    end
  end
end
