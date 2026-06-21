defmodule Tiannara.Math do
  @moduledoc "Sparse vector mathematical operations for the Lexical Tensegrity Field."

  @spec cosine_similarity(map(), map()) :: float()
  def cosine_similarity(vec1, vec2) when is_map(vec1) and is_map(vec2) do
    dot = dot_product(vec1, vec2)
    mag1 = magnitude(vec1)
    mag2 = magnitude(vec2)

    if mag1 == 0.0 or mag2 == 0.0, do: 0.0, else: dot / (mag1 * mag2)
  end

  defp dot_product(vec1, vec2) do
    # Iterate over the smaller map for O(min(N, M)) efficiency
    {small, large} = if map_size(vec1) <= map_size(vec2), do: {vec1, vec2}, else: {vec2, vec1}
    
    Enum.reduce(small, 0.0, fn {k, v1}, acc ->
      case Map.fetch(large, k) do
        {:ok, v2} -> acc + v1 * v2
        :error -> acc
      end
    end)
  end

  defp magnitude(vec) do
    vec
    |> Map.values()
    |> Enum.reduce(0.0, fn v, acc -> acc + v * v end)
    |> :math.sqrt()
  end
end
