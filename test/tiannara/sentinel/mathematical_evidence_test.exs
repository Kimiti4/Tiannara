defmodule Tiannara.Sentinel.MathematicalEvidenceTest do
  use ExUnit.Case, async: true
  alias Tiannara.Sentinel.MathematicalEvidence

  test "accepts proof evidence with replay provenance" do
    artifact = %{
      status: :proven_under_assumptions,
      assumptions: [{:atom, :P}],
      conclusion: {:atom, :P},
      checked_steps: 1,
      kernel: "Tiannara.Math.ProofKernel.v1"
    }

    assert {:ok, evidence} =
      MathematicalEvidence.build(:proof_checked, artifact, %{proof_steps: [%{id: 1}]})

    assert evidence.kind == :proof_checked
    assert evidence.status == :proven_under_assumptions
  end

  test "rejects proof evidence without replay steps" do
    artifact = %{
      status: :proven_under_assumptions,
      assumptions: [],
      conclusion: {:atom, :P},
      checked_steps: 0,
      kernel: "Tiannara.Math.ProofKernel.v1"
    }

    assert {:error, :invalid_proof_evidence} =
      MathematicalEvidence.build(:proof_checked, artifact, %{})
  end

  test "stores a bounded non-falsification result as bounded evidence" do
    artifact = %{
      status: :no_counterexample_in_domain,
      tested_cases: 100,
      domain: :finite_domain,
      search_complete: true
    }

    assert {:ok, evidence} =
      MathematicalEvidence.build(:bounded_non_falsification, artifact, %{
        search_definition: %{strategy: :exhaustive}
      })

    assert evidence.status == :survived_tested_domain
  end

  test "counterexamples remain explicitly refutational" do
    artifact = %{
      status: :counterexample_found,
      witness: 5,
      tested_cases: 6,
      domain: [0, 1, 2, 3, 4, 5]
    }

    assert {:ok, evidence} =
      MathematicalEvidence.build(:counterexample_found, artifact, %{
        search_definition: %{strategy: :exhaustive}
      })

    assert evidence.status == :refuted_in_tested_domain
  end
end
