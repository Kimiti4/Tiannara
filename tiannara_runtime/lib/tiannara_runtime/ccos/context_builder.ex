defmodule TiannaraRuntime.CCOS.ContextBuilder do
  @moduledoc """
  Phase 18.2 Context Builder.

  Builds deterministic cognitive context from supplied memory, knowledge,
  world-model, discovery, and mathematics artifacts. It does not retrieve or
  infer missing data.
  """

  alias TiannaraRuntime.CCOS.Artifact

  @spec build(map(), map()) :: {:ok, map()} | {:error, String.t()}
  def build(mission_state, inputs) when is_map(mission_state) and is_map(inputs) do
    with {:ok, working_memory} <- Artifact.require_list(inputs, :working_memory),
         {:ok, knowledge_graph_refs} <- Artifact.require_list(inputs, :knowledge_graph_refs),
         {:ok, world_model_refs} <- Artifact.require_list(inputs, :world_model_refs),
         {:ok, scientific_discovery_refs} <- Artifact.require_list(inputs, :scientific_discovery_refs),
         {:ok, mathematics_refs} <- Artifact.require_list(inputs, :mathematics_refs) do
      context = %{
        mission_id: Map.fetch!(mission_state, :mission_id),
        working_memory: Artifact.sort_by_content_hash(working_memory),
        knowledge_graph_refs: Artifact.sort_by_content_hash(knowledge_graph_refs),
        world_model_refs: Artifact.sort_by_content_hash(world_model_refs),
        scientific_discovery_refs: Artifact.sort_by_content_hash(scientific_discovery_refs),
        mathematics_refs: Artifact.sort_by_content_hash(mathematics_refs)
      }

      {:ok, Map.put(context, :context_id, Artifact.content_id("cckctx", context))}
    end
  end

  def build(_mission_state, _inputs),
    do: {:error, "ContextBuilder.build requires mission state and context input maps"}
end
