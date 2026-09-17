defmodule TiannaraRuntime.WorldModel.Counterfactual.Behaviours.ComparisonBehaviour do
  @moduledoc """
  Defines the contract for comparing a base world model against a counterfactual world
  and producing a structured branch comparison.
  """

  @callback compare(
              world_model :: TiannaraRuntime.WorldModel.Ontology.WorldModel.t(),
              counterfactual_world :: TiannaraRuntime.WorldModel.Counterfactual.CounterfactualWorld.t()
            ) ::
              {:ok, TiannaraRuntime.WorldModel.Counterfactual.BranchComparison.t()}
end