defmodule TiannaraRuntime.Cognitive.Behaviours.SchedulingBehaviour do
  @moduledoc "Phase 18.05 — Task scheduling and dispatching behaviour"

  @callback schedule(term(), term()) :: {:ok, term()} | {:error, term()}
  @callback dispatch_next(term()) :: {:ok, term(), term()} | {:error, :empty}
  @callback prioritize(term(), term()) :: {:ok, term()} | {:error, term()}
  @callback get_queue(term(), term()) :: {:ok, list()} | {:error, term()}
end