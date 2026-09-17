defmodule TiannaraRuntime.Cognitive.Behaviours.DecisionBehaviour do
  @moduledoc "Phase 18.05 — Decision evaluation and selection behaviour"

  @callback evaluate_alternatives(term(), term()) :: {:ok, term()} | {:error, term()}
  @callback select_option(term()) :: {:ok, term()} | {:error, term()}
  @callback justify_decision(term(), term()) :: {:ok, term()} | {:error, term()}
end