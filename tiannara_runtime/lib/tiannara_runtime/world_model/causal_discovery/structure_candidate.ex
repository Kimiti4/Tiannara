defmodule TiannaraRuntime.CausalDiscovery.StructureCandidate do
  @moduledoc """
  Phase 17.3 — StructureCandidate: a candidate DAG with score and derivation metadata.
  Content-addressed ID prefix: sc_
  """
  @enforce_keys [:edges, :score]
  defstruct [
    :candidate_id, :edges, :score, :score_type, :derivation,
    :parent_graph, :mutations, :confidence, :metadata
  ]

  @type score_type :: :bge | :bic | :custom
  @type derivation_type :: :constraint_based | :score_based | :hybrid | :expert

  @type edge_entry :: {String.t(), String.t(), atom(), float()}

  @type t :: %__MODULE__{
    candidate_id: String.t(),
    edges: [edge_entry()],
    score: float(),
    score_type: score_type(),
    derivation: derivation_type(),
    parent_graph: String.t() | nil,
    mutations: [map()],
    confidence: float(),
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    c = %__MODULE__{
      candidate_id: Keyword.get(opts, :candidate_id),
      edges: Keyword.get(opts, :edges, []),
      score: Keyword.get(opts, :score),
      score_type: Keyword.get(opts, :score_type, :bic),
      derivation: Keyword.get(opts, :derivation, :score_based),
      parent_graph: Keyword.get(opts, :parent_graph),
      mutations: Keyword.get(opts, :mutations, []),
      confidence: Keyword.get(opts, :confidence, 1.0),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, c} <- validate(c),
         do: {:ok, ensure_id(c)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{edges: e}) when not is_list(e) or e == [],
    do: {:error, "StructureCandidate edges must be a non-empty list"}
  def validate(%__MODULE__{score: s}) when is_nil(s),
    do: {:error, "StructureCandidate score must not be nil"}
  def validate(%__MODULE__{score_type: t}) when t not in ~w(bge bic custom)a,
    do: {:error, "StructureCandidate score_type must be :bge, :bic, or :custom"}
  def validate(%__MODULE__{derivation: d}) when d not in ~w(constraint_based score_based hybrid expert)a,
    do: {:error, "StructureCandidate derivation must be :constraint_based, :score_based, :hybrid, or :expert"}
  def validate(%__MODULE__{confidence: c}) when c < 0.0 or c > 1.0,
    do: {:error, "StructureCandidate confidence must be in [0.0, 1.0]"}
  def validate(%__MODULE__{} = c), do: {:ok, c}
  def validate(_), do: {:error, "invalid StructureCandidate"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = c) do
    Map.from_struct(c)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_list(v), do: Enum.map(v, &canonical_value/1)
  defp canonical_value({a, b, c, d}), do: [a, b, to_string(c), d]
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = c) do
    edges_str = c.edges |> Enum.sort() |> inspect()
    raw = edges_str <> Float.to_string(c.score) <> Atom.to_string(c.derivation)
    "sc_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{candidate_id: nil} = c), do: %{c | candidate_id: compute_id(c)}
  defp ensure_id(%__MODULE__{} = c), do: c
end
