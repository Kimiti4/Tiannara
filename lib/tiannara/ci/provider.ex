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

  @doc """
  Correlation-aware lookup: find the run whose dispatch inputs carry
  `correlation_id`. Required by `Tiannara.CI.Correlation.Client` and
  `Tiannara.Omega.CIWiring`; must return `{:error, :not_found}` (not a bare
  atom) when no matching run exists yet so callers can retry.
  """
  @callback find_run_by_correlation(config :: map(), correlation_id :: String.t()) ::
              {:ok, run_id :: term()} | {:error, :not_found} | {:error, term()}
end
