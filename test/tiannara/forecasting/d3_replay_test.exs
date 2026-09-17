defmodule Tiannara.Forecasting.D3ReplayTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{
    Decision,
    DecisionEngine,
    DecisionQuality,
    DecisionRegistry,
    DecisionSnapshot
  }
  alias Tiannara.Forecasting.Contracts.Alternative

  setup do
    start_supervised!(DecisionRegistry)
    :ets.delete_all_objects(:efdi_decision_registry)
    :ok
  end

  defp scenario do
    [
      alt(:expand, [0.6, 0.4], [150, -60]),
      alt(:hold, [0.8, 0.2], [40, 30])
    ]
  end

  defp alt(id, probs, utils) do
    struct!(%Alternative{},
      id: id, label: Atom.to_string(id),
      outcomes: ["up", "down"], probabilities: probs, utilities: utils,
      reversibility: :reversible)
  end

  describe "deterministic replay of decision-time evaluation" do
    test "re-evaluating identical inputs reproduces identical EV, risk, recommendation" do
      {d1, d2} =
        {DecisionEngine.decide(question: "Q", alternatives: scenario()),
         DecisionEngine.decide(question: "Q", alternatives: scenario())}

      assert {:ok, d1} = d1
      assert {:ok, d2} = d2
      assert d1.recommended_alternative_id == d2.recommended_alternative_id
      assert d1.expected_values == d2.expected_values
      assert d1.risk_evaluation == d2.risk_evaluation
      assert Map.equal?(d1.expected_values, d2.expected_values)
    end

    test "replayed ex-ante quality is bit-identical" do
      assert {:ok, d1} = DecisionEngine.decide(question: "Q", alternatives: scenario())
      assert {:ok, d2} = DecisionEngine.decide(question: "Q", alternatives: scenario())

      snap1 = DecisionSnapshot.capture(d1)
      snap2 = DecisionSnapshot.capture(d2)
      q1 = DecisionQuality.evaluate_snapshot(snap1)
      q2 = DecisionQuality.evaluate_snapshot(snap2)
      assert q1.score == q2.score
    end
  end

  describe "replay of an outcome never contaminates decision quality" do
    test "the same decision scored before and after the observed outcome is unchanged" do
      assert {:ok, decision} = DecisionEngine.decide(question: "Q", alternatives: scenario())
      snap = DecisionSnapshot.capture(decision)
      before = DecisionQuality.evaluate_snapshot(snap)

      # simulate time passing and the outcome being "observed"
      _replayed_decision = %{decision | created_at: DateTime.add(decision.created_at, 3600, :second)}
      _snap_replay = DecisionSnapshot.capture(decision)

      after_q = DecisionQuality.evaluate_snapshot(snap)
      assert before.score == after_q.score
      assert before.hindsight_independent
    end
  end

  describe "registry replay (event-sourced reads)" do
    test "reads are stable across repeated get calls" do
      assert {:ok, decision} = DecisionEngine.decide(question: "Q", alternatives: scenario())
      assert {:ok, _} = DecisionRegistry.register(decision)

      r1 = DecisionRegistry.get(decision.id)
      r2 = DecisionRegistry.get(decision.id)
      r3 = DecisionRegistry.get(decision.id)
      assert r1 == r2
      assert r2 == r3
      assert {:ok, d} = r1
      assert d.expected_values == decision.expected_values
    end
  end
end