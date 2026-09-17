defmodule Tiannara.Discoveries.OrbitEngineeringTest do
  use ExUnit.Case, async: false

  alias Tiannara.OrbitEngineering
  alias Tiannara.OrbitAtlas
  alias Tiannara.OrbitTransitions

  setup do
    # Clear and calculate to get a pristine state
    {:ok, _stats} = OrbitEngineering.import_and_calculate()
    :ok
  end

  test "trajectory state classification matches expected logic" do
    # Stability
    telemetry_st = %{dcr_retention: 0.9, scp_retention: 0.2, mortality_rate: 0.0, adaptation_velocity: 0.0}
    assert {:stability_orbit, _} = OrbitEngineering.classify_state(telemetry_st, 0.9)

    # Collapse Recovery
    telemetry_cr = %{dcr_retention: 0.1, scp_retention: 0.0, mortality_rate: 0.0, adaptation_velocity: 1.0}
    assert {:collapse_recovery_orbit, _} = OrbitEngineering.classify_state(telemetry_cr, 0.7)

    # Brittle / Decay
    telemetry_br = %{dcr_retention: 0.1, scp_retention: 0.0, mortality_rate: 0.2, adaptation_velocity: 0.0}
    assert {:other_orbit_1, _} = OrbitEngineering.classify_state(telemetry_br, 0.1)
  end

  test "transition probability matrix calculations and row sum compliance" do
    matrix = OrbitAtlas.get_matrix()
    assert Map.has_key?(matrix, :stability_orbit)
    
    Enum.each(matrix, fn {from_orbit, targets} ->
      row_sum = Enum.sum(Map.values(targets))
      assert_in_delta row_sum, 1.0, 0.001, "Row sum for #{from_orbit} should equal 1.0"
    end)
  end

  test "residency ratios, lifetimes, and volatility metrics calculations" do
    residency = OrbitAtlas.calculate_residency_ratios()
    assert is_map(residency)
    assert Map.has_key?(residency, :stability_orbit)
    assert_in_delta Enum.sum(Map.values(residency)), 1.0, 0.001

    lifetimes = OrbitAtlas.calculate_mean_lifetimes()
    assert is_map(lifetimes)
    assert Map.get(lifetimes, :stability_orbit) > 0.0

    volatilities = OrbitAtlas.calculate_volatility_indices()
    assert is_map(volatilities)
    Enum.each(volatilities, fn {_run, ovi} ->
      assert is_float(ovi)
      assert ovi >= 0.0
    end)
  end

  test "attractor classification and forbidden transition metrics" do
    classifications = OrbitAtlas.classify_orbits()
    assert is_map(classifications)
    assert Map.has_key?(classifications, :sinks)
    assert Map.has_key?(classifications, :attractors)
    assert Map.has_key?(classifications, :gateways)

    forbidden = OrbitAtlas.get_forbidden_transitions()
    assert is_list(forbidden)
    Enum.each(forbidden, fn t ->
      assert t.transition_cost > 0.5
      assert t.successes == 0 or t.probability < 0.02
    end)
  end

  test "Markov steady-state and dominant eigen-orbits calculate successfully" do
    steady_state = OrbitAtlas.calculate_steady_state()
    assert is_map(steady_state)
    assert_in_delta Enum.sum(Map.values(steady_state)), 1.0, 0.001

    eigen_orbits = OrbitAtlas.get_dominant_eigen_orbits()
    assert is_list(eigen_orbits)
    assert length(eigen_orbits) == 4
    
    {_first_id, first_val} = List.first(eigen_orbits)
    {_last_id, last_val} = List.last(eigen_orbits)
    assert first_val >= last_val
  end

  test "Mission Control summary metrics parse correctly" do
    summary = OrbitAtlas.get_summary_metrics()
    assert is_map(summary)
    assert Map.has_key?(summary, :most_common)
    assert Map.has_key?(summary, :most_valuable)
    assert Map.has_key?(summary, :most_dangerous)
    assert Map.has_key?(summary, :highest_cost)
    assert Map.has_key?(summary, :most_stable)

    if summary.most_common do
      assert summary.most_common.probability > 0.0
    end
  end
end
