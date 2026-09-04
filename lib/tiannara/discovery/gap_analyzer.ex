defmodule Tiannara.Discovery.GapAnalyzer do
  alias Tiannara.Discovery.Domain.KnowledgeGap

  def analyze(report) when is_map(report) do
    []
    |> analyze_contradiction_rate(report)
    |> analyze_evidence_quality(report)
    |> analyze_stale_theories(report)
    |> analyze_provenance_completeness(report)
    |> analyze_experiment_recommendations(report)
  end

  def rank(gaps) when is_list(gaps) do
    Enum.sort_by(gaps, fn gap -> severity_weight(gap.severity) * gap.estimated_impact end, :desc)
  end

  defp severity_weight(:critical), do: 4.0
  defp severity_weight(:high), do: 3.0
  defp severity_weight(:medium), do: 2.0
  defp severity_weight(:low), do: 1.0

  defp analyze_contradiction_rate(gaps, report) do
    rate = Map.get(report, :contradiction_rate, 0.0)
    if rate > 0.05 do
      severity = cond do
        rate > 0.3 -> :critical; rate > 0.15 -> :high; rate > 0.05 -> :medium; true -> :low
      end
      [KnowledgeGap.new(%{domain: :epistemic_consistency,
        description: "Contradiction rate #{Float.round(rate, 3)} exceeds threshold (0.05)",
        severity: severity, uncertainty: min(1.0, rate * 2), estimated_impact: min(1.0, rate * 3),
        recommended_investigation: :resolve_contradictions, source: :epistemic_integrity,
        evidence: [%{type: :contradiction_rate, value: rate}]}) | gaps]
    else gaps end
  end

  defp analyze_evidence_quality(gaps, report) do
    quality = Map.get(report, :evidence_quality, 1.0)
    if quality < 0.7 do
      severity = if quality < 0.3, do: :critical, else: (if quality < 0.5, do: :high, else: :medium)
      [KnowledgeGap.new(%{domain: :evidence_quality,
        description: "Evidence quality #{Float.round(quality, 3)} below threshold (0.7)",
        severity: severity, uncertainty: 1.0 - quality, estimated_impact: (1.0 - quality) * 0.8,
        recommended_investigation: :strengthen_evidence, source: :epistemic_integrity,
        evidence: [%{type: :evidence_quality, value: quality}]}) | gaps]
    else gaps end
  end

  defp analyze_stale_theories(gaps, report) do
    stale_rate = Map.get(report, :stale_theory_rate, 0.0)
    if stale_rate > 0.2 do
      [KnowledgeGap.new(%{domain: :knowledge_freshness,
        description: "Stale theory rate #{Float.round(stale_rate, 3)} exceeds threshold (0.2)",
        severity: if(stale_rate > 0.5, do: :high, else: :medium), uncertainty: stale_rate,
        estimated_impact: stale_rate * 0.6, recommended_investigation: :refresh_stale_theories,
        source: :stale_theory, evidence: [%{type: :stale_theory_rate, value: stale_rate}]}) | gaps]
    else gaps end
  end

  defp analyze_provenance_completeness(gaps, report) do
    completeness = Map.get(report, :provenance_completeness, 1.0)
    if completeness < 0.9 do
      [KnowledgeGap.new(%{domain: :provenance,
        description: "Provenance completeness #{Float.round(completeness, 3)} below threshold (0.9)",
        severity: if(completeness < 0.5, do: :high, else: :medium), uncertainty: 1.0 - completeness,
        estimated_impact: (1.0 - completeness) * 0.5, recommended_investigation: :audit_provenance,
        source: :epistemic_integrity, evidence: [%{type: :provenance_completeness, value: completeness}]}) | gaps]
    else gaps end
  end

  defp analyze_experiment_recommendations(gaps, report) do
    Enum.reduce(Map.get(report, :experiment_recommendations, []), gaps, fn rec, acc ->
      [KnowledgeGap.new(%{domain: Map.get(rec, :domain, :general),
        description: Map.get(rec, :reason, "Experiment recommended"),
        severity: Map.get(rec, :severity, :medium), uncertainty: 0.5,
        estimated_impact: Map.get(rec, :estimated_impact, 0.5),
        recommended_investigation: Map.get(rec, :type, :general_inquiry),
        source: :epistemic_integrity,
        evidence: [%{type: :experiment_recommendation, recommendation: rec}]}) | acc]
    end)
  end
end
