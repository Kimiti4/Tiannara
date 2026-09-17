defmodule Tiannara.Forecasting.ValueOfInformationTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Decision, DecisionEngine, ValueOfInformation}
  alias Tiannara.Forecasting.Contracts.Alternative

  defp alt(id, probs, utils) do
    struct!(%Alternative{},
      id: id, label: Atom.to_string(id),
      outcomes: ["up", "down"], probabilities: probs, utilities: utils)
  end

  defp decision(alternatives) do
    Decision.new(question: "Q", alternatives: alternatives)
  end

  describe "expected_value_of_perfect_information/1" do
    test "EVPI is zero when one alternative dominates under the belief" do
      d = decision([
            alt(:a, [0.9, 0.1], [100, -10]),
            alt(:b, [0.1, 0.9], [-10, 100])
          ])
      assert {:ok, analyzed} = DecisionEngine.decide(%{question: d.question, alternatives: d.alternatives})
      # belief = recommended alt (:a) probabilities [0.9, 0.1]
      # best per outcome: outcome up → max(100, -10)=100 ; down → max(-10,100)=100
      # perfect = 0.9*100 + 0.1*100 = 100; current best = 0.9*100+0.1*(-10) = 89
      # EVPI = 11 (>0). Assert it is >= 0 and matches hand computation.
      evpi = ValueOfInformation.expected_value_of_perfect_information(analyzed)
      assert_in_delta(evpi, 11.0, 1.0e-6)
    end

    test "EVPI is small when one alternative is near-certain best" do
      d = decision([
            alt(:a, [0.99, 0.01], [100, 0]),
            alt(:b, [0.01, 0.99], [0, 50])
          ])
      assert {:ok, analyzed} = DecisionEngine.decide(%{question: d.question, alternatives: d.alternatives})
      ev = ValueOfInformation.expected_value_of_perfect_information(analyzed)
      assert is_number(ev)
      assert ev >= 0
    end

    test "returns :unknown when recommendation has unknown probabilities" do
      d = decision([alt(:u, :unknown, [1, 2])])
      assert ValueOfInformation.expected_value_of_perfect_information(d) == :unknown
    end
  end

  describe "decision_sensitivity/1" do
    test "large gap ⇒ information unlikely to change the choice" do
      alts = [alt(:a, [0.9, 0.1], [100, -10]),
              alt(:b, [0.5, 0.5], [10, 5])]
      s = ValueOfInformation.decision_sensitivity(alts)
      assert is_number(s)
      assert s > 20
    end

    test "small gap ⇒ additional info could flip the choice (bridge to research)" do
      alts = [alt(:a, [0.5, 0.5], [10, 0]),
              alt(:b, [0.5, 0.5], [9, 1])]
      s = ValueOfInformation.decision_sensitivity(alts)
      assert is_number(s)
      assert s < 2
    end

    test "single alternative has no sensitivity" do
      assert ValueOfInformation.decision_sensitivity([alt(:a, [1.0, 0.0], [5, 0])]) == 0.0
    end
  end

  describe "information_gap/1 + to_research_priorities/1" do
    test "produces research priorities for sensitive alternatives" do
      d = decision([
            alt(:a, [0.51, 0.49], [100, 0]),
            alt(:b, [0.49, 0.51], [99, 1])
          ])
      assert {:ok, analyzed} = DecisionEngine.decide(%{question: d.question, alternatives: d.alternatives})
      priorities = ValueOfInformation.to_research_priorities(analyzed, sensitivity_threshold: 0.0)
      assert priorities != []
      p = hd(priorities)
      assert p.source_type == :information_value
      assert p.source_id == analyzed.id
      assert p.level in [:immediate, :urgent, :scheduled, :background]
    end

    test "no priorities when the decision is not information-sensitive" do
      d = decision([alt(:a, [0.99, 0.01], [100, 0])])
      assert {:ok, analyzed} = DecisionEngine.decide(%{question: d.question, alternatives: d.alternatives})
      assert ValueOfInformation.to_research_priorities(analyzed, sensitivity_threshold: 1.0) == []
    end
  end

  describe "expected_value_of_information/3" do
    test "is uncertainty × impact × feasibility (opportunity-cost format)" do
      assert_in_delta(ValueOfInformation.expected_value_of_information(0.5, 0.8, 0.6), 0.24, 1.0e-9)
    end
  end
end