defmodule TiannaraRuntime.Cognitive.Behaviours.ReplayBehaviour do
  @moduledoc "Phase 18.05 — Artifact recording and reconstruction behaviour"

  @callback record(term(), term()) :: {:ok, term()} | {:error, term()}
  @callback reconstruct(term()) :: {:ok, term()} | {:error, term()}
  @callback verify(term(), term()) :: {:ok, :verified} | {:error, term()}
  @callback get_sequence(term(), term()) :: {:ok, list()} | {:error, term()}
end