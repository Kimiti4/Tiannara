defmodule TiannaraRuntime.Mathematics.CalculusKernel do
  @moduledoc """
  Small exact symbolic differentiation kernel.

  Expressions use the explicit AST shared by the symbolic substrate. Derivative
  rules produce symbolic results; domain-sensitive rules carry side conditions.
  """

  def differentiate({:constant, _}, _variable), do: {:ok, {:constant, 0}, []}
  def differentiate({:var, variable}, variable), do: {:ok, {:constant, 1}, []}
  def differentiate({:var, _}, _variable), do: {:ok, {:constant, 0}, []}

  def differentiate({:add, a, b}, variable) do
    with {:ok, da, ca} <- differentiate(a, variable),
         {:ok, db, cb} <- differentiate(b, variable) do
      {:ok, {:add, da, db}, ca ++ cb}
    end
  end

  def differentiate({:mul, a, b}, variable) do
    with {:ok, da, ca} <- differentiate(a, variable),
         {:ok, db, cb} <- differentiate(b, variable) do
      {:ok, {:add, {:mul, da, b}, {:mul, a, db}}, ca ++ cb}
    end
  end

  def differentiate({:pow, {:var, variable}, n}, variable) when is_integer(n) and n >= 0 do
    {:ok, {:mul, {:constant, n}, {:pow, {:var, variable}, n - 1}}, []}
  end

  def differentiate({:pow, base, n}, variable) when is_integer(n) do
    with {:ok, db, conditions} <- differentiate(base, variable) do
      {:ok, {:mul, {:mul, {:constant, n}, {:pow, base, n - 1}}, db}, conditions}
    end
  end

  def differentiate({:neg, expression}, variable) do
    with {:ok, derivative, conditions} <- differentiate(expression, variable) do
      {:ok, {:neg, derivative}, conditions}
    end
  end

  def differentiate({:sin, expression}, variable) do
    with {:ok, derivative, conditions} <- differentiate(expression, variable) do
      {:ok, {:mul, {:cos, expression}, derivative}, conditions}
    end
  end

  def differentiate({:cos, expression}, variable) do
    with {:ok, derivative, conditions} <- differentiate(expression, variable) do
      {:ok, {:neg, {:mul, {:sin, expression}, derivative}}, conditions}
    end
  end

  def differentiate({:exp, expression}, variable) do
    with {:ok, derivative, conditions} <- differentiate(expression, variable) do
      {:ok, {:mul, {:exp, expression}, derivative}, conditions}
    end
  end

  def differentiate({:ln, expression}, variable) do
    with {:ok, derivative, conditions} <- differentiate(expression, variable) do
      {:ok, {:mul, {:pow, expression, -1}, derivative},
        [{:domain, expression, :positive} | conditions]}
    end
  end

  def differentiate(_, _), do: {:error, :unsupported_expression}
end
