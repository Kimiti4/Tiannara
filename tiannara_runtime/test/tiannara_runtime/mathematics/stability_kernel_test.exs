defmodule TiannaraRuntime.Mathematics.StabilityKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.StabilityKernel

  test "equilibria remain candidates until verified" do
    assert {:ok, %{status: :candidate_equilibrium, certification_eligible: false}} =
      StabilityKernel.equilibrium({:x, 0}, {:constant, 0})
  end

  test "local stability analysis requires verified Jacobian evidence" do
    assert {:error, :verified_jacobian_evidence_required} =
      StabilityKernel.verify_local_linearization(%{jacobian: :J, evidence: %{status: :observed}})
  end

  test "observed trajectories are not stability proofs" do
    assert {:ok, %{stability_status: :observed_behavior, certification_eligible: false}} =
      StabilityKernel.classify_observed_trajectory([{0, 1}, {1, 1}, {2, 1}])
  end
end
