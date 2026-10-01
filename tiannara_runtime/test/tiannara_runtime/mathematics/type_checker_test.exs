defmodule TiannaraRuntime.Mathematics.TypeCheckerTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.{FormalAST, TypeChecker, AssumptionEnvironment}

  test "checks numeric expression types" do
    x = FormalAST.variable("x", :real)
    {:ok, result} = TypeChecker.check(FormalAST.add(x, FormalAST.constant(1, :integer)))
    assert result.type == :real
  end

  test "division produces an explicit nonzero side condition" do
    x = FormalAST.variable("x", :real)
    {:ok, result} = TypeChecker.check(FormalAST.divide(FormalAST.constant(1, :real), x))
    assert [{:not_equal, ^x, {:const, 0, :integer}}] = result.side_conditions
  end

  test "logical predicates must be boolean" do
    x = FormalAST.variable("x", :real)
    assert {:error, :logical_operand_must_be_boolean} =
             TypeChecker.check(FormalAST.and_(x, x))
  end

  test "assumptions are scoped and explicit" do
    x = FormalAST.variable("x", :real)
    p = FormalAST.greater_than(x, FormalAST.constant(0, :real))
    env = AssumptionEnvironment.new() |> AssumptionEnvironment.assume(p)
    assert AssumptionEnvironment.contains?(env, p)
  end
end
