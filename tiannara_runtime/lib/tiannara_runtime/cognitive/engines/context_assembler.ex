defmodule TiannaraRuntime.Cognitive.Engines.ContextAssembler do
  @moduledoc "Phase 18.3 — Context Assembler"

  def assemble(mission, working_memory, activation_graph, opts \\ []) do
    knowledge_refs = opts[:knowledge_refs] || []
    world_models = opts[:world_models] || []
    sorted_refs = Enum.sort(knowledge_refs)
    sorted_models = Enum.sort(world_models)
    context_state = %{
      mission: mission,
      working_memory: working_memory,
      activation_graph: activation_graph,
      knowledge_refs: sorted_refs,
      world_models: sorted_models,
      assembled_at: :erlang.unique_integer([:positive])
    }
    {:ok, context_state}
  end

  def resolve_references(context_state, reference_type) do
    filtered = case reference_type do
      :knowledge -> context_state.knowledge_refs
      :world_model -> context_state.world_models
      _ -> []
    end
    {:ok, filtered}
  end
end
