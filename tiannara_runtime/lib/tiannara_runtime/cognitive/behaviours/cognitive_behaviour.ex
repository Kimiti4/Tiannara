defmodule TiannaraRuntime.Cognitive.Behaviours.CognitiveBehaviour do
  @moduledoc "Phase 18.05 — Core cognitive lifecycle behaviour"

  @callback initialize(term()) :: {:ok, term()} | {:error, term()}
  @callback process_pipeline(term(), term()) :: {:ok, term(), term()} | {:error, term()}
  @callback shutdown(term()) :: :ok
end