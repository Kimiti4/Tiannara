defmodule TiannaraRuntime.Cognitive.Behaviours.RuntimeBehaviour do
  @moduledoc "Phase 18.09 — Cognitive runtime lifecycle behaviour"

  @callback initialize_mission(config :: map()) :: {:ok, map()} | {:error, term()}
  @callback execute_mission(mission :: map()) :: {:ok, map()} | {:error, term()}
  @callback complete_mission(mission :: map()) :: {:ok, map()} | {:error, term()}
  @callback abort_mission(mission :: map(), reason :: term()) :: {:ok, map()} | {:error, term()}
end
