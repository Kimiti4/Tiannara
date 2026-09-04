defmodule TiannaraAudit.HashVerifier do
  @moduledoc """
  Independently verifies content-addressed hashes.

  Replicates `MathematicalID.from_canonical_map/1` algorithm:
  1. Canonicalize map (sort keys alphabetically, convert keys to strings, recurse)
  2. JSON encode (via Jason)
  3. SHA-256 hash
  4. Base16 lowercase encode

  Without importing the TiannaraRuntime mathematics modules.
  """

  def verify(samples) when is_list(samples) do
    results = Enum.map(samples, fn sample ->
      input = sample[:input]
      expected = sample[:expected_hash]
      computed = from_canonical_map(input)
      match = computed == expected
      %{sample_id: sample[:sample_id], match: match, expected: expected, computed: computed}
    end)

    failures = Enum.filter(results, fn r -> not r.match end)

    %{
      total: length(results),
      failures: length(failures),
      details: Enum.map(failures, fn f ->
        "Sample ##{f.sample_id}: expected #{f.expected}, computed #{f.computed}"
      end)
    }
  end

  @doc """
  Replicates `MathematicalID.from_canonical_map/1` exactly.
  """
  def from_canonical_map(map) when is_map(map) do
    map
    |> canonicalize()
    |> Jason.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp canonicalize(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize(term) when is_list(term), do: Enum.map(term, &canonicalize/1)
  defp canonicalize(term), do: term
end
