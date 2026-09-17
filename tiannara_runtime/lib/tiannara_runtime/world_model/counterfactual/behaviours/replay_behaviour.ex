defmodule TiannaraRuntime.WorldModel.Counterfactual.Behaviours.ReplayBehaviour do
  @moduledoc """
  Defines the contract for fingerprinting and verifying counterfactual world states
  to ensure replay consistency.
  """

  @callback fingerprint(
              counterfactual_world :: TiannaraRuntime.WorldModel.Counterfactual.CounterfactualWorld.t()
            ) :: String.t()

  @callback verify(
              counterfactual_world :: TiannaraRuntime.WorldModel.Counterfactual.CounterfactualWorld.t()
            ) :: {:ok, %{verified: boolean(), mismatches: [String.t()]}}
end