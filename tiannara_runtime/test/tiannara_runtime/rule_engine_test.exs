defmodule TiannaraRuntime.Mathematics.RuleEngineTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.RuleEngine

  test "modus ponens creates a generated step" do
    implication = %{if: :a, then: :b}
    assert {:ok, step} = RuleEngine.apply(:modus_ponens, [implication, :a], %{})
    assert step.output == :b
    assert step.status == :generated
  end

  test "substitution is explicit and auditable" do
    expression = {:add, {:var, :x}, {:constant, 1}}
    assert {:ok, step} =
      RuleEngine.apply(:substitution, [{:eq, {:var, :x}, {:var, :y}}, expression], %{})
    assert step.output == {:add, {:var, :y}, {:constant, 1}}
  end

  test "unsupported transformations fail closed" do
    assert {:error, {:unsupported_rule_or_side_conditions, :division}} =
      RuleEngine.apply(:division, [:a, :b], %{})
  end
end
