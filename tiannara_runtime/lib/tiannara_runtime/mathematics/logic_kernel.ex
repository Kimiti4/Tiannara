defmodule TiannaraRuntime.Mathematics.LogicKernel do
  @moduledoc """
  Small deterministic propositional proof kernel.

  It proves only formulas derivable by explicit natural-deduction-style rules.
  It does not infer truth from model scores or probabilistic confidence.
  """

  def prove({:implies, premise, conclusion}, assumptions \ []) do
    if member?(premise, assumptions) do
      {:ok, :proved, %{rule: :assumption}}
    else
      case prove(conclusion, [premise | assumptions]) do
        {:ok, :proved, evidence} -> {:ok, :proved, %{rule: :implication_intro, premise: premise, evidence: evidence}}
        other -> other
      end
    end
  end

  def prove({:and, left, right}, assumptions) do
    with {:ok, :proved, left_evidence} <- prove(left, assumptions),
         {:ok, :proved, right_evidence} <- prove(right, assumptions) do
      {:ok, :proved, %{rule: :and_intro, left: left_evidence, right: right_evidence}}
    end
  end

  def prove({:or, left, _right}, assumptions) do
    case prove(left, assumptions) do
      {:ok, :proved, evidence} -> {:ok, :proved, %{rule: :or_intro_left, evidence: evidence}}
      _ -> {:ok, :not_established, %{rule: :or_intro_requires_proof}}
    end
  end

  def prove({:not, proposition}, assumptions) do
    case prove({:implies, proposition, false}, assumptions) do
      {:ok, :proved, evidence} -> {:ok, :proved, %{rule: :negation_intro, evidence: evidence}}
      _ -> {:ok, :not_established, %{rule: :negation_not_derived}}
    end
  end

  def prove(proposition, assumptions) when is_list(assumptions) do
    if member?(proposition, assumptions),
      do: {:ok, :proved, %{rule: :assumption}},
      else: {:ok, :not_established, %{rule: :no_derivation}}
  end

  defp member?(term, assumptions), do: Enum.member?(assumptions, term)
end
