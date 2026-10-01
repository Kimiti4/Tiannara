defmodule TiannaraRuntime.Mathematics.AlgebraKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.{AlgebraKernel, FormalAST}

  test "commutative addition normalizes identically" do
    x = FormalAST.variable("x", :real)
    y = FormalAST.variable("y", :real)
    assert {:ok, :proved, %{kernel: :algebra_v1}} =
             AlgebraKernel.equivalent(FormalAST.add(x, y), FormalAST.add(y, x))
  end

  test "unestablished equivalence is not called false" do
    x = FormalAST.variable("x", :real)
    y = FormalAST.variable("y", :real)
    assert {:ok, :not_established, %{kernel: :algebra_v1}} =
             AlgebraKernel.equivalent(x, y)
  end
end
