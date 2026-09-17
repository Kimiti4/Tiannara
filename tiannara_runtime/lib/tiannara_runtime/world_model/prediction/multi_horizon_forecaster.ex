defmodule TiannaraRuntime.WorldModel.Prediction.MultiHorizonForecaster do
  @moduledoc """
  Phase 17.4.6 — MultiHorizonForecaster: generates forecasts across all
  standard horizons for comparative analysis.
  """
  alias TiannaraRuntime.WorldModel.Ontology.WorldModel
  alias TiannaraRuntime.WorldModel.Prediction.{Forecast, ForecastVariable}
  alias TiannaraRuntime.WorldModel.Prediction.ForecastGenerator

  @horizons [:immediate, :short_term, :medium_term, :long_term, :civilization]

  @spec generate_multi_horizon(WorldModel.t(), [ForecastVariable.t()], keyword()) ::
    {:ok, [Forecast.t()]} | {:error, String.t()}
  def generate_multi_horizon(%WorldModel{} = world_model, target_variables, opts \\ []) do
    results =
      Enum.reduce_while(@horizons, {:ok, []}, fn horizon, {:ok, acc} ->
        case ForecastGenerator.generate(world_model, target_variables, horizon, opts) do
          {:ok, forecast} ->
            tagged = %{forecast | metadata: Map.merge(forecast.metadata, %{generated_horizon: horizon, multi_horizon: true})}
            {:cont, {:ok, [tagged | acc]}}
          {:error, reason} ->
            {:halt, {:error, "Horizon #{horizon} failed: #{reason}"}}
        end
      end)

    case results do
      {:ok, forecasts} -> {:ok, Enum.reverse(forecasts)}
      {:error, _} = err -> err
    end
  end

  @spec available_horizons() :: [atom()]
  def available_horizons, do: @horizons
end
