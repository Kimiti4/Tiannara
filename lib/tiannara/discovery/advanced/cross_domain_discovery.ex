defmodule Tiannara.Discovery.Advanced.CrossDomainDiscovery do
  alias Tiannara.Discovery.Domain.KnowledgeGap

  @spec discover([KnowledgeGap.t()], [map()]) :: [map()]
  def discover(gaps, knowledge_base) when is_list(gaps) and is_list(knowledge_base) do
    gaps
    |> Enum.flat_map(fn gap -> find_analogs(gap, knowledge_base) end)
    |> rank_by_transfer_potential()
  end

  @spec find_analogs(KnowledgeGap.t(), [map()]) :: [map()]
  def find_analogs(%KnowledgeGap{} = gap, knowledge_base) do
    knowledge_base
    |> Enum.filter(fn item ->
      Map.get(item, :domain) != gap.domain and structural_similarity(gap, item) > 0.3
    end)
    |> Enum.map(fn item ->
      similarity = structural_similarity(gap, item)
      %{
        source_gap: gap.id,
        source_domain: gap.domain,
        target_item: Map.get(item, :id),
        target_domain: Map.get(item, :domain),
        similarity: similarity,
        transfer_potential: compute_transfer_potential(gap, item, similarity),
        analogy_type: classify_analogy(gap, item),
        suggested_hypothesis: generate_cross_domain_hypothesis(gap, item),
        confidence: similarity * 0.7
      }
    end)
  end

  @spec structural_similarity(KnowledgeGap.t(), map()) :: float()
  def structural_similarity(%KnowledgeGap{} = gap, item) do
    gap_features = extract_structural_features(gap)
    item_features = extract_structural_features(item)
    cosine_similarity(gap_features, item_features)
  end

  defp extract_structural_features(entity) do
    %{
      complexity: Map.get(entity, :estimated_impact, 0.5),
      uncertainty: Map.get(entity, :uncertainty, 0.5),
      severity: severity_to_numeric(Map.get(entity, :severity, :medium)),
      connectivity: Map.get(entity, :connectivity, 0.5),
      temporal_scale: Map.get(entity, :temporal_scale, 0.5),
      abstraction_level: Map.get(entity, :abstraction_level, 0.5)
    }
  end

  defp severity_to_numeric(:critical), do: 1.0
  defp severity_to_numeric(:high), do: 0.75
  defp severity_to_numeric(:medium), do: 0.5
  defp severity_to_numeric(:low), do: 0.25

  defp cosine_similarity(vec_a, vec_b) do
    keys = Map.keys(vec_a)
    dot_product = Enum.reduce(keys, 0.0, fn key, acc -> acc + Map.get(vec_a, key, 0.0) * Map.get(vec_b, key, 0.0) end)
    magnitude_a = keys |> Enum.reduce(0.0, fn key, acc -> acc + :math.pow(Map.get(vec_a, key, 0.0), 2) end) |> :math.sqrt()
    magnitude_b = keys |> Enum.reduce(0.0, fn key, acc -> acc + :math.pow(Map.get(vec_b, key, 0.0), 2) end) |> :math.sqrt()
    if magnitude_a > 0 and magnitude_b > 0, do: dot_product / (magnitude_a * magnitude_b), else: 0.0
  end

  defp compute_transfer_potential(gap, item, similarity) do
    target_saturation = Map.get(item, :domain_saturation, 0.5)
    gap_severity = severity_to_numeric(gap.severity)
    similarity * (1.0 - target_saturation) * gap_severity
  end

  defp classify_analogy(_gap, item) do
    cond do
      Map.get(item, :type) == :pattern -> :structural_analogy
      Map.get(item, :type) == :principle -> :principled_analogy
      Map.get(item, :type) == :model -> :model_analogy
      true -> :surface_analogy
    end
  end

  defp generate_cross_domain_hypothesis(gap, item) do
    "The #{Map.get(item, :type, :pattern)} '#{Map.get(item, :description, "unknown")}' " <>
    "from #{Map.get(item, :domain, :unknown)} may explain the gap in #{gap.domain}: #{gap.description}"
  end

  defp rank_by_transfer_potential(connections) do
    Enum.sort_by(connections, & &1.transfer_potential, :desc)
  end
end
