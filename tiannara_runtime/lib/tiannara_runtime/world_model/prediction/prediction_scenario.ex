defmodule TiannaraRuntime.WorldModel.Prediction.PredictionScenario do
  @moduledoc """
  Phase 17.4 — PredictionScenario: a named what-if scenario with a single forecast.
  Content-addressed ID prefix: ps_
  """
  alias TiannaraRuntime.WorldModel.Prediction.Forecast

  @enforce_keys [:name, :forecast]
  defstruct [
    :scenario_id, :name, :assumptions, :intervention,
    :forecast, :metadata
  ]

  @type t :: %__MODULE__{
    scenario_id: String.t(),
    name: String.t(),
    assumptions: map(),
    intervention: map() | nil,
    forecast: Forecast.t(),
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    ps = %__MODULE__{
      scenario_id: Keyword.get(opts, :scenario_id),
      name: Keyword.get(opts, :name),
      assumptions: Keyword.get(opts, :assumptions, %{}),
      intervention: Keyword.get(opts, :intervention),
      forecast: Keyword.get(opts, :forecast),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, ps} <- validate(ps),
         do: {:ok, ensure_id(ps)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{name: n}) when is_nil(n) or n == "",
    do: {:error, "PredictionScenario name must not be empty"}
  def validate(%__MODULE__{forecast: f}) when is_nil(f),
    do: {:error, "PredictionScenario forecast must not be nil"}
  def validate(%__MODULE__{assumptions: a}) when not is_map(a),
    do: {:error, "PredictionScenario assumptions must be a map"}
  def validate(%__MODULE__{} = ps), do: {:ok, ps}
  def validate(_), do: {:error, "invalid PredictionScenario"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = ps) do
    Map.from_struct(ps)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(%Forecast{} = f), do: Forecast.canonicalize(f)
  defp canonical_value(v) when is_list(v), do: Enum.sort(v)
  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = ps) do
    raw = ps.name <> inspect(ps.assumptions)
    "ps_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{scenario_id: nil} = ps), do: %{ps | scenario_id: compute_id(ps)}
  defp ensure_id(%__MODULE__{} = ps), do: ps
end

# Bridge module so test at TiannaraRuntime.Prediction.ValidationCampaignTest
# can resolve PredictionScenario without explicit alias.
defmodule PredictionScenario do
  @doc false
  defdelegate new(opts), to: TiannaraRuntime.WorldModel.Prediction.PredictionScenario
end
