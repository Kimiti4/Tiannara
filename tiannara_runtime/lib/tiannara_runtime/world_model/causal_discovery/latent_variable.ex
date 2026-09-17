defmodule TiannaraRuntime.CausalDiscovery.LatentVariable do
  @moduledoc """
  Phase 17.3 — LatentVariable: a discovered latent (unobserved) variable from residual patterns.
  Content-addressed ID prefix: lv_
  """
  @enforce_keys [:manifest_variables]
  defstruct [
    :latent_id, :name, :manifest_variables, :confidence,
    :detection_method, :competing_explanations,
    :supporting_observations, :metadata
  ]

  @type detection_method :: :residual_correlation | :mediation_gap | :expert

  @type t :: %__MODULE__{
    latent_id: String.t(),
    name: String.t() | nil,
    manifest_variables: [String.t()],
    confidence: float(),
    detection_method: detection_method(),
    competing_explanations: [[String.t()]],
    supporting_observations: [String.t()],
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    l = %__MODULE__{
      latent_id: Keyword.get(opts, :latent_id),
      name: Keyword.get(opts, :name),
      manifest_variables: Keyword.get(opts, :manifest_variables),
      confidence: Keyword.get(opts, :confidence, 0.5),
      detection_method: Keyword.get(opts, :detection_method, :residual_correlation),
      competing_explanations: Keyword.get(opts, :competing_explanations, []),
      supporting_observations: Keyword.get(opts, :supporting_observations, []),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, l} <- validate(l),
         do: {:ok, ensure_id(l)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{manifest_variables: mv}) when not is_list(mv) or length(mv) < 2,
    do: {:error, "LatentVariable manifest_variables must have at least 2 entries"}
  def validate(%__MODULE__{confidence: c}) when c < 0.0 or c > 1.0,
    do: {:error, "LatentVariable confidence must be in [0.0, 1.0]"}
  def validate(%__MODULE__{detection_method: m}) when m not in ~w(residual_correlation mediation_gap expert)a,
    do: {:error, "LatentVariable detection_method must be :residual_correlation, :mediation_gap, or :expert"}
  def validate(%__MODULE__{} = l), do: {:ok, l}
  def validate(_), do: {:error, "invalid LatentVariable"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = l) do
    Map.from_struct(l)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_list(v), do: Enum.map(v, fn
    sub when is_list(sub) -> Enum.sort(sub)
    other -> other
  end)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = l) do
    raw = (Enum.sort(l.manifest_variables) |> Enum.join("|")) <> Atom.to_string(l.detection_method)
    "lv_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{latent_id: nil} = l), do: %{l | latent_id: compute_id(l)}
  defp ensure_id(%__MODULE__{} = l), do: l
end
