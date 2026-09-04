defmodule Tiannara.Discovery.Advanced.NoveltyDetector do
  alias Tiannara.Discovery.Discovery

  @spec score(Discovery.t(), [map()]) :: map()
  def score(%Discovery{} = disc, existing_knowledge) when is_list(existing_knowledge) do
    conceptual = compute_conceptual_novelty(disc, existing_knowledge)
    methodological = compute_methodological_novelty(disc, existing_knowledge)
    domain = compute_domain_novelty(disc, existing_knowledge)
    temporal = compute_temporal_novelty(disc, existing_knowledge)
    impact = compute_impact_novelty(disc)

    composite = geometric_mean([conceptual, methodological, domain, temporal, impact])

    %{
      discovery_id: disc.id,
      conceptual: conceptual,
      methodological: methodological,
      domain: domain,
      temporal: temporal,
      impact: impact,
      composite: composite,
      classification: classify_novelty(composite),
      details: build_details(conceptual, methodological, domain, temporal, impact)
    }
  end

  @spec novel?(Discovery.t(), [map()]) :: boolean()
  def novel?(%Discovery{} = disc, existing_knowledge) do
    result = score(disc, existing_knowledge)
    result.composite > 0.5
  end

  defp compute_conceptual_novelty(%Discovery{} = disc, existing_knowledge) do
    disc_concepts = extract_concepts(disc)
    known_concepts = Enum.flat_map(existing_knowledge, &Map.get(&1, :concepts, []))
    if disc_concepts == [], do: 0.5, else: length(disc_concepts -- known_concepts) / length(disc_concepts)
  end

  defp compute_methodological_novelty(%Discovery{} = disc, existing_knowledge) do
    disc_methods = Enum.map(disc.experiments, & &1.type) |> Enum.uniq()
    known_methods = Enum.flat_map(existing_knowledge, &Map.get(&1, :methods, [])) |> Enum.uniq()
    if disc_methods == [], do: 0.5, else: length(disc_methods -- known_methods) / length(disc_methods)
  end

  defp compute_domain_novelty(%Discovery{} = disc, existing_knowledge) do
    disc_domain = if disc.gap, do: disc.gap.domain, else: :unknown
    known_domains = Enum.map(existing_knowledge, &Map.get(&1, :domain)) |> Enum.uniq()
    cond do
      disc_domain not in known_domains -> 1.0
      disc_domain == :unknown -> 0.5
      true -> 0.3
    end
  end

  defp compute_temporal_novelty(%Discovery{} = disc, existing_knowledge) do
    similar = Enum.filter(existing_knowledge, fn item ->
      Map.get(item, :domain) == (disc.gap && disc.gap.domain) and Map.get(item, :type) == :discovery
    end)
    cond do
      similar == [] -> 1.0
      length(similar) < 3 -> 0.7
      length(similar) < 10 -> 0.4
      true -> 0.2
    end
  end

  defp compute_impact_novelty(%Discovery{} = disc) do
    uncertainty = disc.uncertainty
    impact = if disc.gap, do: disc.gap.estimated_impact, else: 0.5
    hyp_count = length(disc.hypotheses)
    min(1.0, uncertainty * impact * min(1.0, hyp_count / 4.0))
  end

  defp extract_concepts(%Discovery{} = disc) do
    gap_concepts = if disc.gap, do: [disc.gap.domain], else: []
    hyp_concepts = Enum.flat_map(disc.hypotheses, fn hyp -> [Map.get(hyp.metadata, :causal_model, :unknown)] end)
    (gap_concepts ++ hyp_concepts) |> Enum.uniq()
  end

  defp geometric_mean(values) do
    if Enum.any?(values, &(&1 <= 0.0)), do: 0.0, else: :math.pow(Enum.reduce(values, 1.0, &(&1 * &2)), 1.0 / length(values))
  end

  defp classify_novelty(composite) do
    cond do
      composite > 0.8 -> :groundbreaking
      composite > 0.6 -> :significant
      composite > 0.4 -> :incremental
      composite > 0.2 -> :minor
      true -> :negligible
    end
  end

  defp build_details(conceptual, methodological, domain, temporal, impact) do
    [
      "Conceptual novelty: #{Float.round(conceptual, 2)}",
      "Methodological novelty: #{Float.round(methodological, 2)}",
      "Domain novelty: #{Float.round(domain, 2)}",
      "Temporal novelty: #{Float.round(temporal, 2)}",
      "Impact novelty: #{Float.round(impact, 2)}"
    ]
  end
end
