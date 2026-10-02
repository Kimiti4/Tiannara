defmodule Tiannara.Sentinel.MathematicalEvidenceStoreTest do
  use ExUnit.Case

  alias Tiannara.Sentinel.MathematicalEvidenceStore

  setup do
    case Process.whereis(MathematicalEvidenceStore) do
      nil -> {:ok, _pid} = MathematicalEvidenceStore.start_link([])
      _pid -> :ok
    end
    :ok
  end

  test "records and retrieves proof evidence" do
    artifact = %{
      status: :proven_under_assumptions,
      assumptions: [],
      conclusion: {:atom, :P},
      checked_steps: 1,
      kernel: "Tiannara.Math.ProofKernel.v1"
    }

    assert {:ok, evidence} =
      MathematicalEvidenceStore.record(
        :proof_checked,
        artifact,
        %{proof_steps: [%{id: 1}]}
      )

    assert MathematicalEvidenceStore.get(evidence.id) == evidence
    assert evidence.kind == :proof_checked
  end

  test "indexes evidence by kind" do
    artifact = %{
      status: :counterexample_found,
      witness: :x,
      tested_cases: 1,
      domain: [:x]
    }

    assert {:ok, _} =
      MathematicalEvidenceStore.record(
        :counterexample_found,
        artifact,
        %{search_definition: %{strategy: :exhaustive}}
      )

    assert Enum.all?(
      MathematicalEvidenceStore.by_kind(:counterexample_found),
      &(&1.kind == :counterexample_found)
    )
  end
end
