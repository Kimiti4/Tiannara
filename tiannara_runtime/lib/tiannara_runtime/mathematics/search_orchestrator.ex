defmodule TiannaraRuntime.Mathematics.SearchOrchestrator do
  @moduledoc """
  Bounded, evidence-aware orchestration for mathematical candidate search.

  Search is explicitly exploratory. A candidate can survive filters or receive
  supporting/falsifying evidence, but the orchestrator never upgrades a
  candidate to theorem, discovery, novelty, or physical truth.
  """

  alias TiannaraRuntime.Mathematics.{MathematicalID, ConstraintEngine, InvariantEngine}

  def search(seed_candidates, constraints, evaluator, opts \ [])
      when is_list(seed_candidates) and is_list(constraints) and is_function(evaluator, 1) do
    budget = min(max(Keyword.get(opts, :budget, 32), 0), 256)
    candidates = Enum.take(seed_candidates, budget)
    filtered = ConstraintEngine.filter(candidates, constraints)

    evaluated =
      Enum.map(filtered, fn item ->
        candidate = item.candidate
        case item.status do
          :survives_constraints ->
            case evaluator.(candidate) do
              {:ok, result} ->
                %{candidate: candidate, constraints: item.constraint_results,
                  evaluation: result, search_status: :evaluated}
              {:falsified, evidence} ->
                %{candidate: candidate, constraints: item.constraint_results,
                  evaluation: %{status: :falsified, evidence: evidence},
                  search_status: :falsified}
              {:inconclusive, details} ->
                %{candidate: candidate, constraints: item.constraint_results,
                  evaluation: %{status: :inconclusive, details: details},
                  search_status: :inconclusive}
              {:error, reason} ->
                %{candidate: candidate, constraints: item.constraint_results,
                  evaluation: %{status: :unavailable, reason: reason},
                  search_status: :unavailable}
              other ->
                %{candidate: candidate, constraints: item.constraint_results,
                  evaluation: %{status: :invalid_evaluator_result, result: other},
                  search_status: :unavailable}
            end
          :rejected ->
            %{candidate: candidate, constraints: item.constraint_results,
              evaluation: nil, search_status: :constraint_rejected}
          _ ->
            %{candidate: candidate, constraints: item.constraint_results,
              evaluation: nil, search_status: :constraint_unresolved}
        end
      end)

    {:ok, %{
      search_id: "search_" <> MathematicalID.from_canonical_map(%{
        "candidates" => candidates, "constraints" => constraints, "budget" => budget
      }),
      budget: budget,
      results: evaluated,
      certification_eligible: false
    }}
  end

  def evaluate_invariant(candidate, states, checker) do
    InvariantEngine.check(candidate, states, checker)
  end

  def search(_, _, _, _), do: {:error, :invalid_search_request}
end
