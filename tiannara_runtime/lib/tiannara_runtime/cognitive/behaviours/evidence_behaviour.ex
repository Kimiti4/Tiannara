defmodule TiannaraRuntime.Cognitive.Behaviours.EvidenceBehaviour do
  @moduledoc "Phase 18.09 — Cognitive evidence routing and verification behaviour"

  @callback route(subsystem :: atom(), stage :: atom(), evidence :: map()) :: {:ok, map()} | {:error, term()}
  @callback verify(evidence :: map()) :: {:ok, boolean()} | {:error, term()}
  @callback chain(mission_id :: String.t()) :: {:ok, list()} | {:error, term()}
end
