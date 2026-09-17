defmodule Tiannara.Discovery.PipelineTelemetryContractTest do
  use ExUnit.Case, async: false

  alias Tiannara.Discovery.{DiscoveryEngine, DiscoveryScheduler, PipelineTelemetry}
  alias Tiannara.World.{UnifiedRealityGraph, UnifiedWorldModel}

  defp collect_calls(:earned_knowledge), do: []
  defp collect_calls({:call, {mod, fun, arity}, path}), do: [{mod, fun, arity, path}]

  defp collect_calls(list) when is_list(list) do
    Enum.flat_map(list, &collect_calls/1)
  end

  test "every scheduler key the telemetry reads exists in get_stats/0" do
    assert function_exported?(DiscoveryScheduler, :get_stats, 0)

    stats = DiscoveryScheduler.get_stats()
    assert is_map(stats)

    expected_keys = [
      :total_gaps_detected,
      :total_hypotheses_generated,
      :total_predictions_generated,
      :total_experiments_planned,
      :total_experiments_executed
    ]

    for key <- expected_keys do
      assert Map.has_key?(stats, key),
             "scheduler stat #{inspect(key)} referenced by the pipeline contract is missing"
    end

    for key <- expected_keys do
      assert is_integer(Map.get(stats, key)) and Map.get(stats, key) >= 0
    end
  end

  test "every reader call in the telemetry resolves to a real key on the real surface" do
    calls =
      PipelineTelemetry.readers()
      |> Map.values()
      |> Enum.flat_map(&collect_calls/1)

    refute calls == [], "readers table is empty"

    for {mod, fun, arity, path} <- calls do
      assert function_exported?(mod, fun, arity),
             "reader references #{inspect(mod)}.#{fun}/#{arity}, which does not exist"

      result = apply(mod, fun, [])
      assert is_map(result), "#{inspect(mod)}.#{fun}/0 returned #{inspect(result)}"

      walk =
        Enum.reduce_while(path, result, fn key, acc ->
          if Map.has_key?(acc, key) do
            {:cont, Map.get(acc, key)}
          else
            {:halt, {:missing, key}}
          end
        end)

      case walk do
        {:missing, key} ->
          flunk(
            "reader path #{inspect(path)} references missing key #{inspect(key)} in #{inspect(mod)}.#{fun}/0 result"
          )

        _ ->
          :ok
      end
    end
  end

  test "knowledge integration earns only what is not seeded" do
    assert function_exported?(UnifiedRealityGraph, :query_entities, 1)

    {:ok, seeded_ids} =
      UnifiedRealityGraph.query_entities(
        predicate: fn e -> get_in(e, [:provenance, :origin]) == :epistemic_seed end,
        limit: 100_000
      )

    assert is_list(seeded_ids)

    total =
      UnifiedWorldModel.stats()
      |> Map.get(:entity_count)

    assert is_integer(total)
    assert total >= length(seeded_ids)
  end

  test "all pipeline stages are declared with a reader" do
    for stage <- PipelineTelemetry.stages() do
      assert Map.has_key?(PipelineTelemetry.readers(), stage),
             "stage #{inspect(stage)} has no reader declaration"
    end
  end

  test "seeded pressure reaches the scheduler's real counters within one cycle" do
    before = DiscoveryScheduler.get_stats()

    Tiannara.Discovery.EpistemicSeeder.seed_battery(domain: :contract_test)
    :ok = DiscoveryScheduler.trigger_cycle()

    after_stats = DiscoveryScheduler.get_stats()

    assert after_stats.completed_cycles > before.completed_cycles

    assert after_stats.total_gaps_detected > before.total_gaps_detected,
           "the scheduler detected no gaps from the seeded contradictions; the world-derived report is not feeding the cycle"
  end
end
