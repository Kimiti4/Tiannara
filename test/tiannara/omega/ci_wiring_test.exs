defmodule Tiannara.Omega.CIWiringTest do
  use ExUnit.Case, async: true

  alias Tiannara.Omega.CIWiring

  @moduletag :ci_correlation

  # A correlation-aware mock provider: run_id is DERIVED from the correlation_id,
  # proving each proposal is matched to its own run (never "latest run").
  defmodule MockCorrelationProvider do
    def trigger_workflow(_config, inputs) do
      if pid = Process.get(:ci_notify), do: send(pid, {:dispatched, inputs.correlation_id})
      {:ok, :dispatched}
    end

    def find_run_by_correlation(_config, correlation_id) do
      {:ok, "run-" <> correlation_id}
    end

    def run_status(_config, _run_id), do: {:ok, :done}

    def run_conclusion(_config, run_id) do
      # Echo the run_id so the test can verify the correlation held.
      {:ok, {"success for " <> run_id, 0}}
    end

    def cancel_run(_config, _run_id), do: :ok
  end

  test "correlation IDs are unique" do
    ids = for _ <- 1..100, do: CIWiring.generate_correlation_id()
    assert length(Enum.uniq(ids)) == 100
  end

  test "a proposal result is tied to its own correlation identity" do
    proposal = %{id: :prop_1}

    assert {:ok, result} =
             CIWiring.validate(proposal, MockCorrelationProvider, %{},
               timeout: 1_000, poll_interval: 1)

    assert result.proposal_id == :prop_1
    assert result.run_id == "run-" <> result.correlation_id

    {output, 0} = result.conclusion
    assert output == "success for run-" <> result.correlation_id
  end

  test "10 concurrent proposals each receive their own correlated result" do
    proposals = for i <- 1..10, do: %{id: :"prop_#{i}"}

    results =
      proposals
      |> Enum.map(fn p ->
        Task.async(fn ->
          CIWiring.validate(p, MockCorrelationProvider, %{}, timeout: 1_000, poll_interval: 1)
        end)
      end)
      |> Enum.map(&Task.await/1)

    assert length(results) == 10

    # Each result is tied to its own proposal + correlation + run.
    results
    |> Enum.with_index(1)
    |> Enum.each(fn {{:ok, result}, i} ->
      assert result.proposal_id == :"prop_#{i}"
      assert result.run_id == "run-" <> result.correlation_id

      {output, 0} = result.conclusion
      assert output == "success for run-" <> result.correlation_id
    end)

    # All correlation IDs are distinct — no cross-contamination.
    corr_ids = Enum.map(results, fn {:ok, r} -> r.correlation_id end)
    assert length(Enum.uniq(corr_ids)) == 10
  end
end
