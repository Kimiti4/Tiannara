defmodule TiannaraRuntime.WorldModel.Pipeline.ModelEvolution do
  @moduledoc """
  Phase 17.2 — Model Evolution (Pipeline Stage 10).

  Updates an operational world model with new evidence, creating
  a new version of the model.
  """

  @behaviour TiannaraRuntime.WorldModel.Behaviours.Pipeline

  alias TiannaraRuntime.WorldModel.Ontology.WorldModel
  alias TiannaraRuntime.WorldModel.ModelRegistry

  @impl true
  @spec evolve_model(WorldModel.t(), map()) :: {:ok, WorldModel.t()} | {:error, String.t()}
  def evolve_model(%WorldModel{} = model, new_evidence) when is_map(new_evidence) do
    new_evidence_root = Map.get(new_evidence, :evidence_root, Map.get(new_evidence, "evidence_root"))

    evidence_roots = model.evidence_roots ++ [new_evidence_root]

    updated = %{model | evidence_roots: evidence_roots, version: nil, status: :draft}

    ModelRegistry.store_model(updated, force: false)
  end
end
