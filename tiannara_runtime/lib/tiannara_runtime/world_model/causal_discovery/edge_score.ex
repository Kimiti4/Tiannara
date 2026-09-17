defmodule TiannaraRuntime.CausalDiscovery.EdgeScore do
  @moduledoc """
  Phase 17.3 — EdgeScore: multi-metric scoring of a causal edge.
  Content-addressed ID prefix: es_
  """
  @enforce_keys [:source, :target]
  defstruct [
    :edge_id, :source, :target, :evidence_support,
    :statistical_strength, :stability, :replay_confidence,
    :intervention_compat, :overall, :weight_vector, :metadata
  ]

  @type t :: %__MODULE__{
    edge_id: String.t(),
    source: String.t(),
    target: String.t(),
    evidence_support: float(),
    statistical_strength: float(),
    stability: float(),
    replay_confidence: float(),
    intervention_compat: float(),
    overall: float(),
    weight_vector: [float()],
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    e = %__MODULE__{
      edge_id: Keyword.get(opts, :edge_id),
      source: Keyword.get(opts, :source),
      target: Keyword.get(opts, :target),
      evidence_support: Keyword.get(opts, :evidence_support, 0.5),
      statistical_strength: Keyword.get(opts, :statistical_strength, 0.5),
      stability: Keyword.get(opts, :stability, 0.5),
      replay_confidence: Keyword.get(opts, :replay_confidence, 0.5),
      intervention_compat: Keyword.get(opts, :intervention_compat, 0.5),
      overall: Keyword.get(opts, :overall, 0.5),
      weight_vector: Keyword.get(opts, :weight_vector, [0.2, 0.2, 0.2, 0.2, 0.2]),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, e} <- validate(e),
         do: {:ok, ensure_id(e)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{source: s}) when is_nil(s) or s == "",
    do: {:error, "EdgeScore source must not be empty"}
  def validate(%__MODULE__{target: t}) when is_nil(t) or t == "",
    do: {:error, "EdgeScore target must not be empty"}
  def validate(%__MODULE__{source: s, target: t}) when s == t,
    do: {:error, "EdgeScore source and target must differ"}
  def validate(%__MODULE__{weight_vector: wv}) when not is_list(wv) or length(wv) != 5,
    do: {:error, "EdgeScore weight_vector must be a list of 5 floats"}
  def validate(%__MODULE__{} = e) do
    scores = [e.evidence_support, e.statistical_strength, e.stability, e.replay_confidence, e.intervention_compat, e.overall]
    bad = Enum.filter(scores, fn s -> s < 0.0 or s > 1.0 end)
    if bad != [] do
      {:error, "EdgeScore all score fields must be in [0.0, 1.0]"}
    else
      {:ok, e}
    end
  end
  def validate(_), do: {:error, "invalid EdgeScore"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = e) do
    Map.from_struct(e)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = e) do
    raw = e.source <> "->" <> e.target
    "es_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{edge_id: nil} = e), do: %{e | edge_id: compute_id(e)}
  defp ensure_id(%__MODULE__{} = e), do: e
end
