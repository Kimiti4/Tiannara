defmodule Tiannara.Omega.PatchGeneratorTest do
  use ExUnit.Case, async: true

  alias Tiannara.Omega.{ExperimentGenerator, PatchGenerator, AuthorityVerifier}
  alias Tiannara.Omega.PatchGenerator.Candidate

  @moduletag :omega_patch_generator

  defp sample_proposal do
    %{
      id: :prop_1,
      hypothesis_id: :hyp_1,
      statement: "memory growth is caused by unbounded cache",
      type: :memory,
      falsifier: "memory does not decrease when cache is bounded",
      rank: 1,
      status: :proposed
    }
  end

  test "experiment generator produces a falsifiable experiment spec" do
    assert {:ok, spec} = ExperimentGenerator.design(sample_proposal())

    assert spec.hypothesis_id == :hyp_1
    assert spec.proposal_id == :prop_1
    assert spec.method == :measure_memory_delta
    assert spec.prediction =~ "memory growth"
    assert spec.falsifier != nil
    assert :prop_1 in spec.lineage
  end

  test "patch generator produces a candidate with full lineage" do
    {:ok, spec} = ExperimentGenerator.design(sample_proposal())
    assert {:ok, candidate} = PatchGenerator.generate(spec)

    assert candidate.type in Candidate.candidate_types()
    assert candidate.proposal_id == :prop_1
    assert candidate.status == :generated
    assert :prop_1 in candidate.lineage
    assert :hyp_1 in candidate.lineage
  end

  test "GENERATION ≠ AUTHORITY: generator has no deployment capability" do
    assert AuthorityVerifier.assert_no_deployment_capability(PatchGenerator) == :ok
    assert AuthorityVerifier.assert_no_deployment_capability(ExperimentGenerator) == :ok
  end

  test "candidate cannot skip the sandbox" do
    {:ok, spec} = ExperimentGenerator.design(sample_proposal())
    {:ok, candidate} = PatchGenerator.generate(spec)

    # The only legal transition from :generated is :sandboxed.
    assert {:error, {:illegal_transition, _}} = Candidate.transition(candidate, :deployed)
    assert {:error, {:illegal_transition, _}} = Candidate.transition(candidate, :approved)
    assert {:error, {:illegal_transition, _}} = Candidate.transition(candidate, :tested)
    assert {:ok, sandboxed} = Candidate.transition(candidate, :sandboxed)
    assert sandboxed.status == :sandboxed
  end

  test "candidate cannot be deployed without passing the full chain" do
    {:ok, spec} = ExperimentGenerator.design(sample_proposal())
    {:ok, candidate} = PatchGenerator.generate(spec)

    # Walk the full legal chain. The final step (:approved → :deployed) is
    # NOT reachable through the generic transition/2 — it is the DeploymentGateway's
    # exclusive authority via deploy_transition/1.
    {:ok, c1} = Candidate.transition(candidate, :sandboxed)
    {:ok, c2} = Candidate.transition(c1, :tested)
    {:ok, c3} = Candidate.transition(c2, :benchmarked)
    {:ok, c4} = Candidate.transition(c3, :certified)
    {:ok, c5} = Candidate.transition(c4, :approved)
    {:ok, c6} = Candidate.deploy_transition(c5)

    assert c6.status == :deployed
    assert Candidate.sandboxed?(c6)

    # The generic transition must never reach :deployed — even from :approved.
    assert {:error, {:illegal_transition, _}} = Candidate.transition(c5, :deployed)
    assert {:error, {:candidate_not_approved, _}} = Candidate.deploy_transition(c4)

    # A candidate that never reached :approved cannot deploy.
    {:ok, spec2} = ExperimentGenerator.design(sample_proposal())
    {:ok, cand2} = PatchGenerator.generate(spec2)
    refute Candidate.deployable?(cand2)
  end

  test "authority verifier rejects a generator with deployment capability" do
    defmodule RogueGenerator do
      def generate(_spec, _ctx), do: {:ok, nil}
      def deploy(_candidate), do: :deployed
    end

    assert {:error, {:deployment_capability_found, violations}} =
             AuthorityVerifier.assert_no_deployment_capability(RogueGenerator)

    assert :deploy in violations
  end
end