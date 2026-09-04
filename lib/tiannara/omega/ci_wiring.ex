defmodule Tiannara.Omega.CIWiring do
  @moduledoc """
  Wires a correlation-aware CI client into the Ω improvement pipeline.

  INVARIANT: A CI result must NEVER be attributed to an improvement proposal
  unless its correlation identity is proven. This eliminates the concurrent-
  dispatch race where "latest run" could belong to a different proposal.

  Flow:
      generate correlation_id
        → dispatch workflow with correlation_id in inputs
        → find the run whose correlation_id matches (NOT "latest run")
        → poll that run to completion
        → fetch its conclusion
        → return a result provably tied to this proposal

  Correlation-aware providers must implement `find_run_by_correlation/2` in
  addition to the `Tiannara.CI.Provider` callbacks.

  Constitutional basis: Verification First, "Support reproducibility",
  "Maintain audit trails", Security by design.
  """

  @doc "Generate a unique correlation token."
  def generate_correlation_id do
    :crypto.strong_rand_bytes(12) |> Base.encode16(case: :lower)
  end

  @doc """
  Validates a proposal through CI using correlation-token matching. Returns
  `{:ok, result}` where `result` ties `proposal_id`, `correlation_id`,
  `run_id`, and `conclusion` together.
  """
  def validate(proposal, provider, config, opts \\ []) do
    correlation_id = Keyword.get(opts, :correlation_id) || generate_correlation_id()
    poll_interval = Keyword.get(opts, :poll_interval, 50)
    timeout = Keyword.get(opts, :timeout, 5_000)

    with {:ok, _dispatch} <- dispatch(provider, config, proposal, correlation_id),
         {:ok, run_id} <- find_run(provider, config, correlation_id, timeout, poll_interval),
         {:ok, _status} <- await_completion(provider, config, run_id, timeout, poll_interval),
         {:ok, conclusion} <- provider.run_conclusion(config, run_id) do
      {:ok,
       %{
         proposal_id: Map.get(proposal, :id),
         correlation_id: correlation_id,
         run_id: run_id,
         conclusion: conclusion
       }}
    end
  end

  # --- internals ----------------------------------------------------------

  defp dispatch(provider, config, proposal, correlation_id) do
    inputs = %{
      correlation_id: correlation_id,
      proposal_id: Map.get(proposal, :id),
      lineage_id: Map.get(proposal, :lineage_id)
    }

    provider.trigger_workflow(config, inputs)
  end

  defp find_run(provider, config, correlation_id, timeout, poll_interval) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_find_run(provider, config, correlation_id, deadline, poll_interval)
  end

  defp do_find_run(provider, config, correlation_id, deadline, poll_interval) do
    case provider.find_run_by_correlation(config, correlation_id) do
      {:ok, run_id} ->
        {:ok, run_id}

      {:error, :not_found} ->
        if System.monotonic_time(:millisecond) > deadline do
          {:error, :correlation_timeout}
        else
          Process.sleep(poll_interval)
          do_find_run(provider, config, correlation_id, deadline, poll_interval)
        end

      {:error, _} = e ->
        e
    end
  end

  defp await_completion(provider, config, run_id, timeout, poll_interval) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_await(provider, config, run_id, deadline, poll_interval)
  end

  defp do_await(provider, config, run_id, deadline, poll_interval) do
    case provider.run_status(config, run_id) do
      {:ok, :done} ->
        {:ok, :done}

      {:ok, status} when status in [:pending, :running] ->
        if System.monotonic_time(:millisecond) > deadline do
          {:error, :status_timeout}
        else
          Process.sleep(poll_interval)
          do_await(provider, config, run_id, deadline, poll_interval)
        end

      {:ok, other} ->
        {:error, {:unexpected_status, other}}

      {:error, _} = e ->
        e
    end
  end
end
