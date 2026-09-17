defmodule TiannaraRuntime.CausalDiscovery.Behaviours.StructureLearning do
  @moduledoc """
  Phase 17.3 — StructureLearningBehaviour: contract for causal structure discovery algorithms.
  """
  @callback discover_structure(evidence_set :: map(), config :: map()) ::
    {:ok, %{causal_graph: TiannaraRuntime.WorldModel.Ontology.CausalGraph.t(),
            candidates: [TiannaraRuntime.CausalDiscovery.StructureCandidate.t()],
            structure_root: String.t()}}
    | {:error, String.t()}

  @callback generate_alternatives(
    causal_graph :: TiannaraRuntime.WorldModel.Ontology.CausalGraph.t(),
    evidence_set :: map(),
    config :: map()
  ) ::
    {:ok, [TiannaraRuntime.CausalDiscovery.StructureCandidate.t()]}
    | {:error, String.t()}

  @callback score_structure(
    candidate :: TiannaraRuntime.CausalDiscovery.StructureCandidate.t(),
    evidence_set :: map()
  ) ::
    {:ok, TiannaraRuntime.CausalDiscovery.StructureCandidate.t()}
    | {:error, String.t()}
end
