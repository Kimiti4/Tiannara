defmodule TiannaraRuntime.Mathematics.DifferentialKernel do
  @moduledoc """
  Evidence-bound symbolic first-derivative substrate.

  This layer derives exact derivatives only for explicitly supported forms.
  Numerical finite differences are treated as approximations, never proofs.
  """

  def derivative({:constant, _}, _variable), do: {:ok, {:constant, 0}}
  def derivative({:var, variable}, variable), do: {:ok, {:constant, 1}}
  def derivative({:var, _}, _), do: {:ok, {:constant, 0}}

  def derivative({:add, left, right}, variable) do
    with {:ok, dl} <- derivative(left, variable),
         {:ok, dr} <- derivative(right, variable) do
      {:ok, {:add, dl, dr}}
    end
  end

  def derivative({:mul, left, right}, variable) do
    with {:ok, dl} <- derivative(left, variable),
         {:ok, dr} <- derivative(right, variable) do
      {:ok, {:add, {:mul, dl, right}, {:mul, left, dr}}}
    end
  end

  def derivative({:pow, expression, exponent}, variable) when is_integer(exponent) do
    with {:ok, de} <- derivative(expression, variable) do
      {:ok, {:mul, {:mul, {:constant, exponent},
                     {:pow, expression, exponent - 1}}, de}}
    end
  end

  def derivative({:neg, expression}, variable) do
    with {:ok, de} <- derivative(expression, variable) do
      {:ok, {:neg, de}}
    end
  end

  def derivative(_, _), do: {:error, :unsupported_symbolic_form}

  def classify_approximation(%{method: :finite_difference, samples: samples})
      when is_integer(samples) and samples > 1 do
    {:ok, %{evidence_class: :approximate, samples: samples,
            certification_eligible: false}}
  end

  def classify_approximation(_), do: {:error, :approximation_evidence_required}
end
