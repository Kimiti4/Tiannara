defmodule Tiannara.Math.CounterexampleSearch do
  @moduledoc """
  Bounded falsification engine for mathematical conjectures.

  This module searches an explicitly supplied finite domain. Finding a
  counterexample refutes the conjecture over that domain and provides a
  concrete witness. Exhausting the supplied domain without finding one does
  NOT prove the conjecture globally.
  """

  @max_cases 1_000_000

  @type result :: %{
          status: :counterexample_found | :no_counterexample_in_domain,
          tested_cases: non_neg_integer(),
          domain_size: non_neg_integer(),
          witness: term() | nil,
          domain: term(),
          search_complete: boolean(),
          strategy: :exhaustive,
          global_proof: false,
          certification_eligible: false
        }

  @spec exhaustive([term()], (term() -> boolean())) :: {:ok, result()} | {:error, term()}
  def exhaustive(domain, conjecture) when is_list(domain) and is_function(conjecture, 1) do
    with :ok <- validate_domain(domain),
         :ok <- validate_unique_domain(domain) do
      search(domain, conjecture, 0)
    end
  rescue
    FunctionClauseError -> {:error, :conjecture_evaluation_failed}
    ArithmeticError -> {:error, :conjecture_evaluation_failed}
  end

  def exhaustive(_, _), do: {:error, :invalid_counterexample_search_input}

  defp search([], _conjecture, tested) do
    {:ok, %{
      status: :no_counterexample_in_domain,
      tested_cases: tested,
      domain_size: tested,
      witness: nil,
      domain: :exhausted_supplied_domain,
      search_complete: true,
      strategy: :exhaustive,
      global_proof: false,
      certification_eligible: false
    }}
  end

  defp search([candidate | rest], conjecture, tested) do
    case conjecture.(candidate) do
      true ->
        search(rest, conjecture, tested + 1)

      false ->
        {:ok, %{
          status: :counterexample_found,
          tested_cases: tested + 1,
          domain_size: tested + 1 + length(rest),
          witness: candidate,
          domain: :supplied_finite_domain,
          search_complete: false,
          strategy: :exhaustive,
          global_proof: false,
          certification_eligible: false
        }}

      _ ->
        {:error, :conjecture_must_return_boolean}
    end
  end

  defp validate_domain(domain) do
    if length(domain) <= @max_cases, do: :ok, else: {:error, :domain_too_large}
  end

  defp validate_unique_domain(domain) do
    if length(domain) == MapSet.size(MapSet.new(domain)),
      do: :ok,
      else: {:error, :duplicate_domain_element}
  end
end
