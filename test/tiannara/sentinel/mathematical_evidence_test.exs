defmodule Tiannara.Sentinel.MathematicalEvidenceTest do
  use ExUnit.Case, async: true
  alias Tiannara.Sentinel.MathematicalEvidence

  setup do
    start_supervised!(MathematicalEvidence)
    :ok
  end

  test "retains refuted civilization reasoning" do
    assert {:ok, record} = MathematicalEvidence.store(%{
      kind: :scientific_reasoning,
      statement: "candidate causal explanation",
      artifact: %{reasoning_steps: [:observe, :hypothesize, :test]},
      status: :refuted,
      evidence: %{failure_point: :counterexample},
      provenance: %{world_id: "world-1", civilization_id: "civ-1"}
    })
    assert record.status == :refuted
  end

  test "supports parent-linked evidence lineage" do
    assert {:ok, parent} = MathematicalEvidence.store(%{
      kind: :theorem, statement: "P", artifact: %{origin: :civilization},
      status: :conjecture, provenance: %{world_id: "world-2"}
    })
    assert {:ok, child} = MathematicalEvidence.store(%{
      kind: :proof, statement: "P", artifact: %{proof_steps: [1]},
      status: :rejected, parent_ids: [parent.id],
      provenance: %{world_id: "world-2"}
    })
    assert child.parent_ids == [parent.id]
    assert is_binary(child.hash)
  end

  test "retains superseded knowledge" do
    assert {:ok, record} = MathematicalEvidence.store(%{
      kind: :theorem, statement: "old model",
      artifact: %{reasoning: [:a, :b]}, status: :superseded,
      provenance: %{world_id: "world-3"}
    })
    assert record.status == :superseded
  end
end
