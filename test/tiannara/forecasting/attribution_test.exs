defmodule Tiannara.Forecasting.AttributionTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Decision, Attribution}
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
    %{d | selected_alternative_id: :bet}
  end

  defp outcome(d, alt_id, obs, at \\ nil) do
    %DecisionOutcome{decision_id: d.id, alternative_id: alt_id, observed_outcome: obs,
                     observed_at: at || DateTime.utc_now()}
  end

  test "default status is NOT_ATTRIBUTED with no evidence" do
    r = Attribution.analyze(decision(), [], n_min: 3)
    assert r.status == :not_attributed
    assert r.repeat_count == 0
  end

  test "single outcome is never attributed, regardless of outcome goodness" do
    d = decision()
    r = Attribution.analyze(d, [outcome(d, :bet, "win")], n_min: 3, skill_margin: 0.1)
    assert r.status == :not_attributed
  end

  test "BAD OUTCOME does not imply BAD DECISION attribution" do
    d = decision()
    one = outcome(d, :bet, "lose")
    repeated = List.duplicate(one, 5)
    r = Attribution.analyze(d, repeated, n_min: 3)
    assert r.status in [:mixed, :likely_luck]
    refute r.status == :likely_skill
  end

  test "repeated wins above threshold can be attributed to likely skill" do
    # expected value of :bet = 40, actual win = 100 → positive delta
    d = decision()
    outs = List.duplicate(outcome(d, :bet, "win"), 5)
    r = Attribution.analyze(d, outs, n_min: 3, skill_margin: 0.1, skill_consistency: 0.6)
    assert r.status == :likely_skill
  end

  test "repeated losses below threshold are at most mixed/luck, never skill" do
    d = decision()
    outs = List.duplicate(outcome(d, :bet, "lose"), 5)
    r = Attribution.analyze(d, outs, n_min: 3, skill_margin: 0.1, skill_consistency: 0.6)
    assert r.status in [:mixed, :likely_luck]
  end

  test "thresholds carry provenance, not hidden constants" do
    r = Attribution.analyze(decision(), [], n_min: 5, skill_margin: 0.2)
    assert r.thresholds_provenance.n_min == [5, :repeat_count_evidence_threshold]
    assert r.thresholds_provenance.skill_margin == [0.2, :mean_delta_gate]
  end
end