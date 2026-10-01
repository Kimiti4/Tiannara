defmodule TiannaraRuntime.Mathematics.QuantifiedLogicKernel do
  @moduledoc """
  Deterministic quantified-logic layer over explicit finite domains.

  Quantifier proofs here are finite-domain derivations only. No finite
  enumeration is promoted to a universal theorem outside the declared domain.
  """

  def prove({:forall, variable, domain, proposition}, assumptions \ [])
      when is_list(domain) do
    results = Enum.map(domain, fn value ->
      prove(substitute(proposition, variable, value), assumptions)
    end)

    if Enum.all?(results, &match?({:ok, :proved, _}, &1)) do
      {:ok, :proved, %{rule: :finite_forall_intro, variable: variable, domain: domain, evidence: results}}
    else
      {:ok, :not_established, %{rule: :finite_forall_intro_failed, evidence: results}}
    end
  end

  def prove({:exists, variable, domain, proposition}, assumptions \ [])
      when is_list(domain) do
    case Enum.find(domain, fn value -> match?({:ok, :proved, _}, prove(substitute(proposition, variable, value), assumptions)) end) do
      nil -> {:ok, :not_established, %{rule: :finite_exists_intro_failed}}
      value ->
        {:ok, :proved, %{rule: :finite_exists_intro, variable: variable, witness: value}}
    end
  end

  def prove(proposition, assumptions) do
    TiannaraRuntime.Mathematics.LogicKernel.prove(proposition, assumptions)
  end

  defp substitute({:implies, a, b}, variable, value),
    do: {:implies, substitute(a, variable, value), substitute(b, variable, value)}
  defp substitute({:and, a, b}, variable, value),
    do: {:and, substitute(a, variable, value), substitute(b, variable, value)}
  defp substitute({:or, a, b}, variable, value),
    do: {:or, substitute(a, variable, value), substitute(b, variable, value)}
  defp substitute({:not, a}, variable, value),
    do: {:not, substitute(a, variable, value)}
  defp substitute({:eq, a, b}, variable, value),
    do: {:eq, substitute(a, variable, value), substitute(b, variable, value)}
  defp substitute({:var, variable}, variable, value), do: value
  defp substitute(term, _variable, _value), do: term
end
