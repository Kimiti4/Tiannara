defmodule TiannaraRuntime.Mathematics.AlgebraProofRules do
  @moduledoc """
  Proof-aware wrappers around exact polynomial transformations.

  Algebraic computation is separated from theorem certification.
  """

  alias TiannaraRuntime.Mathematics.PolynomialKernel

  def add(left, right) do
    with {:ok, result} <- PolynomialKernel.add(left, right) do
      {:ok, %{rule: :polynomial_addition, inputs: [left, right],
              output: result, status: :generated,
              evidence_class: :exact_symbolic_transformation}}
    end
  end

  def multiply(left, right) do
    with {:ok, result} <- PolynomialKernel.multiply(left, right) do
      {:ok, %{rule: :polynomial_multiplication, inputs: [left, right],
              output: result, status: :generated,
              evidence_class: :exact_symbolic_transformation}}
    end
  end

  def derivative(terms) do
    with {:ok, result} <- PolynomialKernel.derivative(terms) do
      {:ok, %{rule: :polynomial_derivative, inputs: [terms],
              output: result, status: :generated,
              evidence_class: :exact_symbolic_transformation}}
    end
  end
end
