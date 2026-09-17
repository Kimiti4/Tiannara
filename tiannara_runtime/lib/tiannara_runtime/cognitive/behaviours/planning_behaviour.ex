defmodule TiannaraRuntime.Cognitive.Behaviours.PlanningBehaviour do
  @moduledoc "Phase 18.05 — Plan creation and execution behaviour"

  @callback create_plan(term(), term()) :: {:ok, term()} | {:error, term()}
  @callback execute_step(term(), term()) :: {:ok, term(), term()} | {:error, term()}
  @callback evaluate_progress(term()) :: {:ok, term()} | {:error, term()}
  @callback refine_plan(term(), term()) :: {:ok, term()} | {:error, term()}
end