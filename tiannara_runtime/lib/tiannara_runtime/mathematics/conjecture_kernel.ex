defmodule TiannaraRuntime.Mathematics.ConjectureKernel do
  @moduledoc """
  Creates explicit conjectures from candidate symbolic relationships.

  A conjecture is never promoted to a theorem by successful examples alone.
  """

  alias TiannaraRuntime.Mathematics.SymbolicAlgebra

  def propose(statement, rationale, source_cases \ []) do
    {:ok, %{
      statement: statement,
      rationale: rationale,
      source_cases: source_cases,
      status: :conjecture,
      proof_status: :unproved,
      counterexample_status: :unsearched,
      certification_eligible: false
    }}
  end

  def test_special_cases(conjecture, cases) when is_map(conjecture) and is_list(cases) do
    results =
      Enum.map(cases, fn %{left: left, right: right} = case_data ->
        Map.put(case_data, :matches, SymbolicAlgebra.equivalent?(left, right))
      end)

    {:ok, %{conjecture | special_case_results: results,
            counterexample_status:
              if(Enum.any?(results, &(Map.get(&1, :matches) == false)),
                do: :counterexample_found,
                else: :not_falsified)}}
  end

  def promote_to_theorem(_conjecture),
    do: {:error, :independent_proof_required}
end
