defmodule Tiannara.CI.Correlation.Client do
  @moduledoc """
  A correlation-aware CI client. Wraps a CI provider with correlation-token
  handling: dispatch registers a correlation, and fetching a result verifies
  the correlation identity before attribution.

  This is the production-grade replacement for "assume the latest run is
  ours." Every result is proven to belong to its dispatch before attribution.

  Constitutional basis: Verification First, "Support reproducibility",
  "Maintain audit trails", Security by design.
  """

  alias Tiannara.CI.Correlation.{Token, Registry, Verifier}

  @doc """
  Dispatch a CI workflow for a proposal, registering a fresh correlation_id.
  Returns `{:ok, %{correlation_id, run_id}}` or `{:error, reason}`.
  """
  def dispatch(provider, config, proposal, registry_path) do
    correlation_id = Token.generate()

    with :ok <- Registry.register(correlation_id, proposal.id,
                                  Map.get(proposal, :lineage_id), registry_path),
         {:ok, run_id} <- provider.trigger_workflow(config, %{
           correlation_id: correlation_id,
           proposal_id: proposal.id
         }) do
      {:ok, %{correlation_id: correlation_id, run_id: run_id}}
    end
  end

  @doc """
  Dispatch and await a verified result. This is the main entry point: it
  dispatches, polls to completion, verifies the correlation identity, and only
  then attributes the result to the proposal.

  Returns `{:ok, %{correlation_id, run_id, proposal_id, conclusion}}` or
  `{:error, reason}`.
  """
  def dispatch_and_await(provider, config, proposal, registry_path, opts \\ []) do
    with {:ok, %{correlation_id: cid, run_id: rid}} <-
           dispatch(provider, config, proposal, registry_path),
         {:ok, _} <- await_completion(provider, config, cid, opts),
         {:ok, conclusion} <- fetch_verified_result(provider, config, cid, proposal.id, registry_path) do
      {:ok, %{correlation_id: cid, run_id: rid, proposal_id: proposal.id, conclusion: conclusion}}
    end
  end

  # --- internals ----------------------------------------------------------

  defp await_completion(provider, config, correlation_id, opts) do
    poll_interval = Keyword.get(opts, :poll_interval, 50)
    timeout = Keyword.get(opts, :timeout, 5_000)
    deadline = System.monotonic_time(:millisecond) + timeout

    do_await(provider, config, correlation_id, deadline, poll_interval)
  end

  defp do_await(provider, config, correlation_id, deadline, poll_interval) do
    with {:ok, run_id} <- provider.find_run_by_correlation(config, correlation_id),
         {:ok, status} <- provider.run_status(config, run_id) do
      case status do
        :done ->
          {:ok, run_id}

        status when status in [:pending, :running] ->
          if System.monotonic_time(:millisecond) > deadline do
            {:error, :await_timeout}
          else
            Process.sleep(poll_interval)
            do_await(provider, config, correlation_id, deadline, poll_interval)
          end

        other ->
          {:error, {:unexpected_status, other}}
      end
    end
  end

  defp fetch_verified_result(provider, config, correlation_id, proposal_id, registry_path) do
    with {:ok, run_id} <- provider.find_run_by_correlation(config, correlation_id),
         {:ok, conclusion} <- provider.run_conclusion(config, run_id),
         {:ok, _record} <- Verifier.verify_matches(correlation_id, proposal_id, registry_path) do
      Registry.complete(correlation_id, proposal_id, conclusion, registry_path)
      {:ok, conclusion}
    end
  end
end