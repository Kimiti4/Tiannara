defmodule TiannaraRuntime.WorldModel.Prediction.Behaviours.ConfidenceBehaviour do
  @moduledoc """
  Defines the contract for computing confidence estimates on forecasts.
  Implementations produce a ConfidenceEstimate struct that quantifies prediction certainty.
  """

  @callback compute(TiannaraRuntime.WorldModel.WorldModel.t(), TiannaraRuntime.WorldModel.Prediction.Forecast.t(), keyword()) ::
              {:ok, TiannaraRuntime.WorldModel.Prediction.ConfidenceEstimate.t()}
end
