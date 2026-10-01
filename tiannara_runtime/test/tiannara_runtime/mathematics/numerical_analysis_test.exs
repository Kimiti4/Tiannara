defmodule TiannaraRuntime.Mathematics.NumericalAnalysisTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.{RungeKutta4, ConvergenceEvidence}

  test "RK4 generates an explicitly approximate trajectory" do
    rhs = fn _t, %{x: x} -> %{x: -x} end
    {:ok, result} = RungeKutta4.solve(rhs, %{x: 1.0}, {0.0, 1.0}, 0.1)

    assert result.method == :runge_kutta_4
    assert result.order == 4
    assert result.evidence_class == :numerical_approximation
    assert result.convergence_status == :unassessed
    assert result.certification_eligible == false
  end

  test "agreement between resolutions remains observational evidence" do
    assert {:ok, result} = ConvergenceEvidence.compare(0.3679, 0.36788)
    assert result.convergence_status == :observed_only
    assert result.proof_status == :unproved
    assert result.certification_eligible == false
  end

  test "convergence rate requires an independent verifier" do
    assert {:error, :convergence_theorem_verifier_required} =
      ConvergenceEvidence.verify_rate([{1, 0.1}, {2, 0.025}], 4)
  end
end
