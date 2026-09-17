defmodule Tiannara.Forecasting.D4IntegrationTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.Contracts.{Alternative, DecisionOutcome, InterventionSpec}

  defp alt(id, probs, utils) do
    struct!(%Alternative{},
      id: id, label: Atom.to_string(id),
      outcomes: ["win", "lose"], probabilities: probs, utilities: utils,
      reversibility: :reversible)
  end

  test "EFDI status reflects D4 implemented and D5/D6 deferred" do
    st = Tiannara.Forecasting.status()
    assert :counterfactual in st.implemented
    assert :attribution in st.implemented
    assert :selection in st.implemented
    assert :regression_to_mean in st.implemented
    assert :noise in st.deferred
    assert :memory in st.deferred
  end

  test "a full D4 pass: bundle → analysis, all read-only over D3" do
    d = Tiannara.Forecasting.decide(%{
      question: "Should we launch?",
      alternatives: [
        %{id: :launch, outcomes: ["success", "fail"], probabilities: [0.7, 0.3], utilities: [200, -100],
          reversibility: :reversible},
        %{id: :do_nothing, outcomes: ["no_change"], probabilities: [1.0], utilities: [0],
          reversibility: :reversible}
      ]
    })
    |> elem(1)

    bundle = Tiannara.Forecasting.alternative_history(d)
    assert bundle.decision_id == d.id
    assert bundle.includes_do_nothing

    outs = List.duplicate(
      %DecisionOutcome{decision_id: d.id, alternative_id: :launch, observed_outcome: "success",
                       observed_at: DateTime.utc_now()}, 5)

    report = Tiannara.Forecasting.attribution(d, outs)
    assert report.decision_id == d.id
    assert report.repeat_count == 5

    sel = Tiannara.Forecasting.selection(%{population_size: 100, sample_size: 10})
    assert sel.denominator_status == :known

    rtm = Tiannara.Forecasting.regression_to_mean([2, 3, 2.5], %{mean: 3, std: 0.5})
    assert is_number(rtm.extremity_index)
  end
end