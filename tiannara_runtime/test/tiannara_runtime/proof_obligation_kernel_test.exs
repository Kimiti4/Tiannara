defmodule TiannaraRuntime.Mathematics.ProofObligationKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.{ProofObligationKernel, LemmaSearch}

  test "decomposes a theorem into open obligations" do
    {:ok, plan} = ProofObligationKernel.create(:theorem, [:lemma_a, :boundary_b])
    assert {:ok, %{open: 2, discharged: 0, complete: false}} =
      ProofObligationKernel.status(plan)
  end

  test "only verified evidence can discharge an obligation" do
    {:ok, plan} = ProofObligationKernel.create(:theorem, [:lemma_a])
    assert {:error, :independent_verified_evidence_required} =
      ProofObligationKernel.discharge(plan, 1, %{status: :observed})

    assert {:ok, plan} =
      ProofObligationKernel.discharge(plan, 1, %{status: :proved})

    assert {:ok, %{complete: true, proof_status: :all_obligations_discharged}} =
      ProofObligationKernel.status(plan)
  end

  test "lemma retrieval is only a candidate match" do
    {:ok, results} =
      LemmaSearch.search([
        %{name: "lemma_one", terms: [:continuity], verified_uses: 3}
      ], :continuity)

    assert [%{match_status: :candidate_match}] = results
  end
end
