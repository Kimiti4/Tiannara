defmodule Tiannara.Forecasting.DecisionReviewTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Decision, DecisionReview}
  alias Tiannara.Forecasting.Contracts.{Alternative, DecisionOutcome}

  defp alt(id, probs, utils) do
    struct!(%Alternative{},
      id: id, label: Atom.to_string(id),
      outcomes: ["win", "lose"], probabilities: probs, utilities: utils,
      reversibility: :reversible)
  end

  defp decision do
    d = Decision.new(
      question: "Q",
      alternatives: [alt(:bet, [0.6, 0.4], [100, -50]), alt(:fold, [0.9, 0.1], [5, 0])]
    )
    %{d | selected_alternative_id: :bet,
          expected_values: %{bet: 40.0, fold: 4.5},
          risk_evaluation: %{bet: %{expected_value: 40.0, variance: 34.0, stddev: 5.83, risk_score: 0.5},
                             fold: %{expected_value: 4.5, variance: 0.25, stddev: 0.5, risk_score: 0.1}}}
  end

  describe "postmortem/2" do
    test "produces a structured review without luck/skill attribution" do
      d = decision()
      o = %DecisionOutcome{decision_id: d.id, alternative_id: :bet, observed_outcome: "lose",
                           observed_at: DateTime.utc_now()}

      pm = DecisionReview.postmortem(d, o)
      assert pm.observed == "lose"
      assert pm.attribution == :not_attributed
      assert pm.decision_id == d.id
    end
  end

  describe "guard_outcome/2" do
    test "accepts outcomes observed after the decision" do
      d = Decision.new(question: "Q", alternatives: [alt(:a, [0.5, 0.5], [1, 1])])
      o = %DecisionOutcome{decision_id: d.id, alternative_id: :a, observed_outcome: "win",
                           observed_at: DateTime.add(DateTime.utc_now(), 1, :second)}
      assert {:ok, _} = DecisionReview.guard_outcome(o, d)
    end

    test "rejects outcomes observed before the decision (hindsight contamination)" do
      d = Decision.new(question: "Q", alternatives: [alt(:a, [0.5, 0.5], [1, 1])])
      o = %DecisionOutcome{decision_id: d.id, alternative_id: :a, observed_outcome: "win",
                           observed_at: DateTime.add(d.created_at, -1, :second)}
      assert {:error, :hindsight_contamination} = DecisionReview.guard_outcome(o, d)
    end
  end

  describe "decision_outcome/2" do
    test "pairs decision, outcome, and hindsight-independent quality" do
      d = decision()
      o = %DecisionOutcome{decision_id: d.id, alternative_id: :bet, observed_outcome: "lose",
                           observed_at: DateTime.utc_now()}

      result = DecisionReview.decision_outcome(d, o)
      assert result.decision.id == d.id
      assert result.outcome.observed_outcome == "lose"
      assert result.quality.hindsight_independent == true
      assert result.postmortem.attribution == :not_attributed
    end
  end
end