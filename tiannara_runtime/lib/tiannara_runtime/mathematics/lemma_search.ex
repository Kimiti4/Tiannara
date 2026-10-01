defmodule TiannaraRuntime.Mathematics.LemmaSearch do
  @moduledoc """
  Deterministic lemma-index search over explicitly registered theorem metadata.

  Search results are candidates only. Retrieval never proves applicability.
  """

  def search(index, query) when is_list(index) do
    normalized = normalize(query)

    {:ok,
     index
     |> Enum.filter(fn lemma ->
       terms = Map.get(lemma, :terms, [])
       Enum.any?(terms, &(normalize(&1) == normalized))
     end)
     |> Enum.map(&Map.put(&1, :match_status, :candidate_match))}
  end

  def rank(results) when is_list(results) do
    {:ok, Enum.sort_by(results, fn result ->
      {-Map.get(result, :verified_uses, 0), Map.get(result, :name, "")}
    end)}
  end

  defp normalize(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize(value) when is_binary(value), do: String.downcase(value)
  defp normalize(value), do: inspect(value)
end
