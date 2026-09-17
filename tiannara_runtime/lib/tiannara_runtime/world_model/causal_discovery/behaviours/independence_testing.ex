defmodule TiannaraRuntime.CausalDiscovery.Behaviours.IndependenceTesting do
  @moduledoc """
  Phase 17.3 — IndependenceTestingBehaviour: contract for conditional/marginal independence test implementations.
  """
  @callback test_conditional(
    variable_a :: String.t(),
    variable_b :: String.t(),
    conditioning_set :: [String.t()],
    evidence_set :: map()
  ) ::
    {:ok, TiannaraRuntime.CausalDiscovery.IndependenceResult.t()}
    | {:error, String.t()}

  @callback test_marginal(
    variable_a :: String.t(),
    variable_b :: String.t(),
    evidence_set :: map()
  ) ::
    {:ok, TiannaraRuntime.CausalDiscovery.IndependenceResult.t()}
    | {:error, String.t()}

  @callback batch_test(
    variables :: [String.t()],
    evidence_set :: map(),
    config :: map()
  ) ::
    {:ok, [TiannaraRuntime.CausalDiscovery.IndependenceResult.t()]}
    | {:error, String.t()}
end
