defmodule TiannaraRuntime.WorldModel.Counterfactual.Behaviours.InterventionBehaviour do
  @moduledoc """
  Defines the contract for executing and validating interventions against a world model.
  """

  @callback execute(
              world_model :: TiannaraRuntime.WorldModel.Ontology.WorldModel.t(),
              intervention :: TiannaraRuntime.WorldModel.Counterfactual.Intervention.t()
            ) ::
              {:ok, TiannaraRuntime.WorldModel.Counterfactual.Intervention.t()}
              | {:error, term()}

  @callback validate(
              world_model :: TiannaraRuntime.WorldModel.Ontology.WorldModel.t(),
              intervention :: TiannaraRuntime.WorldModel.Counterfactual.Intervention.t()
            ) :: :ok | {:error, String.t()}
end