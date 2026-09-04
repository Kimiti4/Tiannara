defmodule Tiannara.NearestNeighbor do
  @moduledoc """
  Lightweight nearest-neighbor lookup for artifact novelty checks.

  Uses a simple Euclidean distance over numeric embedding values to identify
  the closest candidate in a collection of existing artifacts.
  """

  def find(candidate_embedding, existing_artifacts) when is_list(existing_artifacts) do
    existing_artifacts
    |> Enum.map(fn artifact ->
      distance = distance(candidate_embedding, artifact.embedding)
      %{artifact_id: artifact.artifact_id, embedding: artifact.embedding, distance: distance}
    end)
    |> Enum.min_by(& &1.distance, fn -> nil end)
  end

  def find(_candidate_embedding, _existing_artifacts), do: nil

  defp distance(left, right) when is_map(left) and is_map(right) do
    left_values = Map.values(left) |> Enum.map(&normalize_value/1)
    right_values = Map.values(right) |> Enum.map(&normalize_value/1)

    max_length = max(length(left_values), length(right_values))
    padded_left = pad_values(left_values, max_length)
    padded_right = pad_values(right_values, max_length)

    Enum.zip(padded_left, padded_right)
    |> Enum.reduce(0.0, fn {a, b}, acc ->
      acc + :math.pow(a - b, 2)
    end)
    |> :math.sqrt()
  end

  defp distance(_left, _right), do: 1.0e9

  defp normalize_value(value) when is_number(value), do: value
  defp normalize_value(value) when is_atom(value), do: 0.0
  defp normalize_value(_value), do: 0.0

  defp pad_values(values, size) do
    values
    |> Enum.concat(List.duplicate(0.0, size - length(values)))
    |> Enum.take(size)
  end
end
