defmodule TiannaraRuntime.Mathematics.ProofKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.{ProofKernel, CounterexampleKernel}

  test "proof composition retains assumptions and premises" do
    {:ok, proof} = ProofKernel.new(:theorem_x, [:assumption_a])
    {:ok, proof} = ProofKernel.add_premise(proof, :lemma_1, %{status: :proved})
    {:ok, proof} =
      ProofKernel.add_step(proof, :modus_ponens, [:lemma_1], :conclusion_x, %{status: :proved})
    {:ok, proof} = ProofKernel.conclude(proof, :conclusion_x)

    assert {:ok, verified} = ProofKernel.verify(proof)
    assert verified.proof_status == :independently_verifiable
  end

  test "unverified proof steps cannot pass verification" do
    {:ok, proof} = ProofKernel.new(:theorem_x)
    {:ok, proof} =
      ProofKernel.add_step(proof, :unknown_rule, [], :x, %{status: :observed})
    {:ok, proof} = ProofKernel.conclude(proof, :x)

    assert {:error, :unsupported_proof_step_evidence} = ProofKernel.verify(proof)
  end

  test "counterexample changes claim state without becoming a universal theorem" do
    assert {:ok, result} =
      CounterexampleKernel.test_universal(:all_x, [
        %{case: 7, violates_claim: true, domain: :integers,
          evidence: %{status: :proved}}
      ])

    assert result.claim_status == :falsified_for_stated_domain
    assert result.certification_eligible == false
  end

  test "no counterexample is not proof" do
    assert {:ok, result} =
      CounterexampleKernel.test_universal(:all_x, [
        %{case: 1, violates_claim: false},
        %{case: 2, violates_claim: false}
      ])

    assert result.claim_status == :not_falsified
    assert result.proof_status == :unproved
  end
end
