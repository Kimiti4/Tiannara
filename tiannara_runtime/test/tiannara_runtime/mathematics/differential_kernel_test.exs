defmodule TiannaraRuntime.Mathematics.DifferentialKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.DifferentialKernel

  test "derivative of a variable is one" do
    assert {:ok, {:constant, 1}} = DifferentialKernel.derivative({:var, :x}, :x)
  end

  test "product rule is represented explicitly" do
    expression = {:mul, {:var, :x}, {:var, :x}}
    assert {:ok, {:add, _, _}} = DifferentialKernel.derivative(expression, :x)
  end

  test "power rule derives integer powers" do
    assert {:ok, {:mul, {:mul, {:constant, 3}, {:pow, {:var, :x}, 2}}, {:constant, 1}}} =
      DifferentialKernel.derivative({:pow, {:var, :x}, 3}, :x)
  end

  test "finite differences remain approximate evidence" do
    assert {:ok, %{evidence_class: :approximate, certification_eligible: false}} =
      DifferentialKernel.classify_approximation(%{method: :finite_difference, samples: 10})
  end
end
