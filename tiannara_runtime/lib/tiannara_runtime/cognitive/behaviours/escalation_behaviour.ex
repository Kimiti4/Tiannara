defmodule TiannaraRuntime.Cognitive.Behaviours.EscalationBehaviour do
  @callback evaluate(health :: map(), uncertainty :: map(), confidence :: map()) :: {:ok, map()} | {:error, term()}
  @callback escalate(decision :: map(), level :: atom()) :: {:ok, map()} | {:error, term()}
  @callback de_escalate(decision :: map()) :: {:ok, map()} | {:error, term()}
end
