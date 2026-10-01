defmodule Tiannara.OCM.SemanticDriftAnalyzer do
  @moduledoc """
  Computes cosine drift only from explicitly supplied numeric vectors.

  No default/synthetic drift value is returned.
  """

  def calculate_drift(_concept, definition) when is_map(definition) do
    with {:ok, a} <- vector(definition, :baseline_vector),
         {:ok, b} <- vector(definition, :current_vector),
         {:ok, similarity} <- cosine_similarity(a, b) do
      {:ok, 1.0 - similarity}
    end
  end

  def calculate_drift(_concept, _), do: {:error, :vectors_unavailable}

  defp vector(definition, key) do
    case Map.get(definition, key) do
      values when is_list(values) and values != [] ->
        if Enum.all?(values, &is_number/1), do: {:ok, values}, else: {:error, {:invalid_vector, key}}
      _ -> {:error, {:vector_unavailable, key}}
    end
  end

  defp cosine_similarity(a, b) when length(a) == length(b) do
    dot = Enum.zip(a, b) |> Enum.reduce(0.0, fn {x, y}, acc -> acc + x * y end)
    na = :math.sqrt(Enum.reduce(a, 0.0, fn x, acc -> acc + x * x end))
    nb = :math.sqrt(Enum.reduce(b, 0.0, fn x, acc -> acc + x * x end))
    if na == 0.0 or nb == 0.0, do: {:error, :zero_vector}, else: {:ok, dot / (na * nb)}
  end

  defp cosine_similarity(_, _), do: {:error, :vector_dimension_mismatch}
end
