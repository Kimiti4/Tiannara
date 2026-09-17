defmodule Tiannara.Forecasting.DecisionEngineTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{DecisionEngine}
  alias Tiannara.Forecasting.Contracts.Alternative

  defp alt(attrs) do
    struct!(%Alternative{}, Map.merge(%{id: :a, label: "A"}, Map.new(attrs)))
  end

  describe "expected_value/1" do
    test "computes probability-weighted utility" do
      a = alt(outcomes: ["up", "down"], probabilities: [0.7, 0.3], utilities: [100, -50])
      assert_in_delta(DecisionEngine.expected_value(a), 55.0, 1.0e-9)
    end

    test "returns :unknown for unknown probabilities" do
      a = alt(outcomes: ["up", "down"], probabilities: :unknown, utilities: [100, -50])
      assert DecisionEngine.expected_value(a) == :unknown
    end

    test "returns :unknown when probabilities and utilities are mismatched" do
      a = alt(outcomes: ["up", "down"], probabilities: [0.7, 0.3], utilities: [100])
      assert DecisionEngine.expected_value(a) == :unknown
    end
  end

  describe "variance/1 and stddev/1" do
    test "variance of a deterministic alternative is 0" do
      a = alt(outcomes: ["up"], probabilities: [1.0], utilities: [50])
      assert_in_delta(DecisionEngine.variance(a), 0.0, 1.0e-9)
    end

    test "variance matches hand computation" do
      a = alt(outcomes: ["up", "down"], probabilities: [0.5, 0.5], utilities: [10, 0])
      # EV=5, var = 0.5*25 + 0.5*25 = 25
      assert_in_delta(DecisionEngine.variance(a), 25.0, 1.0e-9)
      assert_in_delta(DecisionEngine.stddev(a), 5.0, 1.0e-9)
    end
  end

  describe "decide/1" do
    test "selects the highest-ev alternative as recommendation" do
      a1 = alt(id: :invest, label: "Invest", outcomes: ["win", "lose"],
               probabilities: [0.6, 0.4], utilities: [200, -100])
      a2 = alt(id: :wait, label: "Wait", outcomes: ["win", "lose"],
               probabilities: [0.5, 0.5], utilities: [50, 10])

      assert {:ok, d} = DecisionEngine.decide(question: "Should we invest?", alternatives: [a1, a2])
      assert d.recommended_alternative_id == :invest
      assert_in_delta(d.expected_values[:invest], 80.0, 1.0e-9)
      assert_in_delta(d.expected_values[:wait], 30.0, 1.0e-9)
    end

    test "records expected_value and risk for each alternative" do
      a1 = alt(id: :x, label: "X", outcomes: ["a", "b"], probabilities: [1.0, 0.0], utilities: [10, 0])
      assert {:ok, d} = DecisionEngine.decide(question: "Q", alternatives: [a1])
      assert is_number(d.expected_values[:x])
      assert is_number(d.risk_evaluation[:x][:risk_score])
    end

    test "returns error for missing question" do
      a = alt(id: :x, outcomes: ["a"], probabilities: [1.0], utilities: [1.0])
      assert {:error, :missing_question} = DecisionEngine.decide(alternatives: [a])
    end

    test "recommendation is nil when all evs are unknown" do
      a = alt(id: :unk, outcomes: ["a", "b"], probabilities: :unknown, utilities: [1, 2])
      assert {:ok, d} = DecisionEngine.decide(question: "Q", alternatives: [a])
      assert d.recommended_alternative_id == nil
    end
  end
end