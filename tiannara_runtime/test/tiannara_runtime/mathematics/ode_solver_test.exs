defmodule TiannaraRuntime.Mathematics.OdeSolverTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.OdeSolver

  test "Euler produces a candidate numerical trajectory" do
    rhs = fn _t, %{x: x} -> %{x: -x} end
    {:ok, result} = OdeSolver.solve(rhs, %{x: 1.0}, {0.0, 1.0}, 0.1)

    assert result.method == :explicit_euler
    assert result.solution_status == :candidate_solution
    assert result.evidence_class == :numerical_approximation
    assert result.certification_eligible == false
    assert length(result.trajectory) > 1
  end
end
