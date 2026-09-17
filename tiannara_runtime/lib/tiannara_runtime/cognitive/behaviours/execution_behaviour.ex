defmodule TiannaraRuntime.Cognitive.Behaviours.ExecutionBehaviour do
  @moduledoc "Phase 18.09 — Cognitive execution step behaviour"

  @callback execute_step(state :: map(), step :: atom()) :: {:ok, map()} | {:error, term()}
  @callback transition(state :: map(), next_phase :: atom()) :: {:ok, map()} | {:error, term()}
  @callback fail(state :: map(), reason :: term()) :: {:ok, map()} | {:error, term()}
end
