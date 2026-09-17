defmodule Tiannara.Forecasting.DecisionSnapshotTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Decision, DecisionSnapshot}
  alias Tiannara.Forecasting.Contracts.Alternative

  defp alt(id, probs, utils) do
    struct!(%Alternative{},
      id: id, label: Atom.to_string(id),
      outcomes: ["up", "down"], probabilities: probs, utilities: utils,
      reversibility: :reversible)
  end

  defp decision do
    Decision.new(
      question: "Should we expand?",
      alternatives: [
        alt(:expand, [0.6, 0.4], [200, -50]),
        alt(:hold, [0.7, 0.3], [50, 20])
      ],
      forecast_refs: ["f1"]
    )
  end

  describe "capture/1" do
    test "freezes the decision-time alternatives as plain maps" do
      snap = DecisionSnapshot.capture(decision())
      assert snap.decision_id != nil
      assert snap.question == "Should we expand?"
      assert length(snap.alternatives) == 2
      alt0 = Enum.find(snap.alternatives, &(&1.id == :expand))
      assert alt0.probabilities == [0.6, 0.4]
      assert alt0.utilities == [200, -50]
      assert alt0.reversibility == :reversible
    end

    test "records unknown probability positions for information sufficiency" do
      d = Decision.new(question: "Q", alternatives: [alt(:unk, :unknown, [1, 2])])
      snap = DecisionSnapshot.capture(d)
      assert {:unk, :unknown_distribution} in snap.unknowns
    end
  end

  describe "consistent?/2" do
    test "true when the decision still matches its snapshot" do
      d = decision()
      snap = DecisionSnapshot.capture(d)
      assert DecisionSnapshot.consistent?(snap, d)
    end

    test "false when the decision probabilities were rewritten (hindsight)" do
      d = decision()
      snap = DecisionSnapshot.capture(d)

      rewritten =
        Decision.new(
          question: d.question,
          alternatives: [
            alt(:expand, [0.99, 0.01], [200, -50]),
            alt(:hold, [0.7, 0.3], [50, 20])
          ],
          forecast_refs: d.forecast_refs
        )

      refute DecisionSnapshot.consistent?(snap, rewritten)
    end
  end
end