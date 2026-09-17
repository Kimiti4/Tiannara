defmodule TiannaraRuntime.WorldModel.Prediction.Behaviours.ReplayBehaviour do
  @moduledoc """
  Defines the contract for replaying and verifying past predictions.
  Implementations produce a deterministic fingerprint from a Prediction and can verify
  a stored prediction against a replayed computation.
  """

  @callback fingerprint(TiannaraRuntime.WorldModel.Prediction.Prediction.t()) :: String.t()

  @callback verify(String.t(), keyword()) ::
              {:ok, %{verified: boolean(), mismatches: [String.t()]}}
end
