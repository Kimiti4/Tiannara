defmodule TiannaraRuntime.Mathematics.ProofPlanningTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.ProofPlanner
  alias TiannaraRuntime.Mathematics.ProofComposer

  test "proof planning remains unproven" do
    {:ok, plan} = ProofPlanner.plan("For all n, P(n) holds", strategy: :induction, budget: 3)
    assert plan.status == :unproven
    assert plan.certification_eligible == false
    assert length(plan.obligations) == 3
  end

  test "proof composition rejects circular dependencies" do
    components = [
      %{"proof_id" => "a", "dependencies" => ["b"]},
      %{"proof_id" => "b", "dependencies" => ["a"]}
    ]

    assert {:error, {:circular_proof_dependency, _}} =
             ProofComposer.compose("assertion-1", components)
  end

  test "acyclic composition remains unverified" do
    components = [
      %{"lemma_id" => "lemma-a", "dependencies" => []},
      %{"proof_id" => "proof-b", "dependencies" => ["lemma-a"]}
    ]

    {:ok, composition} = ProofComposer.compose("assertion-1", components)
    assert composition.status == "candidate"
    assert composition.verification_status == "unverified"
    assert composition.certification_eligible == false
  end
end
