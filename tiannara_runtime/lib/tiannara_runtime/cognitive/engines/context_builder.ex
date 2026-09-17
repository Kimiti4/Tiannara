defmodule TiannaraRuntime.Cognitive.Engines.ContextBuilder do
  @moduledoc "Phase 18.2 — Context construction engine"

  alias TiannaraRuntime.Cognitive.CognitiveContext

  def build_context(mission, working_memory, knowledge_refs) do
    {:ok, context} = CognitiveContext.new(%{
      mission: mission,
      working_memory: working_memory,
      knowledge_references: knowledge_refs
    })
    {:ok, context}
  end

  def build_from_science(context, science_refs) do
    {:ok, Map.put(context, :scientific_references, Enum.sort(science_refs))}
  end

  def build_from_mathematics(context, math_refs) do
    {:ok, Map.put(context, :mathematical_references, Enum.sort(math_refs))}
  end

  def build_from_world_models(context, model_refs) do
    {:ok, Map.put(context, :world_models, Enum.sort(model_refs))}
  end
end
