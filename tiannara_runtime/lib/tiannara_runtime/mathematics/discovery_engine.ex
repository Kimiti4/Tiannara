defmodule TiannaraRuntime.Mathematics.DiscoveryEngine do
  @moduledoc """
  Mathematical discovery layer.

  Generates candidate formulas and mathematical conjectures from symbolic
  structure. A generated formula is a hypothesis, never a theorem.
  """

  alias TiannaraRuntime.Mathematics.SymbolicEngine
  alias TiannaraRuntime.Mathematics.MathematicalID

  @max_candidates 64

  @doc """
  Search a bounded deterministic transformation space around a seed expression.

  Candidates require symbolic replay, counterexample search, and a formal proof
  before they can become mathematical theorems.
  """
  def discover(seed, opts \\ []) do
    variable = Keyword.get(opts, :variable, "x")
    budget = min(Keyword.get(opts, :budget, 16), @max_candidates)

    with {:ok, seed_expr} <- normalize_seed(seed),
         {:ok, candidates} <- generate_candidates(seed_expr, variable, budget) do
      {:ok, %{
        discovery_id: MathematicalID.from_canonical_map(%{
          "seed" => SymbolicEngine.expression_hash(seed_expr),
          "variable" => variable,
          "budget" => budget
        }),
        status: :candidate,
        evidence_class: :mathematical_derivation,
        certification_eligible: false,
        seed: seed_expr,
        candidates: candidates,
        proof_obligations: Enum.map(candidates, &proof_obligation/1)
      }}
    end
  end

  @doc "Derive a formula transformation without asserting that it is a theorem."
  def derive(seed, operation, variable \\ "x") do
    with {:ok, expr} <- normalize_seed(seed),
         {:ok, result} <- apply_operation(expr, operation, variable) do
      {:ok, %{
        status: :derived_candidate,
        operation: operation,
        input: expr,
        formula: result,
        proof_required: true,
        certification_eligible: false
      }}
    end
  end

  defp normalize_seed(%{__struct__: _} = expr), do: {:ok, expr}
  defp normalize_seed(_), do: {:error, :symbolic_expression_required}

  defp generate_candidates(seed, variable, budget) do
    [
      :simplify,
      :expand,
      :factor,
      :differentiate,
      :integrate,
      {:differentiate_twice, variable},
      {:differentiate_integrate, variable},
      {:integrate_differentiate, variable}
    ]
    |> Enum.take(budget)
    |> Enum.map(fn
      {:differentiate_twice, v} -> derive_candidate(seed, :differentiate_twice, v)
      {:differentiate_integrate, v} -> derive_candidate(seed, :differentiate_integrate, v)
      {:integrate_differentiate, v} -> derive_candidate(seed, :integrate_differentiate, v)
      op -> derive_candidate(seed, op, variable)
    end)
    |> collect_results([])
  end

  defp derive_candidate(seed, operation, variable) do
    case apply_operation(seed, operation, variable) do
      {:ok, formula} ->
        {:ok, %{
          candidate_id: MathematicalID.from_canonical_map(%{
            "input" => SymbolicEngine.expression_hash(seed),
            "operation" => operation,
            "formula" => SymbolicEngine.expression_hash(formula)
          }),
          operation: operation,
          formula: formula,
          status: :conjecture,
          uncertainty: 1.0
        }}
      {:error, reason} -> {:skip, reason}
    end
  end

  defp collect_results([], acc), do: {:ok, Enum.reverse(acc)}
  defp collect_results([{:ok, value} | rest], acc), do: collect_results(rest, [value | acc])
  defp collect_results([{:skip, _} | rest], acc), do: collect_results(rest, acc)

  defp apply_operation(expr, :simplify, _), do: SymbolicEngine.simplify(expr)
  defp apply_operation(expr, :expand, _), do: SymbolicEngine.expand(expr)
  defp apply_operation(expr, :factor, _), do: SymbolicEngine.factor(expr)
  defp apply_operation(expr, :differentiate, variable), do: SymbolicEngine.differentiate(expr, variable)
  defp apply_operation(expr, :integrate, variable), do: SymbolicEngine.integrate(expr, variable)

  defp apply_operation(expr, :differentiate_twice, variable) do
    with {:ok, first} <- SymbolicEngine.differentiate(expr, variable),
         {:ok, second} <- SymbolicEngine.differentiate(first, variable), do: {:ok, second}
  end

  defp apply_operation(expr, :differentiate_integrate, variable) do
    with {:ok, integrated} <- SymbolicEngine.integrate(expr, variable),
         {:ok, result} <- SymbolicEngine.differentiate(integrated, variable), do: {:ok, result}
  end

  defp apply_operation(expr, :integrate_differentiate, variable) do
    with {:ok, differentiated} <- SymbolicEngine.differentiate(expr, variable),
         {:ok, result} <- SymbolicEngine.integrate(differentiated, variable), do: {:ok, result}
  end

  defp proof_obligation(candidate) do
    %{
      candidate_id: candidate.candidate_id,
      required: [:symbolic_replay, :counterexample_search, :formal_proof],
      status: :unproven
    }
  end
end
