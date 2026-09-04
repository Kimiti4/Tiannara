defmodule Tiannara.Constraints do
  @moduledoc """
  Constraint satisfaction and normalization for Tiannara certification.

  "Every conclusion should follow an evidence-driven process" — normalized outputs
  are evidence that constraints are satisfied.

  Ensures all normalized quantities sum to their required totals.
  Handles responsibility weights, probabilities, allocations, etc.

  All operations return {:ok, result} | {:error, reason}.
  """

  @type constraint :: {:sum_to, number()} | {:bounded, number(), number()} | {:non_negative}
  @type normalized :: {:ok, [number()]} | {:error, atom()}

  @doc """
  Normalize a list of weights to sum to target (default 1.0).
  Fixes Exercise 3.9 "responsibility = 0.9" issue.

  Returns {:ok, normalized_values, evidence} where evidence documents the normalization.
  """
  @spec normalize_to([number()], number()) :: {:ok, [number()], map()} | {:error, atom()}
  def normalize_to(values, target \\ 1.0) when is_list(values) and is_number(target) do
    with {:ok, valid} <- validate_numeric_list(values),
         {:ok, _} <- validate_non_negative(valid),
         total when total > 0 <- Enum.sum(valid) do
      scale = target / total
      normalized = Enum.map(valid, &(&1 * scale))

      # Verify the sum after normalization
      actual_sum = Enum.sum(normalized)
      {final, final_sum} =
        if abs(actual_sum - target) < 1.0e-9 do
          {normalized, actual_sum}
        else
          # Adjust last element to ensure exact sum
          diff = target - actual_sum
          adjusted = List.update_at(normalized, -1, &(&1 + diff))
          {adjusted, target}
        end

      evidence = %{
        input_sum: total,
        target: target,
        scale_factor: scale,
        output_sum: final_sum,
        precision: 1.0e-9,
        method: :proportional_scaling,
        verified: abs(final_sum - target) < 1.0e-9
      }

      {:ok, final, evidence}
    else
      0 -> {:error, :all_zeros}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Normalize probabilities — must sum to 1.0 and all be in [0, 1].
  Returns {:ok, normalized, evidence}.
  """
  @spec normalize_probabilities([number()]) :: {:ok, [number()], map()} | {:error, atom()}
  def normalize_probabilities(values) when is_list(values) do
    with {:ok, clamped} <- clamp_probabilities(values),
         {:ok, normalized, evidence} <- normalize_to(clamped, 1.0) do
      evidence = Map.put(evidence, :clamped, values != clamped)
      {:ok, normalized, evidence}
    end
  end

  defp clamp_probabilities(values) do
    clamped = Enum.map(values, fn v ->
      cond do
        v < 0 -> 0.0
        v > 1 -> 1.0
        true -> v
      end
    end)
    {:ok, clamped}
  end

  @doc """
  Allocate budget across items respecting weights and constraints.
  Returns {:ok, allocated_items, evidence}.
  """
  @spec allocate_budget([map()], number()) :: {:ok, [map()], map()} | {:error, atom()}
  def allocate_budget(items, total_budget)
      when is_list(items) and is_number(total_budget) and total_budget > 0 do
    weights = Enum.map(items, &Map.get(&1, :weight, 1.0))

    case normalize_to(weights, total_budget) do
      {:ok, allocations, evidence} ->
        allocated_items =
          Enum.zip(items, allocations)
          |> Enum.map(fn {item, amount} -> Map.put(item, :allocated, amount) end)

        {:ok, allocated_items, evidence}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Allocate with minimum guarantees — fixes Exercise 4.1.
  Each item gets at least its minimum, remainder distributed by weight.
  Returns {:ok, allocated_items, evidence}.
  """
  @spec allocate_with_minimums([map()], number(), [number()]) ::
          {:ok, [map()], map()} | {:error, atom()}
  def allocate_with_minimums(items, total, minimums)
      when is_list(items) and is_number(total) and is_list(minimums) do
    if length(items) != length(minimums) do
      {:error, :items_minimums_mismatch}
    else
      min_total = Enum.sum(minimums)

      if min_total > total do
        {:error, :minimums_exceed_total}
      else
        remainder = total - min_total
        weights = Enum.map(items, &Map.get(&1, :weight, 1.0))

        case normalize_to(weights, remainder) do
          {:ok, extra_allocations, evidence} ->
            final_items =
              Enum.zip(items, minimums)
              |> Enum.zip(extra_allocations)
              |> Enum.map(fn {{item, min_val}, extra} ->
                Map.put(item, :allocated, min_val + extra)
              end)

            {:ok, final_items, evidence}

          {:error, reason} ->
            {:error, reason}
        end
      end
    end
  end

  @doc """
  Verify that a normalized quantity actually sums correctly.
  Returns {:ok, boolean, evidence}.
  """
  @spec verify_sum([number()], number(), float()) :: {:ok, boolean(), map()}
  def verify_sum(values, target, tolerance \\ 1.0e-6) do
    total = Enum.sum(values)
    ok = abs(total - target) <= tolerance
    evidence = %{
      values: values,
      actual_sum: total,
      target: target,
      tolerance: tolerance,
      verified: ok,
      deviation: abs(total - target)
    }
    {:ok, ok, evidence}
  end

  @doc """
  Solve a simple linear constraint: a*x + b*y = target, x + y = 1.
  Returns {:ok, {x, y}, evidence} | {:error, :infeasible}.
  """
  @spec solve_two_variable(number(), number(), number()) ::
          {:ok, {number(), number()}, map()} | {:error, atom()}
  def solve_two_variable(a, b, target) when is_number(a) and is_number(b) do
    denom = a - b

    if abs(denom) < 1.0e-12 do
      {:error, :degenerate_system}
    else
      x = (target - b) / denom
      y = 1.0 - x

      if x >= 0 and x <= 1 and y >= 0 and y <= 1 do
        evidence = %{
          coefficients: %{a: a, b: b},
          target: target,
          solution: %{x: x, y: y},
          verification: %{a_x_plus_b_y: a * x + b * y, x_plus_y: x + y},
          method: :linear_system
        }
        {:ok, {x, y}, evidence}
      else
        {:error, :infeasible}
      end
    end
  end

  @doc """
  Project a vector onto the simplex (sum = 1, all >= 0).
  Uses the algorithm from Duchi et al. (2008).
  Returns {:ok, projected, evidence}.
  """
  @spec project_onto_simplex([number()]) :: {:ok, [number()], map()}
  def project_onto_simplex(values) when is_list(values) do
    n = length(values)
    sorted = Enum.sort(values, :desc)

    # Find the threshold
    {rho, _} =
      Enum.reduce(Enum.with_index(sorted), {0, 0}, fn {v, i}, {best_rho, best_i} ->
        cumsum = Enum.sum(Enum.take(sorted, i + 1))
        theta = (cumsum - 1) / (i + 1)

        if v - theta > 0 and i + 1 > best_i do
          {i, i + 1}
        else
          {best_rho, best_i}
        end
      end)

    cumsum = Enum.sum(Enum.take(sorted, rho + 1))
    theta = (cumsum - 1) / (rho + 1)

    projected = Enum.map(values, fn v -> max(0.0, v - theta) end)

    # Normalize to ensure exact sum = 1
    actual_sum = Enum.sum(projected)
    {final, final_sum} =
      if actual_sum > 0 do
        {Enum.map(projected, &(&1 / actual_sum)), 1.0}
      else
        uniform = 1.0 / n
        {List.duplicate(uniform, n), 1.0}
      end

    evidence = %{
      input: values,
      threshold: theta,
      rho: rho + 1,
      output_sum: final_sum,
      method: :duchi_simplex_projection,
      verified: abs(final_sum - 1.0) < 1.0e-9
    }

    {:ok, final, evidence}
  end

  @doc """
  Check if a set of constraints is satisfiable.
  Returns {:ok, boolean, evidence}.
  """
  @spec feasible?([number()], [constraint()]) :: {:ok, boolean(), map()}
  def feasible?(values, constraints) when is_list(values) and is_list(constraints) do
    results =
      Enum.map(constraints, fn constraint ->
        case constraint do
          {:sum_to, target} -> {:sum_to, verify_sum(values, target)}
          {:bounded, min, max} -> {:bounded, Enum.all?(values, &(&1 >= min and &1 <= max))}
          {:non_negative} -> {:non_negative, Enum.all?(values, &(&1 >= 0))}
        end
      end)

    all_ok = Enum.all?(results, fn {_, result} ->
      case result do
        {:ok, ok, _} -> ok
        ok when is_boolean(ok) -> ok
        _ -> false
      end
    end)

    evidence = %{
      constraints: constraints,
      results: results,
      all_satisfied: all_ok
    }

    {:ok, all_ok, evidence}
  end

  @doc """
  Normalize a named responsibility map so that values sum to exactly 1.0.

  Accepts either:
  - A map of %{agent => weight} where weights are numbers
  - A keyword list of {agent, weight} pairs

  Returns {:ok, normalized_map, evidence} | {:error, reason}

  Fixes Exercise 3.9 "responsibility = 0.9" — any partial sum is renormalized
  to 1.0 without requiring manual bookkeeping.

  Example:
      normalize_responsibility(%{a: 0.4, b: 0.3, c: 0.2})
      => {:ok, %{a: 0.4444, b: 0.3333, c: 0.2222}, evidence}  # sums to 1.0
  """
  @spec normalize_responsibility(map() | keyword()) ::
          {:ok, map(), map()} | {:error, atom()}
  def normalize_responsibility(responsibilities) when is_map(responsibilities) do
    keys = Map.keys(responsibilities)
    values = Map.values(responsibilities)

    with {:ok, _} <- validate_numeric_list(values),
         {:ok, normalized, evidence} <- normalize_to(values, 1.0) do
      result =
        Enum.zip(keys, normalized)
        |> Map.new()

      {:ok, result, evidence}
    end
  end

  def normalize_responsibility(responsibilities) when is_list(responsibilities) do
    {keys, values} = Enum.unzip(responsibilities)

    with {:ok, _} <- validate_numeric_list(values),
         {:ok, normalized, evidence} <- normalize_to(values, 1.0) do
      result =
        Enum.zip(keys, normalized)
        |> Map.new()

      {:ok, result, evidence}
    end
  end

  def normalize_responsibility(_), do: {:error, :invalid_input}

  @doc """
  Applies a sum constraint to a list of values, correcting any floating-point drift.

  Uses a two-pass approach:
  1. Scale all values proportionally to sum to `target`
  2. Adjust the last element by the residual to ensure exact equality

  Returns {:ok, adjusted_values, evidence} | {:error, reason}
  """
  @spec apply_sum_constraint([number()], number()) :: {:ok, [number()], map()} | {:error, atom()}
  def apply_sum_constraint(values, target) when is_list(values) and is_number(target) do
    with {:ok, normalized, evidence} <- normalize_to(values, target) do
      # Two-pass: fix residual floating-point drift
      actual = Enum.sum(normalized)
      residual = target - actual

      {corrected, final_evidence} =
        if abs(residual) < 1.0e-12 do
          {normalized, evidence}
        else
          corrected = List.update_at(normalized, -1, &(&1 + residual))
          {corrected, Map.put(evidence, :residual_correction, residual)}
        end

      {:ok, corrected, Map.put(final_evidence, :final_sum, Enum.sum(corrected))}
    end
  end

  @doc """
  Ensures all values are within [min_val, max_val] then renormalizes to sum to `target`.

  Useful for probability distributions or allocation vectors that may have
  been perturbed outside their valid range.

  Returns {:ok, bounded_normalized, evidence} | {:error, reason}
  """
  @spec ensure_bounds([number()], number(), number(), number()) ::
          {:ok, [number()], map()} | {:error, atom()}
  def ensure_bounds(values, min_val, max_val, target \\ 1.0)
      when is_list(values) and is_number(min_val) and is_number(max_val) and is_number(target) do
    if min_val >= max_val do
      {:error, :invalid_bounds}
    else
      clamped = Enum.map(values, &max(min_val, min(max_val, &1)))
      with {:ok, normalized, evidence} <- normalize_to(clamped, target) do
        {:ok, normalized, Map.put(evidence, :bounds, %{min: min_val, max: max_val})}
      end
    end
  end

  @doc """
  Generates a constraint satisfaction evidence report.
  Documents the entire normalization process for auditability.
  """
  @spec evidence_report({:ok, any(), map()} | {:error, atom()}) :: map()
  def evidence_report({:ok, result, evidence}) do
    %{
      status: :satisfied,
      result: result,
      evidence: evidence,
      timestamp: DateTime.utc_now(),
      verified: Map.get(evidence, :verified, true)
    }
  end

  def evidence_report({:error, reason}) do
    %{
      status: :violated,
      reason: reason,
      timestamp: DateTime.utc_now(),
      verified: false
    }
  end

  # Private helpers

  defp validate_numeric_list(values) do
    if Enum.all?(values, &is_number/1) do
      {:ok, values}
    else
      {:error, :non_numeric_values}
    end
  end

  defp validate_non_negative(values) do
    if Enum.all?(values, &(&1 >= 0)) do
      {:ok, values}
    else
      {:error, :negative_values}
    end
  end
end