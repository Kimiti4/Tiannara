defmodule TiannaraRuntime.Mathematics.RuleEngine do
  @moduledoc """
  Controlled mathematical transformation rules.

  A rule application creates a proof step candidate. It never marks the step
  proved; side conditions and independent verification remain mandatory.
  """

  def apply(:modus_ponens, [%{if: premise, then: conclusion}, premise], _context) do
    {:ok, step("modus_ponens", [premise], conclusion, [])}
  end

  def apply(:equality_transitivity, [{:eq, a, b}, {:eq, b, c}], _context) do
    {:ok, step("equality_transitivity", [{:eq, a, b}, {:eq, b, c}], {:eq, a, c}, [])}
  end

  def apply(:substitution, [{:eq, a, b}, expression], _context) do
    {:ok, step("substitution", [{:eq, a, b}, expression],
      substitute(expression, a, b), [])}
  end

  def apply(:add_zero, [expression], _context) do
    {:ok, step("add_zero", [expression], {:add, expression, {:constant, 0}}, [])}
  end

  def apply(:mul_one, [expression], _context) do
    {:ok, step("mul_one", [expression], {:mul, expression, {:constant, 1}}, [])}
  end

  def apply(rule, _inputs, _context),
    do: {:error, {:unsupported_rule_or_side_conditions, rule}}

  defp step(rule, inputs, output, side_conditions) do
    %{rule: rule, inputs: inputs, output: output,
      side_conditions: side_conditions, status: :generated,
      evidence_class: :proof_rule_application}
  end

  defp substitute(term, from, to) when term == from, do: to
  defp substitute({:add, a, b}, from, to),
    do: {:add, substitute(a, from, to), substitute(b, from, to)}
  defp substitute({:mul, a, b}, from, to),
    do: {:mul, substitute(a, from, to), substitute(b, from, to)}
  defp substitute({:neg, a}, from, to), do: {:neg, substitute(a, from, to)}
  defp substitute({:pow, a, n}, from, to), do: {:pow, substitute(a, from, to), n}
  defp substitute(term, _from, _to), do: term
end
