defmodule Tiannara.Domains.DomainQuarantineTest do
  @moduledoc """
  Regression gate for ledger §7 step 3 (D-A3) and production-readiness scan
  A5: domains whose `simulate/2` and `validate/1` returned constant success
  verdicts — fabricated domain evidence — must now fail closed with named
  reasons; domains whose `evaluate/1` returned a constant verdict must fail
  closed; domains whose `metrics/0` returned hardcoded counts and scores
  presented as measurements must mark them nil with `data_source: :unavailable`.
  Real domains (physics RK4, chemistry graph computation, entropy/Bayes
  evaluates, FormalVerification-backed validates) must remain callable.
  """

  use ExUnit.Case, async: true

  @quarantined_simulate [
    Tiannara.Domains.Aerospace,
    Tiannara.Domains.Agriculture,
    Tiannara.Domains.Architecture,
    Tiannara.Domains.Cognition,
    Tiannara.Domains.Computation,
    Tiannara.Domains.Cybernetics,
    Tiannara.Domains.Ecology,
    Tiannara.Domains.Economics,
    Tiannara.Domains.Energy,
    Tiannara.Domains.Engineering,
    Tiannara.Domains.Governance,
    Tiannara.Domains.Linguistics,
    Tiannara.Domains.Logistics,
    Tiannara.Domains.Materials,
    Tiannara.Domains.Medicine,
    Tiannara.Domains.Philosophy,
    Tiannara.Domains.Robotics,
    Tiannara.Domains.Sociology
  ]

  @quarantined_validate [
    Tiannara.Domains.Agriculture,
    Tiannara.Domains.Chemistry,
    Tiannara.Domains.Cognition,
    Tiannara.Domains.Computation,
    Tiannara.Domains.Cybernetics,
    Tiannara.Domains.Ecology,
    Tiannara.Domains.Economics,
    Tiannara.Domains.Energy,
    Tiannara.Domains.Governance,
    Tiannara.Domains.Linguistics,
    Tiannara.Domains.Logistics,
    Tiannara.Domains.Materials,
    Tiannara.Domains.Medicine,
    Tiannara.Domains.Philosophy,
    Tiannara.Domains.Robotics,
    Tiannara.Domains.Sociology
  ]

  test "every quarantined simulate/2 fails closed instead of asserting a verdict" do
    for module <- @quarantined_simulate do
      assert module.simulate(%{subject: :s, object: :o}, %{}) == {:error, :simulation_unavailable},
             "#{inspect(module)}.simulate/2 must not return a constant success verdict"
    end
  end

  test "every quarantined validate/1 fails closed instead of unconditional validity" do
    for module <- @quarantined_validate do
      assert module.validate(%{model: %{}}) == {:error, :validation_unavailable},
             "#{inspect(module)}.validate/1 must not return unconditional validity"
    end
  end

  test "the specific fabricated measurements are no longer producible" do
    refute match?({:ok, %{trial_phase: _}}, Tiannara.Domains.Medicine.validate(%{}))
    refute match?({:ok, %{constitutional_alignment: _}}, Tiannara.Domains.Governance.validate(%{}))
    assert {:error, :simulation_unavailable} = Tiannara.Domains.Aerospace.simulate(%{}, %{})
    assert {:error, :simulation_unavailable} = Tiannara.Domains.Medicine.simulate(%{}, %{})
  end

  test "real domains are NOT quarantined — physics RK4 stays callable end-to-end" do
    pilot = Tiannara.Domains.Physics.pilot_experiment()

    assert {:ok, %{result: %{}, provenance: %{} = prov}} =
             Tiannara.Domains.Physics.simulate(pilot.hypothesis, pilot.context)

    assert prov.kind == :simulation

    assert {:ok, %{valid: _valid, verification_method: :structural_checks}} =
             Tiannara.Domains.Physics.validate(%{
               model: %{result: Tiannara.Domains.Physics.simulate(pilot.hypothesis, pilot.context) |> elem(1) |> Map.get(:result)}
             })
  end

  test "chemistry simulate keeps its real graph computation (not the quarantine atom)" do
    result = Tiannara.Domains.Chemistry.simulate(%{molecular_graph: %{}}, %{})
    refute result == {:error, :simulation_unavailable}
  end

  @constant_evaluate [
    Tiannara.Domains.Architecture,
    Tiannara.Domains.Chemistry,
    Tiannara.Domains.Governance,
    Tiannara.Domains.Logistics,
    Tiannara.Domains.Robotics
  ]

  @hardcoded_metrics [
    Tiannara.Domains.Aerospace,
    Tiannara.Domains.Agriculture,
    Tiannara.Domains.Architecture,
    Tiannara.Domains.Chemistry,
    Tiannara.Domains.Cognition,
    Tiannara.Domains.Computation,
    Tiannara.Domains.Cybernetics,
    Tiannara.Domains.Ecology,
    Tiannara.Domains.Economics,
    Tiannara.Domains.Energy,
    Tiannara.Domains.Engineering,
    Tiannara.Domains.Governance,
    Tiannara.Domains.Linguistics,
    Tiannara.Domains.Logistics,
    Tiannara.Domains.Materials,
    Tiannara.Domains.Medicine,
    Tiannara.Domains.Philosophy,
    Tiannara.Domains.Robotics,
    Tiannara.Domains.Sociology
  ]

  @metric_keys [
    :active_hypotheses,
    :open_experiments,
    :discoveries_this_cycle,
    :knowledge_growth_rate,
    :evidence_quality_score,
    :hypotheses_generated,
    :experiments_completed
  ]

  test "constant evaluate/1 verdicts fail closed instead of fabricating a score (A5)" do
    for module <- @constant_evaluate do
      assert module.evaluate(%{subject: :s, object: :o}) == {:error, :evaluation_unavailable},
             "#{inspect(module)}.evaluate/1 must not return a constant success verdict"
    end
  end

  test "real evaluates are NOT quarantined — entropy and Bayes stay callable (A5)" do
    assert {:ok, entropy} =
             Tiannara.Domains.Computation.evaluate(%{state_probabilities: %{a: 0.5, b: 0.5}})

    assert is_float(entropy)

    assert {:ok, _} =
             Tiannara.Domains.Cybernetics.evaluate(%{feedback_probabilities: %{a: 0.5, b: 0.5}})
  end

  test "hardcoded metrics are nil with an explicit data_source marker (A5)" do
    for module <- @hardcoded_metrics do
      metrics = module.metrics()

      assert metrics.data_source == :unavailable,
             "#{inspect(module)}.metrics/0 must declare data_source: :unavailable"

      for key <- @metric_keys do
        assert metrics[key] == nil,
               "#{inspect(module)}.metrics/0 must not report #{inspect(key)} as a measurement"
      end
    end
  end

  test "physics metrics stay state-derived and are NOT marked unavailable (A5)" do
    metrics = Tiannara.Domains.Physics.metrics()

    refute Map.has_key?(metrics, :data_source),
           "physics metrics are real state-derived data and must not carry the quarantine marker"

    assert metrics.metrics_source == :state_derived
  end

  test "observatory domain dashboard renders quarantined metrics as nil without crashing" do
    {:ok, _} = Tiannara.Domains.ResearchDirector.register_domain(Tiannara.Domains.Medicine)
    {:ok, _} = Tiannara.Domains.ResearchDirector.register_domain(Tiannara.Domains.Physics)

    dashboard = Tiannara.Observatory.Metrics.Domains.get_dashboard_data()

    assert Enum.any?(dashboard, fn entry -> entry.name == :medicine and entry.hypotheses == nil end)

    assert Enum.any?(dashboard, fn entry ->
             entry.name == :physics and is_integer(entry.hypotheses)
           end)
  end
end
