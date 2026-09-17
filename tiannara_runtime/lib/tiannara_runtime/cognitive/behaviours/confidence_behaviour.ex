defmodule TiannaraRuntime.Cognitive.Behaviours.ConfidenceBehaviour do
  @callback estimate(session :: map(), evidence :: list()) :: {:ok, map()} | {:error, term()}
  @callback calibrate(outcomes :: list(), predictions :: list()) :: {:ok, map()} | {:error, term()}
  @callback score(estimate :: map()) :: {:ok, float()} | {:error, term()}
end
