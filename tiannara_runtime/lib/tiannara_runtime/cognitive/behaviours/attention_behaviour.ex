defmodule TiannaraRuntime.Cognitive.Behaviours.AttentionBehaviour do
  @moduledoc "Phase 18.05 — Attentional focus and allocation behaviour"

  @callback focus(term(), term()) :: {:ok, term()} | {:error, term()}
  @callback shift(term(), term(), term()) :: {:ok, term()} | {:error, term()}
  @callback allocate(term(), term()) :: {:ok, term()} | {:error, term()}
  @callback get_allocation(term()) :: {:ok, term()} | {:error, term()}
end