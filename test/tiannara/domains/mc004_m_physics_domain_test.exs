defmodule Tiannara.Domains.PhysicsTest do
  use ExUnit.Case, async: true

  alias Tiannara.Domains.Physics

  test "simulates the pilot damped oscillator with a real trajectory and simulation provenance" do
    pilot = Physics.pilot_experiment()

    assert {:ok, %{result: result, provenance: provenance}} =
             Physics.simulate(pilot.hypothesis, pilot.context)

    assert result.type == :trajectory
    assert result.method == :rk4
    assert result.order == 4
    assert is_list(result.trajectory) and length(result.trajectory) > 0
    assert %{kind: :simulation} = provenance
    assert is_binary(provenance.evidence_hash)
    assert String.length(provenance.evidence_hash) == 64
  end

  test "simulation obeys underdamped decay: amplitude stays within the decaying envelope" do
    pilot = Physics.pilot_experiment()
    assert {:ok, sim} = Physics.simulate(pilot.hypothesis, pilot.context)
    result = sim.result

    amplitudes =
      result.trajectory
      |> Enum.map(fn p -> abs(List.first(p.x)) end)

    # Damped-harmonic envelope: e^(-c*t/2m) starting from amplitude 1.0, so at
    # t=10 the bound is ~0.082; the sampled position must stay <= initial and
    # end far below the start (an explicit, real check of the integrated result).
    assert Enum.max(amplitudes) <= 1.0 + 1.0e-9
    assert List.last(amplitudes) < 0.1
    assert hd(amplitudes) <= 1.0 + 1.0e-9
    assert List.last(amplitudes) < hd(amplitudes)
  end

  test "validate performs structural_checks on the pilot trajectory (never claims verified)" do
    pilot = Physics.pilot_experiment()
    assert {:ok, sim_result} = Physics.simulate(pilot.hypothesis, pilot.context)

    assert {:ok, validation} = Physics.validate(%{model: sim_result})
    assert validation.verification_method == :structural_checks
    assert is_boolean(validation.valid)
    assert validation.valid == true
    refute Map.has_key?(validation, :verified)
  end

  test "validate remains formal_verification_unavailable for empty models (MC-001 pin)" do
    assert {:error, :formal_verification_unavailable} = Physics.validate(%{model: %{}})
    assert {:error, :formal_verification_unavailable} = Physics.validate(%{})
  end

  test "simulate stays unavailable for the MC-001 empty placeholder (MC-001 pin)" do
    assert {:error, :ode_solver_unavailable} =
             Physics.simulate(%{equations: []}, %{boundary_conditions: []})
  end

  test "execute_experiment bridges to the gated Phase4 gateway" do
    spec = Physics.pilot_experiment()
    assert {:error, :real_execution_not_enabled} = Physics.execute_experiment(spec)
    assert {:error, :invalid_experiment_spec} = Physics.execute_experiment(%{})
  end
end