defmodule TiannaraRuntime.Mathematics.ProofPlanner do
  @moduledoc """
  Bounded proof-strategy planning over explicit mathematical assertions.

  Planning proposes routes and obligations. It never proves an assertion.
  """

  alias TiannaraRuntime.Mathematics.MathematicalID

  @strategies [:direct, :lemma_application, :substitution, :contradiction,
               :contraposition, :induction, :constructive, :invariant, :case_split]

  def plan(assertion, opts \ []) when is_binary(assertion) and assertion != "" do
    strategies = Keyword.get(opts, :strategies, @strategies)
    budget = min(max(Keyword.get(opts, :budget, 8), 1), 32)
    selected = strategies |> Enum.filter(&(&1 in @strategies)) |> Enum.take(budget)

    if selected == [] do
      {:error, :no_valid_proof_strategy}
    else
      root = MathematicalID.from_canonical_map(%{"assertion" => assertion, "strategies" => selected})
      obligations = Enum.map(selected, fn strategy ->
        id = MathematicalID.from_canonical_map(%{"root" => root, "strategy" => strategy})
        %{obligation_id: "obligation_" <> id, statement: assertion,
          strategy: strategy, status: :unproven, proof_required: true}
      end)

      {:ok, %{proof_plan_id: "plan_" <> root, assertion: assertion,
              strategies: selected, obligations: obligations,
              status: :proposed, certification_eligible: false}}
    end
  end

  def plan(_, _), do: {:error, :mathematical_assertion_required}

  def execute_strategy(strategy, _context) when strategy in @strategies,
    do: {:unavailable, {:proof_backend_required, strategy}}
  def execute_strategy(strategy, _), do: {:error, {:unsupported_strategy, strategy}}
end
