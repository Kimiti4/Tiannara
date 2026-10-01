defmodule TiannaraRuntime.Mathematics.CounterexampleKernel do
  @moduledoc """
  Records failed universal claims and counterexamples.

  A counterexample falsifies the tested universal claim only within its stated
  domain and assumptions; it does not automatically establish the negation of
  every related claim.
  """

  def record(statement, counterexample, domain, evidence) when is_map(evidence) do
    {:ok, %{
      statement: statement,
      counterexample: counterexample,
      domain: domain,
      evidence: evidence,
      status: :counterexample_recorded,
      claim_status: :falsified_for_stated_domain,
      certification_eligible: false
    }}
  end

  def test_universal(_statement, []),
    do: {:error, :counterexample_search_requires_cases}

  def test_universal(statement, cases) when is_list(cases) do
    case Enum.find(cases, &Map.get(&1, :violates_claim, false)) do
      nil ->
        {:ok, %{statement: statement, result: :no_counterexample_found,
                claim_status: :not_falsified, proof_status: :unproved,
                certification_eligible: false}}
      counterexample ->
        record(statement, Map.get(counterexample, :case), Map.get(counterexample, :domain),
          Map.get(counterexample, :evidence, %{}))
    end
  end
end
