defmodule TiannaraRuntime.CausalDiscovery.CounterfactualBranch do
  @moduledoc """
  Phase 17.3 — CounterfactualBranch: a forked causal model under an intervention.
  Content-addressed ID prefix: cb_
  """
  @enforce_keys [:branch_id, :base_graph_fingerprint, :intervention]
  defstruct [:branch_id, :base_graph_fingerprint, :intervention, :resulting_graph_fingerprint, :confidence, :evidence_roots, :created_at, :metadata]

  @type t :: %__MODULE__{
    branch_id: String.t(),
    base_graph_fingerprint: String.t(),
    intervention: TiannaraRuntime.WorldModel.Ontology.Intervention.t(),
    resulting_graph_fingerprint: String.t() | nil,
    confidence: float() | nil,
    evidence_roots: [String.t()],
    created_at: String.t(),
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    cb = %__MODULE__{
      branch_id: Keyword.get(opts, :branch_id),
      base_graph_fingerprint: Keyword.get(opts, :base_graph_fingerprint),
      intervention: Keyword.get(opts, :intervention),
      resulting_graph_fingerprint: Keyword.get(opts, :resulting_graph_fingerprint),
      confidence: Keyword.get(opts, :confidence),
      evidence_roots: Keyword.get(opts, :evidence_roots, []),
      created_at: Keyword.get(opts, :created_at, now),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, cb} <- validate(cb),
         do: {:ok, ensure_id(cb)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{base_graph_fingerprint: gf}) when is_nil(gf) or gf == "",
    do: {:error, "CounterfactualBranch base_graph_fingerprint must not be empty"}
  def validate(%__MODULE__{intervention: iv}) when is_nil(iv),
    do: {:error, "CounterfactualBranch intervention must not be nil"}
  def validate(%__MODULE__{confidence: c}) when c != nil and (c < 0.0 or c > 1.0),
    do: {:error, "CounterfactualBranch confidence must be in [0.0, 1.0]"}
  def validate(%__MODULE__{evidence_roots: er}) when not is_list(er),
    do: {:error, "CounterfactualBranch evidence_roots must be a list"}
  def validate(%__MODULE__{} = cb), do: {:ok, cb}
  def validate(_), do: {:error, "invalid CounterfactualBranch"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = cb) do
    Map.from_struct(cb)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_list(v), do: Enum.sort(v)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = cb) do
    raw = cb.base_graph_fingerprint <> cb.intervention.intervention_id <>
          (Enum.sort(cb.evidence_roots) |> Enum.join("|"))
    "cb_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{branch_id: nil} = cb), do: %{cb | branch_id: compute_id(cb)}
  defp ensure_id(%__MODULE__{} = cb), do: cb
end
