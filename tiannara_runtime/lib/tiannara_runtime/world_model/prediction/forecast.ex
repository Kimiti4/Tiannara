defmodule TiannaraRuntime.WorldModel.Prediction.Forecast do
  @moduledoc """
  Phase 17.4 — Forecast: a structured set of time-step predictions for a given horizon.
  Content-addressed ID prefix: fc_
  """
  alias TiannaraRuntime.WorldModel.Prediction.ForecastStep
  alias TiannaraRuntime.WorldModel.Prediction.ForecastVariable

  @enforce_keys [:horizon, :time_steps, :variables]
  defstruct [
    :forecast_id, :horizon, :time_steps, :variables,
    :governing_equations, :causal_constraints, :metadata
  ]

  @type t :: %__MODULE__{
    forecast_id: String.t(),
    horizon: atom(),
    time_steps: [ForecastStep.t()],
    variables: [ForecastVariable.t()],
    governing_equations: [String.t()],
    causal_constraints: [map()],
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    f = %__MODULE__{
      forecast_id: Keyword.get(opts, :forecast_id),
      horizon: Keyword.get(opts, :horizon),
      time_steps: Keyword.get(opts, :time_steps, []),
      variables: Keyword.get(opts, :variables),
      governing_equations: Keyword.get(opts, :governing_equations, []),
      causal_constraints: Keyword.get(opts, :causal_constraints, []),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, f} <- validate(f),
         do: {:ok, ensure_id(f)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{horizon: h}) when h not in ~w(immediate short_term medium_term long_term civilization)a,
    do: {:error, "Forecast horizon must be one of: immediate, short_term, medium_term, long_term, civilization"}
  def validate(%__MODULE__{time_steps: ts}) when not is_list(ts) or ts == [],
    do: {:error, "Forecast time_steps must be a non-empty list"}
  def validate(%__MODULE__{variables: v}) when is_nil(v),
    do: {:error, "Forecast variables must not be nil"}
  def validate(%__MODULE__{variables: v}) when not is_list(v) or v == [],
    do: {:error, "Forecast variables must be a non-empty list"}
  def validate(%__MODULE__{} = f), do: {:ok, f}
  def validate(_), do: {:error, "invalid Forecast"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = f) do
    Map.from_struct(f)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(%ForecastStep{} = fs), do: ForecastStep.canonicalize(fs)
  defp canonical_value(%ForecastVariable{} = fv), do: ForecastVariable.canonicalize(fv)
  defp canonical_value(v) when is_list(v), do: Enum.sort(v)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = f) do
    raw = Atom.to_string(f.horizon) <> inspect(f.time_steps) <> inspect(f.variables)
    "fc_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{forecast_id: nil} = f), do: %{f | forecast_id: compute_id(f)}
  defp ensure_id(%__MODULE__{} = f), do: f
end
