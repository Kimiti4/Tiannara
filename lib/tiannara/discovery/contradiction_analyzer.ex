defmodule Tiannara.Discovery.ContradictionAnalyzer do
  def analyze(contradictions) when is_list(contradictions) do
    contradictions
    |> Enum.map(&classify_contradiction/1)
    |> rank()
  end

  def analyze(%{contradictions: contradictions} = report) when is_list(contradictions) do
    classified = Enum.map(contradictions, &classify_contradiction/1)
    ranked = rank(classified)
    %{report | contradictions: ranked, contradictions_classified: true, analysis_complete: true}
  end

  def rank(contradictions) when is_list(contradictions) do
    Enum.sort_by(contradictions, fn c -> Map.get(c, :impact, 0.0) end, :desc)
  end

  defp classify_contradiction(contradiction) do
    ctype = detect_type(contradiction)
    impact = estimate_impact(ctype, contradiction)
    Map.merge(contradiction, %{classification: ctype, impact: impact, classified_at: DateTime.utc_now()})
  end

  defp detect_type(%{type: type}), do: type
  defp detect_type(%{evidence: [%{type: t} | _]}), do: t
  defp detect_type(%{domain: :knowledge}), do: :direct
  defp detect_type(%{domain: :ontology}), do: :contextual
  defp detect_type(_), do: :unknown

  defp estimate_impact(:direct, _), do: 0.9
  defp estimate_impact(:inferred, _), do: 0.6
  defp estimate_impact(:contextual, _), do: 0.4
  defp estimate_impact(:unknown, c), do: min(1.0, length(Map.get(c, :entity_ids, Map.get(c, :entities, []))) * 0.2)
end
