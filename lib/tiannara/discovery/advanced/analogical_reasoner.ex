defmodule Tiannara.Discovery.Advanced.AnalogicalReasoner do
  @spec reason(map(), map()) :: [map()]
  def reason(source, target) when is_map(source) and is_map(target) do
    mapping = compute_mapping(source, target)
    transferred = transfer_solution(source, target, mapping)

    hypotheses = generate_analogical_hypotheses(source, target, mapping, transferred)

    hypotheses
    |> Enum.map(fn hyp ->
      confidence = estimate_transfer_confidence(hyp, mapping)
      failure_modes = identify_transfer_failures(hyp, mapping)
      Map.merge(hyp, %{transfer_confidence: confidence, failure_modes: failure_modes, mapping_quality: mapping.quality})
    end)
    |> Enum.sort_by(& &1.transfer_confidence, :desc)
  end

  @spec evaluate_mapping(map()) :: float()
  def evaluate_mapping(mapping) do
    Map.get(mapping, :quality, 0.0)
  end

  defp compute_mapping(source, target) do
    source_features = Map.get(source, :features, %{})
    target_features = Map.get(target, :features, %{})

    shared_keys = MapSet.intersection(MapSet.new(Map.keys(source_features)), MapSet.new(Map.keys(target_features)))
    total_keys = MapSet.union(MapSet.new(Map.keys(source_features)), MapSet.new(Map.keys(target_features)))

    quality = if MapSet.size(total_keys) > 0, do: MapSet.size(shared_keys) / MapSet.size(total_keys), else: 0.0

    %{
      source_domain: Map.get(source, :domain),
      target_domain: Map.get(target, :domain),
      shared_elements: MapSet.to_list(shared_keys),
      quality: quality,
      correspondences: build_correspondences(source_features, target_features, shared_keys)
    }
  end

  defp build_correspondences(source_features, target_features, shared_keys) do
    MapSet.to_list(shared_keys)
    |> Enum.map(fn key ->
      %{
        element: key,
        source_value: Map.get(source_features, key),
        target_value: Map.get(target_features, key),
        correspondence_strength: compute_correspondence_strength(Map.get(source_features, key), Map.get(target_features, key))
      }
    end)
  end

  defp compute_correspondence_strength(a, b) when is_number(a) and is_number(b), do: 1.0 - abs(a - b) / max(1.0, max(abs(a), abs(b)))
  defp compute_correspondence_strength(a, b) when a == b, do: 1.0
  defp compute_correspondence_strength(_, _), do: 0.3

  defp transfer_solution(source, target, mapping) do
    solution = Map.get(source, :solution, %{})
    principles = Map.get(source, :principles, [])

    transferred_principles = Enum.map(principles, fn principle ->
      %{
        original: principle,
        adapted: adapt_principle(principle, mapping),
        confidence: mapping.quality * 0.8
      }
    end)

    %{
      principles: transferred_principles,
      solution_components: Map.get(solution, :components, []),
      adaptation_notes: generate_adaptation_notes(source, target, mapping)
    }
  end

  defp adapt_principle(principle, mapping) do
    %{
      statement: "#{Map.get(principle, :statement, "principle")} (adapted from #{mapping.source_domain} to #{mapping.target_domain})",
      source_domain: mapping.source_domain,
      target_domain: mapping.target_domain,
      adaptation_quality: mapping.quality
    }
  end

  defp generate_adaptation_notes(source, target, mapping) do
    [
      "Source domain: #{Map.get(source, :domain, :unknown)}",
      "Target domain: #{Map.get(target, :domain, :unknown)}",
      "Mapping quality: #{Float.round(mapping.quality, 3)}",
      "Shared structural elements: #{length(mapping.shared_elements)}",
      "Caution: Cross-domain transfer requires empirical validation"
    ]
  end

  defp generate_analogical_hypotheses(_source, _target, mapping, transferred) do
    Enum.map(transferred.principles, fn tp ->
      %{
        id: "analogical_hyp_#{:crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)}",
        statement: tp.adapted.statement,
        source_domain: mapping.source_domain,
        target_domain: mapping.target_domain,
        source_principle: tp.original,
        type: :analogical_hypothesis,
        falsifiable: true,
        prior: tp.confidence * mapping.quality,
        expected_information_gain: (1.0 - mapping.quality) * 0.8
      }
    end)
  end

  defp estimate_transfer_confidence(hypothesis, mapping) do
    base = Map.get(hypothesis, :prior, 0.5)
    base * mapping.quality
  end

  defp identify_transfer_failures(_hypothesis, mapping) do
    failures = []
    failures = if mapping.quality < 0.4, do: [%{type: :weak_mapping, detail: "Structural mapping quality #{Float.round(mapping.quality, 2)} < 0.4"} | failures], else: failures
    failures = if mapping.source_domain == mapping.target_domain, do: [%{type: :same_domain, detail: "Source and target are the same domain"} | failures], else: failures
    failures ++ [%{type: :empirical_validation_required, detail: "All analogical transfers require empirical validation"}]
  end
end
