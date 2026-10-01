defmodule TiannaraRuntime.Mathematics.PolynomialKernel do
  @moduledoc """
  Exact polynomial transformations over a small explicit representation.

  Coefficients are numeric and exponents are non-negative integers. Operations
  return symbolic results; theorem status still requires independent proof.
  """

  def normalize(terms) when is_list(terms) do
    normalized =
      terms
      |> Enum.reduce(%{}, fn {power, coefficient}, acc ->
        Map.update(acc, power, coefficient, &(&1 + coefficient))
      end)
      |> Enum.reject(fn {_power, coefficient} -> coefficient == 0 end)
      |> Enum.sort_by(fn {power, _} -> power end)

    {:ok, normalized}
  end

  def add(left, right) when is_list(left) and is_list(right),
    do: normalize(left ++ right)

  def multiply(left, right) when is_list(left) and is_list(right) do
    left
    |> Enum.flat_map(fn {p1, c1} ->
      Enum.map(right, fn {p2, c2} -> {p1 + p2, c1 * c2} end)
    end)
    |> normalize()
  end

  def derivative(terms) when is_list(terms) do
    terms
    |> Enum.flat_map(fn
      {0, _coefficient} -> []
      {power, coefficient} -> [{power - 1, power * coefficient}]
    end)
    |> normalize()
  end

  def evaluate(terms, x) when is_list(terms) and is_number(x) do
    {:ok, Enum.reduce(terms, 0, fn {power, coefficient}, acc ->
      acc + coefficient * :math.pow(x, power)
    end)}
  end
end
