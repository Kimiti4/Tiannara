defmodule TiannaraRuntime.WorldModel.Counterfactual.Behaviours.CounterfactualBehaviour do
  @moduledoc """
  Defines the contract for creating counterfactual worlds from a base world model state
  and a set of interventions.
  """

  @callback create_counterfactual(
              base_world_id :: String.t(),
              intervention :: TiannaraRuntime.WorldModel.Counterfactual.Intervention.t(),
              opts :: keyword()
            ) ::
              {:ok, TiannaraRuntime.WorldModel.Counterfactual.CounterfactualWorld.t()}
              | {:error, term()}
end