defmodule Tiannara.ASC.Civilization.ChaosTest do
  use ExUnit.Case, async: false

  @moduletag :chaos

  setup do
    for mod <- [
      Tiannara.ASC.Civilization.Director,
      Tiannara.ASC.Civilization.WorldModel,
      Tiannara.ASC.Civilization.GlobalRiskEngine,
      Tiannara.ASC.Civilization.SustainabilityEngine,
      Tiannara.ASC.Civilization.ConstitutionalGovernanceEngine,
      Tiannara.ASC.Civilization.FeedbackAggregator
    ] do
      case mod.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end
    :ok
  end

  test "handles empty world state gracefully" do
    {:ok, risk} = Tiannara.ASC.Civilization.GlobalRiskEngine.assess(%{})
    assert risk.overall_risk >= 0.0

    {:ok, sustainability} = Tiannara.ASC.Civilization.SustainabilityEngine.evaluate(%{})
    assert sustainability.score >= 0.0
  end

  test "governance engine gates high-impact decisions" do
    decisions = [
      %{id: "d1", action: "Low impact", requires_human_approval: false},
      %{id: "d2", action: "High impact", requires_human_approval: true},
      %{id: "d3", action: "Critical impact", requires_human_approval: true}
    ]

    {:ok, result} = Tiannara.ASC.Civilization.ConstitutionalGovernanceEngine.review(decisions)

    assert result.auto_approved == 1
    assert result.requires_human == 2
    assert length(result.gated_decisions) == 2
  end

  test "feedback aggregator handles missing data" do
    Tiannara.ASC.Civilization.FeedbackAggregator.aggregate_and_feed_back(%{cycle: 1})
    Process.sleep(500)

    history = Tiannara.ASC.Civilization.FeedbackAggregator.feedback_history()
    assert is_list(history)
  end

  test "civilization director reports stats" do
    stats = Tiannara.ASC.Civilization.Director.stats()
    assert stats.cycles >= 0
    assert is_integer(stats.decisions_made)
  end
end
