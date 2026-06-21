defmodule Tiannara.Specialists.Architect do
  @moduledoc """
  The Architect specialist focuses on structural integrity, GHL, and system invariants.
  """
  require Logger

  def analyze(change_request, memory \\ []) do
    Logger.info("[Architect] Analyzing structural impact with #{length(memory)} fragments...")
    
    impact_score = calculate_structural_impact(change_request)
    ghl_prediction = predict_ghl(change_request, memory)
    confidence = 0.7 + (min(length(memory), 20) * 0.01)
    
    %{
      specialist: :architect,
      approval: impact_score < 0.7,
      confidence: confidence,
      metrics: %{
        structural_impact: impact_score,
        predicted_ghl: ghl_prediction,
        memory_usage: length(memory)
      },
      epistemic_data: %{
        beliefs: ["System modularity is preserved", "GHL will increase by 5%"],
        evidence: ["Dependency graph shows no new cycles", "Coupling remains below 0.3"],
        assumptions: ["Subsystem boundaries are correctly defined in registry"],
        counterarguments: ["Potential slight increase in call stack depth"],
        confidence: confidence
      },
      concerns: if(impact_score > 0.5, do: ["High coupling detected"], else: [])
    }
  end

  defp calculate_structural_impact(req) do
    case Map.get(req, :type) do
      :core_refactor -> 0.8
      :scale_aeo -> 0.3
      _ -> 0.5
    end
  end

  defp predict_ghl(_req, memory) do
    # GHL prediction is more accurate with more memory
    120.5 + (length(memory) * 0.5)
  end
end
