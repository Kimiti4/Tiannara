defmodule TiannaraRuntime.WorldModel.Prediction.UncertaintyDistribution do
  @moduledoc """
  Phase 17.4 — UncertaintyDistribution: variance-based uncertainty quantification for a forecast.
  Content-addressed ID prefix: ud_
  """
  @enforce_keys [:variance]
  defstruct [
    :uncertainty_id, :variance, :std_deviation, :confidence_interval,
    :distribution_type, :entropy, :sources, :metadata
  ]

  @type t :: %__MODULE__{
    uncertainty_id: String.t(),
    variance: float(),
    std_deviation: float(),
    confidence_interval: map() | nil,
    distribution_type: atom(),
    entropy: float(),
    sources: [String.t()],
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    variance = Keyword.get(opts, :variance)
    std_dev =
      Keyword.get(opts, :std_deviation) ||
        if variance != nil, do: :math.sqrt(variance), else: 0.0
    ud = %__MODULE__{
      uncertainty_id: Keyword.get(opts, :uncertainty_id),
      variance: variance,
      std_deviation: std_dev,
      confidence_interval: Keyword.get(opts, :confidence_interval),
      distribution_type: Keyword.get(opts, :distribution_type, :unknown),
      entropy: Keyword.get(opts, :entropy, 0.0),
      sources: Keyword.get(opts, :sources, []),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, ud} <- validate(ud),
         do: {:ok, ensure_id(ud)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{variance: v}) when is_nil(v),
    do: {:error, "UncertaintyDistribution variance must not be nil"}
  def validate(%__MODULE__{variance: v}) when v < 0.0,
    do: {:error, "UncertaintyDistribution variance must be >= 0.0"}
  def validate(%__MODULE__{std_deviation: sd}) when sd < 0.0,
    do: {:error, "UncertaintyDistribution std_deviation must be >= 0.0"}
  def validate(%__MODULE__{distribution_type: dt}) when dt not in ~w(normal uniform log_normal exponential poisson binomial unknown)a,
    do: {:error, "UncertaintyDistribution distribution_type must be one of: normal, uniform, log_normal, exponential, poisson, binomial, unknown"}
  def validate(%__MODULE__{entropy: e}) when e < 0.0,
    do: {:error, "UncertaintyDistribution entropy must be >= 0.0"}
  def validate(%__MODULE__{sources: s}) when not is_list(s),
    do: {:error, "UncertaintyDistribution sources must be a list"}
  def validate(%__MODULE__{} = ud), do: {:ok, ud}
  def validate(_), do: {:error, "invalid UncertaintyDistribution"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = ud) do
    Map.from_struct(ud)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_list(v), do: Enum.sort(v)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = ud) do
    raw = Float.to_string(ud.variance) <> Atom.to_string(ud.distribution_type)
    "ud_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{uncertainty_id: nil} = ud), do: %{ud | uncertainty_id: compute_id(ud)}
  defp ensure_id(%__MODULE__{} = ud), do: ud
end
