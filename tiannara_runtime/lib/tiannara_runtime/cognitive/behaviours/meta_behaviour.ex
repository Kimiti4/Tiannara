defmodule TiannaraRuntime.Cognitive.Behaviours.MetaBehaviour do
  @callback initialize_session(config :: map()) :: {:ok, map()} | {:error, term()}
  @callback record_step(session :: map(), step_type :: atom(), data :: map()) :: {:ok, map()} | {:error, term()}
  @callback finalize(session :: map()) :: {:ok, map()} | {:error, term()}
  @callback summarize(session :: map()) :: {:ok, map()} | {:error, term()}
end
