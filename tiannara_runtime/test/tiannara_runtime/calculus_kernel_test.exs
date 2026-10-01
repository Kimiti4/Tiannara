defmodule TiannaraRuntime.Mathematics.CalculusKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.CalculusKernel

  test "power rule differentiates x^3 exactly" do
    assert {:ok, derivative, []} =
      CalculusKernel.differentiate({:pow, {:var, :x}, 3}, :x)

    assert derivative ==
      {:mul, {:constant, 3}, {:pow, {:var, :x}, 2}}
  end

  test "product rule is explicit" do
    expression = {:mul, {:var, :x}, {:sin, {:var, :x}}}

    assert {:ok, derivative, []} =
      CalculusKernel.differentiate(expression, :x)

    assert derivative ==
      {:add,
       {:mul, {:constant, 1}, {:sin, {:var, :x}}},
       {:mul, {:var, :x}, {:cos, {:var, :x}}}}
  end

  test "logarithm differentiation carries a domain condition" do
    assert {:ok, _derivative, conditions} =
      CalculusKernel.differentiate({:ln, {:var, :x}}, :x)

    assert {:domain, {:var, :x}, :positive} in conditions
  end

  test "unsupported syntax fails closed" do
    assert {:error, :unsupported_expression} =
      CalculusKernel.differentiate({:unknown, :x}, :x)
  end
end
