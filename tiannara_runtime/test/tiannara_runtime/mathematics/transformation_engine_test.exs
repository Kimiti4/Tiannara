defmodule TiannaraRuntime.Mathematics.TransformationEngineTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.{FormalAST, TransformationEngine, EquivalenceEngine, AssumptionEnvironment}

  test "commutativity transformation is valid" do
    x = FormalAST.variable("x", :real)
    y = FormalAST.variable("y", :real)
    {:ok, result} = TransformationEngine.apply(:normalize_add, FormalAST.add(x, y), AssumptionEnvironment.new())
    assert result.status == :valid
    assert {:ok, :equivalent, _} = EquivalenceEngine.check(result.before, result.after)
  end

  test "unsupported transformation does not silently succeed" do
    x = FormalAST.variable("x", :real)
    assert {:error, {:unsupported_transformation, :sqrt_magic}} =
             TransformationEngine.apply(:sqrt_magic, x, AssumptionEnvironment.new())
  end

  test "unknown equivalence is not treated as false" do
    x = FormalAST.variable("x", :real)
    y = FormalAST.variable("y", :real)
    assert {:ok, :unknown, _} = EquivalenceEngine.check(x, y)
  end
end
