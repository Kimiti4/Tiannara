defmodule Tiannara.CI.Provider do
  @moduledoc """
  Contract for CI providers. Replaceable per provider (GitHub Actions,
  Buildkite, GitLab CI, ...) behind one interface.

  Constitutional basis: Replaceability, "Support reproducibility", "Maintain
  audit trails", "Avoid designs dependent on any single ... platform."
  """

  @callback trigger_workflow(config :: map(), inputs :: map()) ::
              {:ok, run_id :: term()} | {:error, term()}
  @callback run_status(config :: map(), run_id :: term()) ::
              {:ok, status :: atom()} | {:error, term()}
  @callback run_conclusion(config :: map(), run_id :: term()) ::
              {:ok, {output :: term(), exit_code :: integer()}} | {:error, term()}
  @callback cancel_run(config :: map(), run_id :: term()) :: :ok | {:error, term()}
end