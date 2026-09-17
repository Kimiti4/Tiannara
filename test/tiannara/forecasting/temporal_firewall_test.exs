defmodule Tiannara.Forecasting.TemporalFirewallTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.{Decision, DecisionSnapshot, TemporalFirewall, Counterfactual}
  alias Tiannara.Forecasting.Contracts.{Alternative, DecisionOutcome, InterventionSpec}

  defp alt(id, probs, utils) do
    struct!(%Alternative{},
      id: id, label: Atom.to_string(id),
      outcomes: ["win", "lose"], probabilities: probs, utilities: utils,
      reversibility: :reversible)
  end

  test "firewall is a first-class certification property, intact for posterior outcomes" do
    d = Decision.new(question: "Q", alternatives: [alt(:a, [0.5, 0.5], [1, 1])])
    snap = DecisionSnapshot.capture(d)
    out = %DecisionOutcome{decision_id: d.id, alternative_id: :a, observed_outcome: "win",
                           observed_at: DateTime.add(d.created_at, 10, :second)}
    res = TemporalFirewall.verify(d, snap, [out])
    assert res.firewall_intact?
    assert res.snapshot_consistent?
    assert res.contamination == []
  end

  test "hindsight outcome (predating the decision) breaks the firewall" do
    d = Decision.new(question: "Q", alternatives: [alt(:a, [0.5, 0.5], [1, 1])])
    snap = DecisionSnapshot.capture(d)
    out = %DecisionOutcome{decision_id: d.id, alternative_id: :a, observed_outcome: "win",
                           observed_at: DateTime.add(d.created_at, -1, :second)}
    res = TemporalFirewall.verify(d, snap, [out])
    refute res.firewall_intact?
    assert res.contamination != []
  end

  test "D4 analysis never writes to a D3 decision" do
    d = Decision.new(question: "Q", alternatives: [alt(:a, [0.5, 0.5], [1, 1])])
    snap = DecisionSnapshot.capture(d)
    out = %DecisionOutcome{decision_id: d.id, alternative_id: :a, observed_outcome: "win",
                           observed_at: DateTime.add(d.created_at, 1, :second)}
    res = TemporalFirewall.verify(d, snap, [out])
    assert res.firewall_intact?
    assert res.d3_writes == []
  end

  test "a counterfactual that attempts a D3 write is flagged and breaks the firewall" do
    d = Decision.new(question: "Q", alternatives: [alt(:a, [0.5, 0.5], [1, 1])])
    snap = DecisionSnapshot.capture(d)
    cf = Counterfactual.new(%{
      intervention: %InterventionSpec{kind: :do_nothing},
      reference: %{baseline_state_ref: "blob", write_to_d3: true}
    })
    res = TemporalFirewall.verify(d, snap, [cf])
    refute res.firewall_intact?
    assert res.d3_writes != []
  end
end