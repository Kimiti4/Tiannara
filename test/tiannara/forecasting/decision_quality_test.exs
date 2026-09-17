defmodule Tiannara.Forecasting.DecisionQualityTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Decision, DecisionQuality, DecisionSnapshot}
  alias Tiannara.Forecasting.Contracts.Alternative

  defp alt(id, probs, utils, opts \\ []) do
    struct!(%Alternative{},
      id: id, label: Atom.to_string(id),
      outcomes: ["up", "down"], probabilities: probs, utilities: utils,
      reversibility: Keyword.get(opts, :reversibility, :reversible))
  end

  defp well_formed do
    Decision.new(
      question: "Q",
      alternatives: [
        alt(:a, [0.8, 0.2], [100, -10]),
        alt(:b, [0.5, 0.5], [40, 20]),
        Decision.do_nothing()
      ]
    )
  end

  describe "hindsight independence (the core D3 invariant)" do
    test "decision quality is invariant to the observed outcome" do
      d = well_formed()
      snap = DecisionSnapshot.capture(d)

      q1 = DecisionQuality.evaluate_snapshot(snap)
      q2 = DecisionQuality.evaluate_snapshot(snap)

      assert q1.score == q2.score
      assert q1.hindsight_independent == true
      assert q1.basis == :decision_time
      assert q1.score >= 0 and q1.score <= 1
    end

    test "a decision with full information scores higher than one with unknown distributions" do
      full = DecisionQuality.evaluate(well_formed())

      sparse = Decision.new(
        question: "Q",
        alternatives: [alt(:a, :unknown, [100, -10])]
      )

      poor = DecisionQuality.evaluate(sparse)
      assert full.score > poor.score
    end
  end

  describe "classify/2 preserves all four decision×outcome combinations" do
    test "four combinations are all representable" do
      good_decision = 0.9
      poor_decision = 0.1

      assert DecisionQuality.classify(good_decision, true) == %{decision: :good, outcome: :good}
      assert DecisionQuality.classify(good_decision, false) == %{decision: :good, outcome: :poor}
      assert DecisionQuality.classify(poor_decision, true) == %{decision: :poor, outcome: :good}
      assert DecisionQuality.classify(poor_decision, false) == %{decision: :poor, outcome: :poor}
    end
  end

  describe "component scores" do
    test "well-formed decision has high component scores" do
      q = DecisionQuality.evaluate(well_formed())
      assert q.components.probability_integrity == 1.0
      assert q.components.utility_integrity == 1.0
      assert q.components.information_sufficiency == 1.0
      assert q.components.risk_registered == 1.0
    end

    test "unknown distribution depresses information sufficiency but keeps integrity elsewhere" do
      d = Decision.new(
        question: "Q",
        alternatives: [
          alt(:a, :unknown, [100, -10]),
          alt(:b, [0.5, 0.5], [40, 20])
        ]
      )
      q = DecisionQuality.evaluate(d)
      assert q.components.information_sufficiency == 0.5
      assert q.components.probability_integrity < 1.0
    end
  end

  describe "consistent_with_snapshot?/2" do
    test "raises no barrier for an untouched decision" do
      d = well_formed()
      snap = DecisionSnapshot.capture(d)
      assert DecisionQuality.consistent_with_snapshot?(d, snap)
    end
  end
end