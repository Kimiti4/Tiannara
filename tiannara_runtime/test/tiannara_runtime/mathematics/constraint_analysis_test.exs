defmodule TiannaraRuntime.Mathematics.ConstraintEngineTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.{ConstraintEngine, DimensionalAnalysis, InvariantEngine}

  test "constraints distinguish surviving candidates from proof" do
    candidate = %{typing: %{type: :real, side_conditions: []}, expression: :x}
    [result] = ConstraintEngine.filter([candidate], [{:requires_type, :real}, {:requires_no_side_conditions}])
    assert result.status == :survives_constraints
  end

  test "dimensionally incompatible addition is rejected" do
    meter = DimensionalAnalysis.quantity(1, %{length: 1})
    second = DimensionalAnalysis.quantity(1, %{time: 1})
    assert {:error, :incompatible_dimensions} = DimensionalAnalysis.add(meter, second)
  end

  test "invariant checker requires a real checker and preserves epistemic uncertainty" do
    assert {:error, :invariant_checker_unavailable} =
             InvariantEngine.check(:energy, [], nil)

    checker = fn _, _ -> {:preserved, %{tests: 10}} end
    {:ok, result} = InvariantEngine.check(:energy, [:a, :b], checker)
    assert result.status == :candidate_supported
    assert result.certification_eligible == false
  end
end
