defmodule TiannaraRuntime.Mathematics.ProofPlanner do
  @moduledoc """
  Decomposes a mathematical assertion into auditable proof obligations.

  Planning is not proving. Every generated obligation remains unproven until
  an actual proof step and independent verifier establish it.
  """

  alias TiannaraRuntime.Mathematics.MathematicalID

  @strategies [:direct, :contradiction, :induction, :constructive, :computational]

  def plan(assertion, opts \ []) when is_binary(assertion) and assertion != "" do
    strategy = Keyword.get(opts, :strategy, :direct)
    budget = min(Keyword.get(opts, :budget, 8), 32)

    if strategy in @strategies do
      root = MathematicalID.from_canonical_map(%{
        "assertion" => assertion,
        "strategy" => strategy
      })

      obligations =
        Enum.map(1..budget, fn n ->
          id = MathematicalID.from_canonical_map(%{
            "root" => root,
            "sequence" => n,
            "strategy" => strategy
          })

          %{
            obligation_id: "obligation_" <> id,
            sequence: n,
            statement: "Proof obligation #{n} for: #{assertion}",
            parent_obligation: if(n == 1, do: nil, else: "obligation_#{root}_#{n - 1}"),
            status: :unproven,
            strategy: strategy,
            proof_required: true
          }
        end)

      {:ok, %{
        proof_plan_id: "plan_" <> root,
        assertion: assertion,
        strategy: strategy,
        obligations: obligations,
        status: :unproven,
        certification_eligible: false
      }}
    else
      {:error, :invalid_proof_strategy}
    end
  end

  def plan(_, _), do: {:error, :mathematical_assertion_required}
end
