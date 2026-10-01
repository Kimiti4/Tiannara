defmodule TiannaraRuntime.Mathematics.InvariantEngine do
  @moduledoc """
  Searches for explicitly supplied candidate invariants using a real checker.

  An invariant is never accepted because it has a plausible name or because a
  few observations happen to preserve it.
  """

  def check(candidate, states, checker) when is_function(checker, 2) and is_list(states) do
    case checker.(candidate, states) do
      {:preserved, evidence} ->
        {:ok, %{status: :candidate_supported, candidate: candidate,
                evidence: evidence, certification_eligible: false}}
      {:violated, counterexample} ->
        {:ok, %{status: :falsified, candidate: candidate,
                counterexample: counterexample, certification_eligible: false}}
      {:inconclusive, details} ->
        {:ok, %{status: :inconclusive, candidate: candidate,
                details: details, certification_eligible: false}}
      {:error, reason} ->
        {:error, reason}
      other ->
        {:error, {:invalid_invariant_checker_result, other}}
    end
  end

  def check(_, _, _), do: {:error, :invariant_checker_unavailable}
end
