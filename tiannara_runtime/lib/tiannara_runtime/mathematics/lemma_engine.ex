defmodule TiannaraRuntime.Mathematics.LemmaEngine do
  @moduledoc """
  Generates bounded lemma candidates from a mathematical problem or conjecture.

  Lemmas are intermediate hypotheses. They are never accepted as true merely
  because they simplify a target problem.
  """

  alias TiannaraRuntime.Mathematics.MathematicalID

  @operations [:specialize, :generalize, :decompose, :invariant, :boundary_case, :symmetry]

  @spec generate(map(), keyword()) :: {:ok, map()} | {:error, term()}
  def generate(problem, opts \ []) when is_map(problem) do
    statement = Map.get(problem, :statement) || Map.get(problem, "statement")
    if is_binary(statement) and statement != "" do
      budget = min(Keyword.get(opts, :budget, 12), 32)
      candidates =
        @operations
        |> Enum.take(budget)
        |> Enum.map(fn operation ->
          id = MathematicalID.from_canonical_map(%{
            "problem" => statement,
            "operation" => operation
          })

          %{
            lemma_id: "lemma_" <> id,
            operation: operation,
            statement: lemma_statement(operation, statement),
            status: :candidate,
            proof_required: true,
            uncertainty: 1.0,
            certification_eligible: false
          }
        end)

      {:ok, %{status: :candidate, problem: statement, candidates: candidates,
              certification_eligible: false}}
    else
      {:error, :mathematical_problem_statement_required}
    end
  end

  defp lemma_statement(:specialize, s), do: "Special case of: #{s}"
  defp lemma_statement(:generalize, s), do: "Generalization candidate of: #{s}"
  defp lemma_statement(:decompose, s), do: "Decomposition candidate for: #{s}"
  defp lemma_statement(:invariant, s), do: "Invariant candidate for: #{s}"
  defp lemma_statement(:boundary_case, s), do: "Boundary-case lemma candidate for: #{s}"
  defp lemma_statement(:symmetry, s), do: "Symmetry lemma candidate for: #{s}"
end
