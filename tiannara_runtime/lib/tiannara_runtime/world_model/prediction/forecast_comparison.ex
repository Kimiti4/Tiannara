defmodule TiannaraRuntime.WorldModel.Prediction.ForecastComparison do
  @moduledoc """
  Phase 17.4 — ForecastComparison: pairwise or multi-way comparison across forecasts.
  Content-addressed ID prefix: pc_
  """
  alias TiannaraRuntime.WorldModel.Prediction.Forecast

  @enforce_keys [:forecasts]
  defstruct [
    :comparison_id, :forecasts, :divergence, :consensus,
    :confidence_ranking, :explanation, :metadata
  ]

  @type t :: %__MODULE__{
    comparison_id: String.t(),
    forecasts: [Forecast.t()],
    divergence: float(),
    consensus: map(),
    confidence_ranking: [String.t()],
    explanation: String.t(),
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    pc = %__MODULE__{
      comparison_id: Keyword.get(opts, :comparison_id),
      forecasts: Keyword.get(opts, :forecasts),
      divergence: Keyword.get(opts, :divergence, 0.0),
      consensus: Keyword.get(opts, :consensus, %{}),
      confidence_ranking: Keyword.get(opts, :confidence_ranking, []),
      explanation: Keyword.get(opts, :explanation, ""),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, pc} <- validate(pc),
         do: {:ok, ensure_id(pc)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{forecasts: f}) when is_nil(f) or f == [],
    do: {:error, "ForecastComparison forecasts must not be empty"}
  def validate(%__MODULE__{forecasts: f}) when length(f) < 2,
    do: {:error, "ForecastComparison forecasts must have at least 2 entries"}
  def validate(%__MODULE__{divergence: d}) when not is_number(d) or d < 0.0 or d > 1.0,
    do: {:error, "ForecastComparison divergence must be in [0.0, 1.0]"}
  def validate(%__MODULE__{confidence_ranking: cr}) when not is_list(cr),
    do: {:error, "ForecastComparison confidence_ranking must be a list"}
  def validate(%__MODULE__{explanation: e}) when not is_binary(e),
    do: {:error, "ForecastComparison explanation must be a string"}
  def validate(%__MODULE__{} = pc), do: {:ok, pc}
  def validate(_), do: {:error, "invalid ForecastComparison"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = pc) do
    Map.from_struct(pc)
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
  def compute_id(%__MODULE__{} = pc) do
    raw = inspect(pc.forecasts)
    "pc_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{comparison_id: nil} = pc), do: %{pc | comparison_id: compute_id(pc)}
  defp ensure_id(%__MODULE__{} = pc), do: pc
end
