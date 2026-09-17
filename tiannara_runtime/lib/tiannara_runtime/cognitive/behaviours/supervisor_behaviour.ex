defmodule TiannaraRuntime.Cognitive.Behaviours.SupervisorBehaviour do
  @moduledoc "Phase 18.05 — Validation, audit, and oversight behaviour"

  @callback validate(term(), term()) :: :ok | {:error, term()}
  @callback audit(term(), term()) :: {:ok, term()} | {:error, term()}
  @callback enforce(term(), term()) :: {:ok, term()} | {:error, term()}
  @callback check_constitutional(term()) :: {:ok, term()} | {:error, term()}
end
