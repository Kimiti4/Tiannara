defmodule TiannaraRuntime.Mathematics.ConjectureEngineTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.ConjectureEngine

  test "counterexample produces a constraint candidate" do
    {:ok, result} = ConjectureEngine.extract_constraint(:candidate_x, {:falsified, %{x: 3}})
    assert result.source == :counterexample
    assert result.status == :candidate_constraint
  end

  test "candidate is explicitly a conjecture, never a theorem" do
    {:ok, result} = ConjectureEngine.propose(:candidate_x, %{tests: 12})
    assert result.epistemic_status == :conjecture
    assert result.certification_eligible == false
  end

  test "refinement extracts falsification-derived constraints" do
    {:ok, result} = ConjectureEngine.refine([
      %{candidate: :a, evaluation: %{status: :falsified, evidence: %{case: 1}}},
      %{candidate: :b, evaluation: %{status: :inconclusive, details: %{}}}
    ])
    assert length(result.constraints) == 1
  end
end
