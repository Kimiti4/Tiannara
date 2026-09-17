defmodule TiannaraRuntime.CausalDiscovery.Behaviours.CausalValidation do
  @moduledoc """
  Phase 17.3 — CausalValidationBehaviour: contract for graph validation and evidence grounding.
  """
  @callback validate_graph(
    causal_graph :: TiannaraRuntime.WorldModel.Ontology.CausalGraph.t()
  ) ::
    {:ok, TiannaraRuntime.CausalDiscovery.CausalValidationResult.t()}
    | {:error, String.t()}

  @callback validate_evidence_grounding(
    causal_graph :: TiannaraRuntime.WorldModel.Ontology.CausalGraph.t(),
    evidence_set :: map()
  ) ::
    {:ok, %{grounded: boolean(), ungrounded_edges: [String.t()]}}
    | {:error, String.t()}

  @callback validate_intervention(
    intervention :: TiannaraRuntime.WorldModel.Ontology.Intervention.t(),
    causal_graph :: TiannaraRuntime.WorldModel.Ontology.CausalGraph.t()
  ) ::
    :ok
    | {:error, String.t()}
end
