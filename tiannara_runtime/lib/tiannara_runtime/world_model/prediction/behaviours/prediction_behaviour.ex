defmodule TiannaraRuntime.WorldModel.Prediction.Behaviours.PredictionBehaviour do
  @moduledoc """
  Defines the contract for making predictions against a world model.
  Implementations produce a Prediction struct from a stored world model state.
  """

  @callback predict(String.t(), [String.t()], atom(), keyword()) ::
              {:ok, TiannaraRuntime.WorldModel.Prediction.Prediction.t()} | {:error, term()}
end
