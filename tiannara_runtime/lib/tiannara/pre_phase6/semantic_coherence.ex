defmodule Tiannara.PrePhase6.SemanticCoherence do
  @moduledoc """
  Validates OCM + NDE coherence: ensures semantic drift is contained
  and novelty injection hasn't created irreconcilable ontology fragmentation.
  """

  @max_acceptable_drift 0.4
  @min_diversity_threshold 0.2

  @spec validate_ontology_mesh(node_states :: map()) :: {:ok, map()} | {:error, String.t()}
  def validate_ontology_mesh(node_states) do
    if Map.equal?(node_states, %{}) do
      {:ok, %{status: :coherent, drift_summary: %{mean_drift: 0.0, max_drift: 0.0, outlier_count: 0}}}
    else
      with {:ok, drift_metrics} <- compute_global_drift(node_states),
           :ok <- verify_drift_within_bounds(drift_metrics),
           :ok <- ensure_diversity_preserved(node_states) do
        {:ok, %{status: :coherent, drift_summary: drift_metrics}}
      end
    end
  end

  defp compute_global_drift(node_states) do
    nodes = Map.keys(node_states)

    if length(nodes) < 2 do
      {:ok, %{mean_drift: 0.0, max_drift: 0.0, outlier_count: 0}}
    else
      drift_pairs = for i <- 0..(length(nodes)-2), j <- (i+1)..(length(nodes)-1) do
        n1 = Enum.at(nodes, i)
        n2 = Enum.at(nodes, j)
        {n1, n2, compute_cosine_drift(Map.get(node_states[n1], :vector, []), Map.get(node_states[n2], :vector, []))}
      end

      drifts = Enum.map(drift_pairs, &elem(&1, 2))
      mean_drift = Enum.sum(drifts) / length(drifts)
      max_drift = Enum.max(drifts)
      outliers = Enum.count(drift_pairs, &(elem(&1, 2) > @max_acceptable_drift))

      {:ok, %{
        mean_drift: Float.round(mean_drift, 4),
        max_drift: Float.round(max_drift, 4),
        outlier_count: outliers
      }}
    end
  end

  defp compute_cosine_drift(vec1, vec2) do
    dot = Enum.zip(vec1, vec2) |> Enum.reduce(0, fn {a, b}, acc -> acc + a * b end)
    mag1 = :math.sqrt(Enum.reduce(vec1, 0, fn x, acc -> acc + x * x end))
    mag2 = :math.sqrt(Enum.reduce(vec2, 0, fn x, acc -> acc + x * x end))

    if mag1 * mag2 == 0, do: 1.0, else: 1.0 - dot / (mag1 * mag2)
  end

  defp verify_drift_within_bounds(%{max_drift: max, outlier_count: outliers}) do
    cond do
      max > @max_acceptable_drift * 1.5 ->
        {:error, "Critical semantic drift detected (max=#{max})"}

      outliers > 3 ->
        {:error, "Too many outlier node pairs (#{outliers}) exceeding drift threshold"}

      true ->
        :ok
    end
  end

  defp ensure_diversity_preserved(node_states) do
    diversity_scores = Map.values(node_states) |> Enum.map(& Map.get(&1, :semantic_dispersion, 0.5))
    avg_diversity = Enum.sum(diversity_scores) / length(diversity_scores)

    if avg_diversity >= @min_diversity_threshold do
      :ok
    else
      {:error, "Semantic diversity collapsed (avg=#{avg_diversity} < #{@min_diversity_threshold})"}
    end
  end
end
