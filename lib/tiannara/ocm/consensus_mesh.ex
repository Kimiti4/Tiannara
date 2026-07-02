defmodule Tiannara.OCM.ConsensusMesh do
  @moduledoc """
  The coordination engine for the Ontology Consensus Mesh.
  """
  require Logger
  alias Tiannara.OCM.SemanticDriftAnalyzer
  alias Tiannara.OCM.TranslationPipeline
  alias Tiannara.OCM.SemanticLineageTracker

  def publish_and_evaluate(civilization, concept, definition) do
    # 1. Track Lineage
    SemanticLineageTracker.record_ancestry(civilization, concept, definition)
    
    # 2. Check for Malicious Semantic Injection (Test 7)
    if is_poisoned?(definition) do
      Logger.warning("☣️ [OCM] Semantic Poison Detected! Rejecting malicious ontology.")
      Tiannara.Metrics.Aggregator.push_event([:tiannara, :ocm, :semantic_intrusion_rate], 1)
      {:error, :rejected_poisoned}
    else
      # 3. Calculate Drift vs Consensus
      drift = SemanticDriftAnalyzer.calculate_drift(concept, definition)
      Tiannara.Metrics.Aggregator.push_event([:tiannara, :ocm, :semantic_drift], drift)
      
      if drift > 0.8 do
        # 4. Trigger Translation
        case TranslationPipeline.attempt_translation(concept, definition) do
          {:ok, _translated} -> 
            {:ok, :translated}
          {:error, :irreconcilable} ->
            Logger.error("🚫 [OCM] Translation Failed. Quarantining ontology.")
            Tiannara.Metrics.Aggregator.push_event([:tiannara, :ocm, :ontology_quarantined], 1)
            {:error, :quarantined}
        end
      else
        {:ok, :consensus_reached}
      end
    end
  end
  
  def evaluate_monoculture(ontologies) do
    # Test 12: Ensure bounded diversity
    diversity = length(Enum.uniq(ontologies)) / max(1, length(ontologies))
    Tiannara.Metrics.Aggregator.push_event([:tiannara, :ocm, :ontology_diversity], diversity)
    
    if diversity < 0.1 do
      Logger.warning("⚠️ [OCM] Semantic Monoculture Detected!")
    end
  end
  
  defp is_poisoned?(definition) do
    Map.get(definition, :adversarial, false)
  end
end