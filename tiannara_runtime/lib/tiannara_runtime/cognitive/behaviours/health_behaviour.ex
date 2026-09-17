defmodule TiannaraRuntime.Cognitive.Behaviours.HealthBehaviour do
  @callback assess(monitors :: list(), config :: map()) :: {:ok, map()} | {:error, term()}
  @callback compare(a :: map(), b :: map()) :: {:ok, map()} | {:error, term()}
  @callback status(assessment :: map()) :: {:ok, atom()} | {:error, term()}
end
