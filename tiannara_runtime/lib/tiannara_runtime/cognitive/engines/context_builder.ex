defmodule TiannaraRuntime.Cognitive.Engines.ContextBuilder do
  @moduledoc "Phase 18.2 — Context construction engine"

  alias TiannaraRuntime.Cognitive.CognitiveContext

  def build_context(mission, working_memory, knowledge_refs) do
    # `CognitiveContext.new/1` reads several fields by dot access, so every
    # field it touches must be present. Passing only three of them raised a
    # KeyError, which meant this engine could not build a context for any
    # caller.
    {:ok, context} = CognitiveContext.new(%{
      mission: mission,
      working_memory: working_memory,
      knowledge_references: knowledge_refs,
      world_models: [],
      simulation_references: [],
      mathematical_references: [],
      migration_version: 0
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
