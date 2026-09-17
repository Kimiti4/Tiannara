defmodule Tiannara.ASC.MetaScienceTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.MetaScienceEngine

  @moduletag :integration

  setup do
    case MetaScienceEngine.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
    :ok
  end

  defp inject_phase6_data(data) do
    payload = %{
      source_campaign: :phase6,
      result: data,
      timestamp: DateTime.utc_now()
    }
    send(MetaScienceEngine, {:executive_bus_message, %{type: "campaign.phase7.input", payload: payload}})
  end

  describe "MetaScienceEngine" do
    test "starts and reports initial state" do
      score = MetaScienceEngine.methodology_score()
      assert is_float(score)
      assert score >= 0.0 and score <= 1.0
    end

    test "analyzes Phase 6 results and produces recommendations" do
      inject_phase6_data(%{
        strategy: :hypothesis_first,
        discoveries: 5,
        validated: 2,
        outcomes: [:confirmed, :confirmed, :refuted, :confirmed, :inconclusive],
        hypothesis_types: [:causal, :correlational, :causal],
        cycle_time_ms: 5000
      })

      MetaScienceEngine.analyze()
      Process.sleep(500)

      recs = MetaScienceEngine.recommendations()
      assert is_list(recs)

      score = MetaScienceEngine.methodology_score()
      assert score >= 0.0 and score <= 1.0
    end

    test "detects confirmation bias" do
      inject_phase6_data(%{
        strategy: :default,
        discoveries: 20,
        validated: 18,
        outcomes: List.duplicate(:confirmed, 19) ++ [:inconclusive],
        hypothesis_types: [:causal],
        cycle_time_ms: 3000
      })

      MetaScienceEngine.analyze()
      Process.sleep(500)

      recs = MetaScienceEngine.recommendations()

      bias_rec = Enum.find(recs, &(&1.type == :confirmation_bias))
      assert bias_rec != nil
    end

    test "detects low validation rate bottleneck" do
      inject_phase6_data(%{
        strategy: :exploratory,
        discoveries: 30,
        validated: 3,
        outcomes: List.duplicate(:inconclusive, 27) ++ List.duplicate(:confirmed, 3),
        hypothesis_types: [:causal, :correlational, :analogical],
        cycle_time_ms: 8000
      })

      MetaScienceEngine.analyze()
      Process.sleep(500)

      recs = MetaScienceEngine.recommendations()

      bottleneck_rec = Enum.find(recs, &(&1.type == :low_validation_rate))
      assert bottleneck_rec != nil
    end

    test "history accumulates across analyses" do
      MetaScienceEngine.analyze()
      Process.sleep(500)

      history = MetaScienceEngine.history()
      assert is_list(history)
    end
  end
end
