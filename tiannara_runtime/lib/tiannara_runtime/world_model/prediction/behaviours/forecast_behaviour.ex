defmodule TiannaraRuntime.WorldModel.Prediction.Behaviours.ForecastBehaviour do
  @moduledoc """
  Defines the contract for generating forecasts from a live world model.
  Implementations produce a Forecast struct by simulating forward from the given model state.
  """

  @callback generate(TiannaraRuntime.WorldModel.WorldModel.t(), [TiannaraRuntime.WorldModel.Prediction.ForecastVariable.t()], atom(), keyword()) ::
              {:ok, TiannaraRuntime.WorldModel.Prediction.Forecast.t()} | {:error, term()}
end
