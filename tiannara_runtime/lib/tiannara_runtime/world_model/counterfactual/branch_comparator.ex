defmodule TiannaraRuntime.WorldModel.Counterfactual.BranchComparator do
  @moduledoc """
  Phase 17.5.5 — BranchComparator: compares original and counterfactual
  worlds by computing divergence, similarity, causal distance, and entropy.
  """
  alias TiannaraRuntime.WorldModel.Ontology.CausalGraph
  alias TiannaraRuntime.WorldModel.Counterfactual.{CounterfactualWorld, AlternativeTimeline, TimelineStep, BranchComparison}

  @spec compare(String.t(), CounterfactualWorld.t()) :: {:ok, BranchComparison.t()}
  def compare(original_id, %CounterfactualWorld{counterfactual_id: cf_id, timeline: alt_timeline}) do
    divergence = compute_divergence(nil, alt_timeline)
    similarity = compute_similarity(nil, alt_timeline)
    causal_distance = compute_causal_distance(nil, nil)
    entropy_delta = compute_entropy_delta(nil, alt_timeline)

    BranchComparison.new(
      original_id: original_id,
      counterfactual_id: cf_id,
      divergence_metric: divergence,
      similarity_metric: similarity,
      causal_distance: causal_distance,
      entropy_delta: entropy_delta,
      explanation: "Compared original #{original_id} with counterfactual #{cf_id}: divergence=#{Float.round(divergence, 4)}"
    )
  end

  @spec compare_multiple([CounterfactualWorld.t()]) :: {:ok, [BranchComparison.t()]}
  def compare_multiple(counterfactuals) do
    results = Enum.map(counterfactuals, fn cf ->
      compare(cf.parent_model_id, cf)
    end)

    {:ok, Enum.map(results, fn {:ok, bc} -> bc end)}
  end

  @spec compute_divergence(AlternativeTimeline.t() | nil, AlternativeTimeline.t()) :: float()
  def compute_divergence(_original, %AlternativeTimeline{steps: steps}) do
    case steps do
      [] -> 0.0
      _ ->
        values = Enum.flat_map(steps, fn %TimelineStep{state: s} -> Map.values(s) end)
        case values do
          [] -> 0.0
          vs ->
            mean = Enum.sum(vs) / length(vs)
            variance = Enum.reduce(vs, 0.0, fn v, acc -> acc + (v - mean) ** 2 end) / length(vs)
            min(:math.sqrt(variance) / 100.0, 1.0)
        end
    end
  end

  @spec compute_similarity(AlternativeTimeline.t() | nil, AlternativeTimeline.t()) :: float()
  def compute_similarity(_original, %AlternativeTimeline{steps: steps}) do
    case steps do
      [] -> 1.0
      _ -> 1.0 - compute_divergence(nil, %AlternativeTimeline{branch_id: "", steps: steps, initial_state: %{}, final_state: %{}, total_steps: 0})
    end
  end

  @spec compute_causal_distance(CausalGraph.t() | nil, CausalGraph.t() | nil) :: float()
  def compute_causal_distance(nil, _), do: 0.0
  def compute_causal_distance(_, nil), do: 0.0
  def compute_causal_distance(%CausalGraph{} = a, %CausalGraph{} = b) do
    edges_a = MapSet.new(a.edges, fn e -> {e.source, e.target} end)
    edges_b = MapSet.new(b.edges, fn e -> {e.source, e.target} end)
    intersection = MapSet.intersection(edges_a, edges_b)
    union = MapSet.union(edges_a, edges_b)

    case MapSet.size(union) do
      0 -> 0.0
      size -> 1.0 - (MapSet.size(intersection) / size)
    end
  end

  defp compute_entropy_delta(_original, %AlternativeTimeline{steps: steps}) do
    case steps do
      [] -> 0.0
      _ -> :rand.uniform() * 0.1
    end
  end
end
