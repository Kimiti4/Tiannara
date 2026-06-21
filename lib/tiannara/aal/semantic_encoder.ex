defmodule Tiannara.AAL.SemanticEncoder do
  @moduledoc """
  Deterministic, zero-latency semantic encoder using the Hashing Trick (Feature Hashing).
  Bypasses neural networks entirely, mapping lexical tokens to a fixed-dimensional 
  sparse vector space using pure Erlang term hashing.
  """
  @vector_dimensions 512

  @spec encode(String.t()) :: %{integer() => integer()}
  def encode(raw_text) when is_binary(raw_text) do
    raw_text
    |> String.downcase()
    |> String.split(~r/[^a-z0-9]+/, trim: true)
    |> Enum.map(&hash_token/1)
    |> Enum.reduce(%{}, fn {idx, sign}, acc ->
      # Accumulate weights; collisions naturally cancel out or reinforce
      Map.update(acc, idx, sign, &(&1 + sign))
    end)
  end

  defp hash_token(token) do
    # :erlang.phash2/2 is deterministic across the same BEAM architecture.
    idx = :erlang.phash2(token, @vector_dimensions)
    # Apply a sign hash to allow for positive/negative weights (reduces collision impact)
    sign = if :erlang.phash2("s_" <> token, 2) == 0, do: -1, else: 1
    {idx, sign}
  end
end
