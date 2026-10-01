defmodule TiannaraRuntime.Mathematics.ProofPlannerTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.ProofPlanner

  test "plans multiple bounded strategies without proving" do
    {:ok, plan} = ProofPlanner.plan("forall n, n + 1 > n", budget: 3)
    assert length(plan.strategies) == 3
    assert plan.status == :proposed
    assert plan.certification_eligible == false
    assert Enum.all?(plan.obligations, &(&1.status == :unproven))
  end

  test "proof execution requires an actual backend" do
    assert {:unavailable, {:proof_backend_required, :induction}} =
             ProofPlanner.execute_strategy(:induction, %{})
  end

  test "invalid assertion is rejected" do
    assert {:error, :mathematical_assertion_required} = ProofPlanner.plan("")
  end
end
