defmodule TiannaraRuntime.Mathematics.MultivariateKernel do
  @moduledoc """
  Symbolic partial derivatives and Jacobians for the supported expression AST.

  Outputs are mathematical derivations, not claims about a real system.
  Applicability to reality requires separate model and observation evidence.
  """

  alias TiannaraRuntime.Mathematics.DifferentialKernel

  def partial(expression, variable) do
    DifferentialKernel.derivative(expression, variable)
  end

  def jacobian(expressions, variables) when is_list(expressions) and is_list(variables) do
    rows =
      Enum.map(expressions, fn expression ->
        Enum.map(variables, fn variable ->
          case partial(expression, variable) do
            {:ok, derivative} -> derivative
            {:error, reason} -> {:unsupported, reason}
          end
        end)
      end)

    if Enum.any?(rows, fn row -> Enum.any?(row, &match?({:unsupported, _}, &1)) end) do
      {:error, :jacobian_contains_unsupported_derivative}
    else
      {:ok, %{matrix: rows, variables: variables, evidence_class: :symbolic}}
    end
  end

  def sensitivity(jacobian, variable_index, output_index) do
    case get_in(jacobian, [:matrix, Access.at(output_index), Access.at(variable_index)]) do
      nil -> {:error, :sensitivity_index_out_of_bounds}
      derivative -> {:ok, %{derivative: derivative, interpretation: :local_symbolic_sensitivity}}
    end
  end
end
