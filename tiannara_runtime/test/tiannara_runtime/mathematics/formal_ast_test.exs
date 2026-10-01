defmodule TiannaraRuntime.Mathematics.FormalASTTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.FormalAST
  alias TiannaraRuntime.Mathematics.SideConditionEngine

  test "represents a quantified proposition structurally" do
    n = FormalAST.variable("n", :natural)
    proposition = FormalAST.greater_than(FormalAST.add(n, FormalAST.constant(1, :natural)), n)
    ast = FormalAST.forall(n, proposition)
    assert :ok == FormalAST.validate(ast)
  end

  test "rejects malformed formal AST" do
    assert {:error, :invalid_formal_ast} = FormalAST.validate({:wat, "x"})
  end

  test "side conditions remain unresolved without evidence" do
    x = FormalAST.variable("x", :real)
    bundle = SideConditionEngine.attach(FormalAST.divide(FormalAST.constant(1, :real), x), [
      SideConditionEngine.require_nonzero(x)
    ])
    assert SideConditionEngine.unresolved?(bundle)
    assert {:error, :side_condition_not_verified} =
             SideConditionEngine.discharge(bundle, hd(bundle.side_conditions), %{})
  end
end
