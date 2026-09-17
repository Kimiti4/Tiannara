defmodule Tiannara.ASC.CMissions.ContractTest do
  use ExUnit.Case, async: true

  alias Tiannara.ASC.CMissions.{Contract, Pareto}

  @contract %{
    peak_ceiling: 0.25,
    retained_reject_floor: 0.15,
    latency_no_effect_ceiling: 0.25,
    retained_ceiling: 0.05,
    latency_adoption_floor: 0.25,
    review_band_retained_max: 0.15,
    review_band_latency_min: 0.60
  }

  defp s(overrides) do
    Map.merge(
      %{
        candidate: :x,
        ci_95: {0.60, 0.80},
        peak_ci: {0.10, 0.20},
        retained_ci: {0.00, 0.02}
      },
      overrides
    )
  end

  # ---- Pareto dominance -------------------------------------------------------

  test "a dominates b when better on one objective and not worse on all" do
    a = s(%{candidate: :a, ci_95: {0.60, 0.80}, retained_ci: {0.00, 0.02}})
    b = s(%{candidate: :b, ci_95: {0.58, 0.82}, retained_ci: {0.20, 0.30}})

    assert Pareto.dominates?(a, b)
    refute Pareto.dominates?(b, a)
  end

  test "overlapping CIs on all objectives: neither dominates" do
    a = s(%{candidate: :a, ci_95: {0.60, 0.80}, retained_ci: {0.00, 0.04}})
    b = s(%{candidate: :b, ci_95: {0.62, 0.82}, retained_ci: {0.01, 0.05}})

    refute Pareto.dominates?(a, b)
    refute Pareto.dominates?(b, a)
  end

  test "strictly separated latency CIs decide the better candidate" do
    a = s(%{candidate: :a, ci_95: {0.80, 0.90}, retained_ci: {0.00, 0.02}})
    b = s(%{candidate: :b, ci_95: {0.60, 0.70}, retained_ci: {0.00, 0.02}})

    assert Pareto.dominates?(a, b)
  end

  test "strictly separated retained CIs decide the better candidate" do
    a = s(%{candidate: :a, ci_95: {0.60, 0.80}, retained_ci: {0.00, 0.02}})
    b = s(%{candidate: :b, ci_95: {0.60, 0.80}, retained_ci: {0.20, 0.30}})

    assert Pareto.dominates?(a, b)
  end

  test "front removes dominated candidates, keeps incomparable ones" do
    a = s(%{candidate: :a, ci_95: {0.60, 0.80}, retained_ci: {0.00, 0.02}})
    b = s(%{candidate: :b, ci_95: {0.58, 0.82}, retained_ci: {0.20, 0.30}})
    c = s(%{candidate: :c, ci_95: {0.62, 0.82}, retained_ci: {0.01, 0.05}})

    front = Pareto.front([a, b, c])

    assert Enum.map(front, & &1.candidate) == [:a, :c]
  end

  # ---- candidate statuses ------------------------------------------------------

  test "peak CI low above ceiling -> rejected_peak" do
    status = Contract.candidate_status(s(%{peak_ci: {0.30, 0.40}}), @contract)
    assert status == :rejected_peak
  end

  test "retained CI low above reject floor -> rejected_memory" do
    status = Contract.candidate_status(s(%{retained_ci: {0.20, 0.30}}), @contract)
    assert status == :rejected_memory
  end

  test "latency CI high below no-effect ceiling -> rejected_no_effect" do
    status = Contract.candidate_status(s(%{ci_95: {0.05, 0.20}}), @contract)
    assert status == :rejected_no_effect
  end

  test "retained within ceiling and latency above floor -> eligible" do
    status = Contract.candidate_status(s(%{ci_95: {0.30, 0.50}}), @contract)
    assert status == :eligible
  end

  test "retained within ceiling and latency in review band -> review_band" do
    status =
      Contract.candidate_status(s(%{ci_95: {0.62, 0.80}, retained_ci: {0.10, 0.12}}), @contract)

    assert status == :review_band
  end

  test "latency CI straddles the adoption floor -> insufficient" do
    status = Contract.candidate_status(s(%{ci_95: {0.20, 0.30}}), @contract)
    assert status == :insufficient
  end

  # ---- final decision ----------------------------------------------------------

  test "lone eligible on the front -> accept_eligible" do
    statused = [s(%{candidate: :a, status: :eligible})]
    assert Contract.final_decision(statused) == {:accept_eligible, [:a]}
  end

  test "empty front -> reject_no_adoption" do
    assert Contract.final_decision([]) == {:reject_no_adoption, []}
  end

  test "front with only review_band members -> review" do
    statused = [s(%{candidate: :a, status: :review_band, retained_ci: {0.10, 0.12}})]
    assert {:review, [:a]} = Contract.final_decision(statused)
  end

  test "incomparable eligible candidates -> review with both on the front" do
    statused = [
      s(%{candidate: :a, status: :eligible}),
      s(%{candidate: :b, status: :eligible, ci_95: {0.62, 0.82}, retained_ci: {0.01, 0.05}})
    ]

    assert Contract.final_decision(statused) == {:review, [:a, :b]}
  end

  test "eligible dominates review_band on latency -> accept the eligible one" do
    statused = [
      s(%{candidate: :a, status: :eligible, ci_95: {0.80, 0.90}, retained_ci: {0.00, 0.02}}),
      s(%{candidate: :b, status: :review_band, ci_95: {0.62, 0.70}, retained_ci: {0.10, 0.12}})
    ]

    assert Contract.final_decision(statused) == {:accept_eligible, [:a]}
  end
end