defmodule Tiannara.ASC.SelfModel.SystemicRiskScanner do
  @moduledoc """
  Phase 17: Analyzes the Civilizational Self-Model for macro-level vulnerabilities.
  Detects Single Points of Failure, Lineage Monocultures, Cognitive Overload, and Dependency Cascades.
  """
  alias Tiannara.ASC.SelfModel.CivilizationGraph
  alias Tiannara.ASC.Immunity.EpistemicThreat
  require Logger

  def scan_macro_risks(%CivilizationGraph{} = model) do
    Logger.info("🔭 [SystemicRisk] Analyzing civilizational anatomy for macro-vulnerabilities...")
    
    [
      check_utility_concentration(model),
      check_lineage_monoculture(model),
      check_cognitive_overload(model),
      check_dependency_cascade(model),
      check_epistemic_blindspots(model)
    ]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  # Risk 1: Single Point of Failure (Utility Concentration)
  # If one capability provides > 70% of the civilization's utility, the host is fragile.
  defp check_utility_concentration(model) do
    {dominant_cap_id, concentration} = 
      Enum.max_by(model.utility_flows, fn {_id, pct} -> pct end, fn -> {nil, 0.0} end)
    
    if concentration > 0.70 do
      %EpistemicThreat{
        type: :utility_concentration,
        severity: :malignant,
        source_id: dominant_cap_id,
        source_type: :macro_anatomy,
        evidence: "Single Point of Failure: Capability #{dominant_cap_id} provides #{Float.round(concentration * 100, 1)}% of total civilizational utility.",
        detected_at: System.system_time(:millisecond)
      }
    else
      nil
    end
  end

  # Risk 2: Lineage Monoculture
  # If > 80% of active capabilities are LLM-synthesized, the civilization lacks human-anchored bedrock.
  defp check_lineage_monoculture(model) do
    llm_count = Enum.count(model.capabilities, & &1.lineage == :llm_synthesis)
    total_count = length(model.capabilities)
    
    ratio = if total_count > 0, do: llm_count / total_count, else: 0.0
    
    if ratio > 0.80 and total_count > 5 do
      %EpistemicThreat{
        type: :lineage_monoculture,
        severity: :malignant,
        source_id: :capability_ecology,
        source_type: :macro_anatomy,
        evidence: "Lineage Monoculture: #{Float.round(ratio * 100, 1)}% of capabilities are LLM-synthesized. Lack of human-seeded bedrock.",
        detected_at: System.system_time(:millisecond)
      }
    else
      nil
    end
  end

  # Risk 3: Cognitive Overload
  defp check_cognitive_overload(model) do
    if model.cognitive_load > 0.90 do
      %EpistemicThreat{
        type: :cognitive_overload,
        severity: :terminal,
        source_id: :capability_ecology,
        source_type: :macro_anatomy,
        evidence: "Cognitive Overload: Context window saturation at #{Float.round(model.cognitive_load * 100, 1)}%.",
        detected_at: System.system_time(:millisecond)
      }
    else
      nil
    end
  end
  
  # Risk 4: Dependency Cascade Risk (Betweenness Centrality)
  defp check_dependency_cascade(model) do
    # Find capabilities with extremely high betweenness centrality
    critical_nodes = Enum.filter(model.capabilities, fn cap -> Map.get(cap, :betweenness_centrality, 0.0) > 0.75 end)
    
    Enum.map(critical_nodes, fn cap ->
      %EpistemicThreat{
        type: :dependency_cascade_risk,
        severity: :malignant,
        source_id: cap.id,
        source_type: :macro_anatomy,
        evidence: "Dependency Cascade Risk: Capability #{cap.id} has a Betweenness Centrality of #{Map.get(cap, :betweenness_centrality)}. Failure will sever mission pipelines.",
        detected_at: System.system_time(:millisecond)
      }
    end)
  end

  defp check_epistemic_blindspots(_model), do: nil # Placeholder for domain-coverage analysis
end
