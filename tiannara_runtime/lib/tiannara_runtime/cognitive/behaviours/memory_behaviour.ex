defmodule TiannaraRuntime.Cognitive.Behaviours.MemoryBehaviour do
  @moduledoc "Phase 18.05 — Working memory behaviour"

  @callback store(term(), term(), term()) :: {:ok, term()} | {:error, term()}
  @callback retrieve(term(), term()) :: {:ok, term()} | {:error, :not_found}
  @callback update(term(), term(), term()) :: {:ok, term()} | {:error, term()}
  @callback clear(term()) :: {:ok, term()}
  @callback capacity(term()) :: non_neg_integer()
end