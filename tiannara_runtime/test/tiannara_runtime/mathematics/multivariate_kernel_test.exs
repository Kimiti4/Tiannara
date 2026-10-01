defmodule TiannaraRuntime.Mathematics.MultivariateKernelTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.MultivariateKernel

  test "computes symbolic partial derivatives" do
    expression = {:add, {:mul, {:var, :x}, {:var, :y}}, {:pow, {:var, :y}, 2}}
    assert {:ok, _} = MultivariateKernel.partial(expression, :x)
    assert {:ok, _} = MultivariateKernel.partial(expression, :y)
  end

  test "constructs a symbolic Jacobian" do
    expressions = [
      {:mul, {:var, :x}, {:var, :y}},
      {:pow, {:var, :x}, 2}
    ]

    assert {:ok, %{matrix: matrix, evidence_class: :symbolic}} =
      MultivariateKernel.jacobian(expressions, [:x, :y])

    assert length(matrix) == 2
    assert Enum.all?(matrix, &(length(&1) == 2))
  end

  test "sensitivity is an interpretation of a derivative, not a real-world claim" do
    {:ok, jacobian} =
      MultivariateKernel.jacobian([{:mul, {:var, :x}, {:var, :y}}], [:x, :y])

    assert {:ok, %{interpretation: :local_symbolic_sensitivity}} =
      MultivariateKernel.sensitivity(jacobian, 0, 0)
  end
end
