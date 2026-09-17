defmodule Tiannara.Forecasting.AlternativeHistoryTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{AlternativeHistory, Decision, Counterfactual}
  alias Tiannara.Forecasting.Contracts.{Alternative, InterventionSpec}

  defp alt(id, probs, utils) do
    struct!(%Alternative{},
      id: id, label: Atom.to_string(id),
      outcomes: ["win", "lose"], probabilities: probs, utilities: utils,
      reversibility: :reversible)
  end

  defp decision do
    Decision.new(
      question: "Q",
      alternatives: [
        alt(:bet, [0.6, 0.4], [100, -50]),
        alt(:fold, [0.9, 0.1], [5, 0])
      ]
    )
  end

  test "bundle always includes the no-action alternative" do
    b = AlternativeHistory.new(decision())
    kinds = b.alternatives |> Enum.map(& &1.intervention.kind)
    assert :do_nothing in kinds
    assert b.includes_do_nothing
    assert b.baseline_state_ref =~ "baseline_"
  end

  test "bundle is bounded by max_alternatives with deterministic exclusion records" do
    d = decision()
    b = AlternativeHistory.new(d, max_alternatives: 1)
    assert length(b.alternatives) <= 1
    assert length(b.excluded_alternatives) >= 1
    reasons = Enum.map(b.excluded_alternatives, & &1.reason)
    assert :max_alternatives_exceeded in reasons
  end

  test "adding beyond the bound returns an error" do
    b = AlternativeHistory.new(decision(), max_alternatives: 1)
    cf = Counterfactual.new(%{intervention: %InterventionSpec{kind: :do_nothing}})
    assert {:error, :alternatives_exceeded} = AlternativeHistory.add_alternative(b, cf)
  end

  test "every bundle element is a non-observed counterfactual record" do
    b = AlternativeHistory.new(decision())
    Enum.each(b.alternatives, fn cf ->
      refute cf.status == :observed
    end)
  end
end