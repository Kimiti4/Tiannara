defmodule TiannaraRuntime.Mathematics.InequalityKernel do
  @moduledoc """
  Deterministic inequality/bound kernel.

  Establishes only explicitly supported monotonicity, non-negativity, and
  interval rules. Numerical sampling is never promoted to a proof.
  """

  def prove({:le, a, b}, assumptions \ []) do
    cond do
      a == b -> proved(:reflexivity)
      nonnegative?(a, assumptions) and nonnegative?(b, assumptions) and
          assumptions_include?(assumptions, {:le, a, b}) ->
        proved(:assumption)
      assumptions_include?(assumptions, {:le, a, b}) ->
        proved(:assumption)
      true ->
        {:ok, :not_established, %{rule: :inequality_kernel_no_rule}}
    end
  end

  def prove({:ge, a, b}, assumptions), do: prove({:le, b, a}, assumptions)
  def prove({:lt, a, b}, assumptions) when a != b, do: prove({:le, a, b}, assumptions)
  def prove(_, _), do: {:ok, :not_established, %{rule: :unsupported_inequality}}


  def bound(expr, {:interval, lower, upper}, assumptions \ []) do
    cond do
      assumptions_include?(assumptions, {:le, lower, expr}) and
          assumptions_include?(assumptions, {:le, expr, upper}) ->
        {:ok, :proved, %{rule: :interval_assumption, lower: lower, upper: upper}}
      expr == lower and expr == upper ->
        {:ok, :proved, %{rule: :degenerate_interval}}
      true ->
        {:ok, :not_established, %{rule: :interval_not_established}}
    end
  end

  defp nonnegative?(x, assumptions), do: x == 0 or assumptions_include?(assumptions, {:le, 0, x})
  defp assumptions_include?(assumptions, item), do: Enum.member?(assumptions, item)
  defp proved(rule), do: {:ok, :proved, %{rule: rule}}
end
