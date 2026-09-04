defmodule Tiannara.Forecasting.Correlation do
  @moduledoc """
  Detection of redundant evidence and false independence between signals.

  Two (or more) signals may APPEAR independent but actually derive from the same
  underlying source. D1 detects:

    - direct duplication          — identical source+observation (dedup key)
    - shared provenance lineage   — derived signals sharing a parent
    - shared upstream source      — same `source`
    - feature correlation         — high cosine similarity of observation vectors
    - common model dependency     — same model/plugin named in metadata

  This prevents false confidence from evidence counting. The "fox" rule: if two
  signals share the same underlying cause, they are NOT independent evidence.

  Returns a correlation assessment for a pair, and a redundancy index for a set.
  """

  alias Tiannara.Forecasting.Signal
  alias Tiannara.Forecasting.Provenance

  @doc "True if two signals share an upstream origin (source + lineage)."
  @spec shares_origin?(Signal.t(), Signal.t()) :: boolean()
  def shares_origin?(%Signal{} = a, %Signal{} = b) do
    same_source = a.source == b.source
    shared_lineage = not Enum.empty?(intersection(a.lineage, b.lineage))
    same_hash = Provenance.content_hash(a) == Provenance.content_hash(b)
    same_source or shared_lineage or same_hash
  end

  @doc "True if two signals depend on the same model/plugin named in metadata."
  @spec shares_dependency?(Signal.t(), Signal.t()) :: boolean()
  def shares_dependency?(%Signal{} = a, %Signal{} = b) do
    da = model_dependencies(a)
    db = model_dependencies(b)
    not Enum.empty?(intersection(da, db))
  end

  @doc "Correlation score between two signals (0..1); nil if not computable."
  @spec correlation(Signal.t(), Signal.t()) :: float() | :unknown
  def correlation(%Signal{} = a, %Signal{} = b) do
    cond do
      shares_origin?(a, b) ->
        1.0

      shares_dependency?(a, b) ->
        0.8

      true ->
        vector_comparison(a, b)
    end
  end

  @doc "Redundancy index of a set: mean pairwise max correlation, or :unknown."
  @spec redundancy_index([Signal.t()]) :: float() | :unknown
  def redundancy_index(signals) when is_list(signals) and length(signals) > 1 do
    corr =
      signals
      |> unique_pairs()
      |> Enum.map(fn {a, b} -> correlation(a, b) end)
      |> Enum.reject(&(&1 == :unknown))

    case corr do
      [] -> :unknown
      corr -> Enum.sum(corr) / length(corr)
    end
  end

  def redundancy_index(_), do: :unknown

  @doc "The set of signals that share origin with the given signal (redundant cluster)."
  @spec redundant_with(Signal.t(), [Signal.t()]) :: [Signal.t()]
  def redundant_with(%Signal{} = signal, others) when is_list(others) do
    Enum.filter(others, fn o -> shares_origin?(signal, o) or shares_dependency?(signal, o) end)
  end

  def redundant_with(_signal, _others), do: []

  # ------------------------------------------------------------------
  # Helpers
  # ------------------------------------------------------------------

  defp model_dependencies(%Signal{metadata: meta}) do
    case Map.get(meta || %{}, :model_dependencies, []) do
      deps when is_list(deps) -> deps
      _ -> []
    end
  end

  defp intersection(a, b) do
    Enum.filter(a, fn x -> x in b end)
  end

  defp vector_comparison(a, b) do
    # Reuse SignalValue's vector-based cosine comparison logic.
    va = to_vector(a.observation)
    vb = to_vector(b.observation)

    case {va, vb} do
      {nil, _} -> :unknown
      {_, nil} -> :unknown
      {x, y} ->
        cosine(x, y)
    end
  end

  defp to_vector(v) when is_list(v) and length(v) > 0 do
    if Enum.all?(v, &is_number/1), do: Enum.map(v, &(&1 * 1.0)), else: nil
  end

  defp to_vector(%{} = m) do
    vals = m |> Map.values() |> Enum.reject(&is_nil/1)
    if vals == [] or not Enum.all?(vals, &is_number/1), do: nil, else: Enum.map(vals, &(&1 * 1.0))
  end

  defp to_vector(_), do: nil

  defp cosine(a, b) do
    dot = Enum.zip(a, b) |> Enum.reduce(0.0, fn {x, y}, acc -> acc + x * y end)
    na = :math.sqrt(Enum.reduce(a, 0.0, fn x, acc -> acc + x * x end))
    nb = :math.sqrt(Enum.reduce(b, 0.0, fn x, acc -> acc + x * x end))

    if na == 0.0 or nb == 0.0, do: 0.0, else: dot / (na * nb) |> clamp01()
  end

  defp unique_pairs(signals) do
    for {a, i} <- Enum.with_index(signals),
        {b, j} <- Enum.with_index(signals),
        i < j do
      {a, b}
    end
  end

  defp clamp01(x) when x < 0, do: 0.0
  defp clamp01(x) when x > 1, do: 1.0
  defp clamp01(x), do: x
end
