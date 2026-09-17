defmodule TiannaraRuntime.Cognitive.Behaviours.ContextBehaviour do
  @moduledoc "Phase 18.05 — Context construction and merging behaviour"

  @callback build_context(term(), term(), term()) :: {:ok, term()} | {:error, term()}
  @callback merge_contexts(term(), term()) :: {:ok, term()} | {:error, term()}
  @callback resolve_references(term(), term()) :: {:ok, term()} | {:error, term()}
end