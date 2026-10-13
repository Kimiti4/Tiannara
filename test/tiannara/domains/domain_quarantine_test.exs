defmodule Tiannara.Domains.DomainQuarantineTest do
  @moduledoc """
  Regression gate for ledger §7 step 3 (D-A3): domains whose `simulate/2` and
  `validate/1` returned constant success verdicts — fabricated domain evidence —
  must now fail closed with named reasons. Real domains (physics RK4, chemistry
  graph computation, FormalVerification-backed validates) must remain callable.
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
end
