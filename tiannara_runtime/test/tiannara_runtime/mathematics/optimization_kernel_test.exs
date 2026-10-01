defmodule TiannaraRuntime.Mathematics.OptimizationKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.OptimizationKernel

  test "defines constrained optimization problem without claiming an optimum" do
    {:ok, problem} = OptimizationKernel.define(:minimize_energy, [:x], [{:le, :x, 10}])
    assert problem.status == :defined
    assert problem.optimality_status == :unproved
  end

  test "candidate solution remains unproved" do
    {:ok, problem} = OptimizationKernel.define(:maximize_output, [:x])
    {:ok, candidate} = OptimizationKernel.candidate(problem, %{x: 5}, %{samples: 100})
    assert candidate.status == :candidate_found
    assert candidate.optimality_status == :unproved
  end

  test "optimality requires a verifier" do
    assert {:error, :optimality_verifier_required} =
      OptimizationKernel.establish_optimality(%{}, %{}, %{})
  end
end
