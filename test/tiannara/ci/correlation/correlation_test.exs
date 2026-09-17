defmodule Tiannara.CI.Correlation.CorrelationTest do
  use ExUnit.Case, async: false

  alias Tiannara.CI.Correlation.{Token, Registry, Verifier, Client}

  @moduletag :ci_correlation

  # A correlation-aware mock provider keyed by correlation_id.
  defmodule CorrelationMockProvider do
    def trigger_workflow(_config, inputs) do
      {:ok, "run-" <> inputs.correlation_id}
    end

    def find_run_by_correlation(_config, correlation_id) do
      {:ok, "run-" <> correlation_id}
    end

    def run_status(_config, _run_id), do: {:ok, :done}

    def run_conclusion(_config, run_id) do
      correlation_id = String.replace_prefix(run_id, "run-", "")
      {:ok, {"result-for-" <> correlation_id, 0}}
    end

    def cancel_run(_config, _run_id), do: :ok
  end

  setup do
    path = Path.join(System.tmp_dir!(), "corr_#{System.unique_integer([:positive])}.log")
    on_exit(fn -> File.rm(path) end)
    {:ok, registry_path: path}
  end

  test "tokens are unique and valid" do
    tokens = for _ <- 1..100, do: Token.generate()
    assert length(Enum.uniq(tokens)) == 100
    assert Enum.all?(tokens, &Token.valid?/1)
  end

  test "dispatch registers a correlation and awaits a verified result", %{registry_path: path} do
    proposal = %{id: :prop_1, lineage_id: :line_1}

    assert {:ok, result} =
             Client.dispatch_and_await(CorrelationMockProvider, %{}, proposal, path,
               poll_interval: 1, timeout: 1_000)

    assert result.proposal_id == :prop_1
    assert result.correlation_id != nil
    assert {"result-for-" <> result.correlation_id, 0} == result.conclusion
  end

  test "10 concurrent proposals each get their own correlated result", %{registry_path: path} do
    proposals = for i <- 1..10, do: %{id: :"prop_#{i}", lineage_id: :"line_#{i}"}

    results =
      proposals
      |> Enum.map(fn proposal ->
        Task.async(fn ->
          Client.dispatch_and_await(CorrelationMockProvider, %{}, proposal, path,
            poll_interval: 1, timeout: 1_000)
        end)
      end)
      |> Enum.map(&Task.await/1)

    assert length(results) == 10

    results
    |> Enum.with_index(1)
    |> Enum.each(fn {{:ok, result}, i} ->
      assert result.proposal_id == :"prop_#{i}"
      assert {"result-for-" <> result.correlation_id, 0} == result.conclusion
    end)

    # All correlation_ids are distinct — no cross-contamination
    corr_ids = Enum.map(results, fn {:ok, r} -> r.correlation_id end)
    assert length(Enum.uniq(corr_ids)) == 10
  end

  test "an unknown correlation_id is rejected", %{registry_path: path} do
    unknown_token = Token.generate()

    assert {:error, :unknown_correlation_id} =
             Verifier.verify_correlation(unknown_token, path)
  end

  test "an invalid token format is rejected", %{registry_path: path} do
    assert {:error, :invalid_correlation_token} =
             Verifier.verify_correlation("not-a-valid-token", path)
  end

  test "a correlation mismatch is rejected", %{registry_path: path} do
    # Dispatch proposal 1
    proposal_1 = %{id: :prop_1, lineage_id: :line_1}
    {:ok, %{correlation_id: cid_1}} =
      Client.dispatch(CorrelationMockProvider, %{}, proposal_1, path)

    # Try to attribute correlation_1's result to proposal 2
    assert {:error, {:correlation_mismatch, _}} =
             Verifier.verify_matches(cid_1, :prop_2, path)
  end

  test "correlation mappings survive restart (durability)", %{registry_path: path} do
    proposal = %{id: :prop_restart, lineage_id: :line_restart}

    {:ok, %{correlation_id: cid}} =
      Client.dispatch(CorrelationMockProvider, %{}, proposal, path)

    # Simulate restart: re-lookup from the durable file
    assert {:ok, record} = Registry.lookup(cid, path)
    assert record.proposal_id == :prop_restart
    assert record.lineage_id == :line_restart
    assert record.status == :dispatched
  end

  test "a completed correlation is recorded as completed", %{registry_path: path} do
    proposal = %{id: :prop_complete, lineage_id: :line_complete}

    {:ok, %{correlation_id: cid}} =
      Client.dispatch(CorrelationMockProvider, %{}, proposal, path)

    Registry.complete(cid, :prop_complete, {"done", 0}, path)

    assert {:ok, record} = Registry.lookup(cid, path)
    assert record.status == :completed
    assert record.result == {"done", 0}
  end
end