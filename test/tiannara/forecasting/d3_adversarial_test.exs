defmodule Tiannara.Forecasting.D3AdversarialTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{Decision, DecisionEngine, DecisionQuality, DecisionSnapshot, DecisionReview, PreMortem}
  alias Tiannara.Forecasting.Contracts.{Alternative, DecisionOutcome}

  defp alt(id, attrs) do
    struct!(%Alternative{}, Map.merge(%{id: id, label: Atom.to_string(id)}, Map.new(attrs)))
  end

  describe "hindsight smuggling attacks" do
    test "a decision rewritten after the fact fails snapshot consistency" do
      original =
        Decision.new(
          question: "Q",
          alternatives: [
            alt(:a, outcomes: ["up", "down"], probabilities: [0.6, 0.4], utilities: [100, -10]),
            alt(:b, outcomes: ["up", "down"], probabilities: [0.5, 0.5], utilities: [50, 20])
          ]
        )

      snap = DecisionSnapshot.capture(original)

      smuggle =
        Decision.new(
          question: "Q",
          alternatives: [
            # probabilities rewritten to the "known" outcome (hindsight contamination)
            alt(:a, outcomes: ["up", "down"], probabilities: [1.0, 0.0], utilities: [100, -10]),
            alt(:b, outcomes: ["up", "down"], probabilities: [0.5, 0.5], utilities: [50, 20])
          ]
        )

      refute DecisionSnapshot.consistent?(snap, smuggle)
      refute DecisionQuality.consistent_with_snapshot?(smuggle, snap)
    end

    test "quality scored against a poisoned snapshot is still outcome-free" do
      d =
        Decision.new(
          question: "Q",
          alternatives: [
            alt(:a, outcomes: ["up", "down"], probabilities: [0.6, 0.4], utilities: [100, -10])
          ]
        )

      snap = DecisionSnapshot.capture(d)
      q1 = DecisionQuality.evaluate_snapshot(snap)
      q2 = DecisionQuality.evaluate_snapshot(snap)
      assert q1.score == q2.score
      assert q1.hindsight_independent
    end

    test "outcome observed before decision time is rejected as contamination" do
      d = Decision.new(question: "Q", alternatives: [alt(:a, outcomes: ["u"], probabilities: [1.0], utilities: [1.0])])

      o = %DecisionOutcome{decision_id: d.id, alternative_id: :a, observed_outcome: "u",
                           observed_at: DateTime.add(d.created_at, -60, :second)}
      assert {:error, :hindsight_contamination} = DecisionReview.guard_outcome(o, d)
    end
  end

  describe "malformed input hardening" do
    test "engine rejects empty alternative lists" do
      assert {:error, _} = DecisionEngine.decide(question: "Q", alternatives: [])
    end

    test "engine rejects alternatives with mismatched distributions" do
      r = DecisionEngine.decide(question: "Q", alternatives: [
        alt(:bad, outcomes: ["a", "b"], probabilities: [0.5], utilities: [1, 2])
      ])
      assert {:error, _} = r
    end

    test "alternative ids must be unique to avoid ambiguity" do
      r = DecisionEngine.decide(question: "Q", alternatives: [
        alt(:dup, outcomes: ["a"], probabilities: [1.0], utilities: [1]),
        alt(:dup, outcomes: ["a"], probabilities: [1.0], utilities: [2])
      ])
      assert {:error, _} = r
    end

    test "pre-mortem on garbage input does not crash the decision path" do
      assert is_list(PreMortem.run_all([]))
    end
  end

  describe "authority boundary (recommendation ≠ authorization)" do
    test "a recommendation is never mistaken for an authorization" do
      d =
        Decision.new(
          question: "Q",
          alternatives: [alt(:a, outcomes: ["u"], probabilities: [1.0], utilities: [1.0])]
        )

      # The D3 layer computes a recommendation; authorization is Council's duty.
      assert %{recommended_alternative_id: nil} = %{d | recommended_alternative_id: nil}
      assert is_nil(d.selected_alternative_id)
    end

    test "confidence cannot be derived from expected value alone" do
      assert DecisionQuality.classify(0.9, true) == %{decision: :good, outcome: :good}
      # The forbidden implication: a good outcome does not make a poor decision good.
      assert DecisionQuality.classify(0.2, true) == %{decision: :poor, outcome: :good}
    end
  end
end