defmodule TiannaraRuntime.Cognitive.Behaviours.ResourceBehaviour do
  @moduledoc "Phase 18.05 — Resource allocation and tracking behaviour"

  @callback allocate(term(), term(), term()) :: {:ok, term()} | {:error, term()}
  @callback track(term()) :: {:ok, term()} | {:error, term()}
  @callback report(term()) :: {:ok, term()} | {:error, term()}
end