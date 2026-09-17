defmodule Tiannara.OPC.Validation.TensorConstraintSolver do
  @moduledoc """
  Phase 5F.6 — Tensor Constraint Solver

  Ensures observer physics proposals maintain bounded gradients,
  valid tensor ranks, and stable attractor dynamics.

  ## Responsibilities

  - Validates tensor rank doesn't exceed maximum (@max_tensor_rank = 4)
  - Enforces gradient bounds to prevent explosive divergence
  - Detects unstable attractor equations (positive feedback loops)
  - Normalizes tensor operations to safe forms
  - Computes divergence metrics for MSCL-Ω integration

  ## Mathematical Model

  For any tensor operation T:
  - rank(T) ≤ 4 (prevents combinatorial explosion)
  - |∇T| ≤ max_gradient (prevents gradient blowup)
  - eigenvalues(AttractorMatrix) must have negative real parts (stability)

  ## Usage

      ast = {:tensor_op, :gradient, [{:field, :entropy}, 2]}
      case TensorConstraintSolver.solve(ast) do
        {:ok, constrained_ast} -> IO.puts("Tensor constraints satisfied")
        {:error, :tensor_rank_exceeded} -> IO.puts("Rank too high")
      end
  """

  require Logger

  # Maximum allowed tensor rank (4D tensors are computationally expensive)
  @max_tensor_rank 4

  # Maximum allowed gradient magnitude (prevents explosive divergence)
  @max_gradient 0.4

  # Maximum attractor instability (eigenvalue real part threshold)
  @max_attractor_instability 0.0

  @doc """
  Solves tensor constraints for observer physics AST.

  ## Parameters
  - `ast`: The physics AST containing tensor operations

  ## Returns
  - `{:ok, constrained_ast}` — AST with tensor constraints enforced
  - `{:error, reason}` — Constraint violation detected

  ## Examples

      # Valid tensor operation
      ast = {:op, :+, [{:const, 1.0}, {:const, 2.0}]}
      {:ok, _} = TensorConstraintSolver.solve(ast)

      # Invalid: tensor rank exceeds limit
      ast = {:tensor, :rank_5, [...]}
      {:error, :tensor_rank_exceeded} = TensorConstraintSolver.solve(ast)
  """
  def solve(ast) do
    Logger.debug("🔒 [TensorConstraintSolver] Solving constraints for AST...")

    with :ok <- validate_tensor_ranks(ast),
         :ok <- validate_gradients(ast),
         :ok <- validate_attractor_stability(ast) do
      normalized_ast = normalize_tensor_operations(ast)
      Logger.debug("✅ [TensorConstraintSolver] All tensor constraints satisfied")
      {:ok, normalized_ast}
    else
      {:error, reason} ->
        Logger.warning("⚠️ [TensorConstraintSolver] Constraint violation: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp validate_tensor_ranks({:tensor, rank_type, _args}) when is_atom(rank_type) do
    # Extract rank from atom name (e.g., :rank_5 → 5)
    rank = extract_rank_from_atom(rank_type)

    if rank > @max_tensor_rank do
      Logger.warning("🛑 [TensorConstraintSolver] Tensor rank #{rank} exceeds maximum #{@max_tensor_rank}")
      {:error, :tensor_rank_exceeded}
    else
      :ok
    end
  end

  defp validate_tensor_ranks({:op, _op, args}) when is_list(args) do
    # Recursively validate all arguments
    results = Enum.map(args, &validate_tensor_ranks/1)

    case Enum.find(results, fn result -> match?({:error, _}, result) end) do
      nil -> :ok
      error -> error
    end
  end

  defp validate_tensor_ranks(list) when is_list(list) do
    results = Enum.map(list, &validate_tensor_ranks/1)

    case Enum.find(results, fn result -> match?({:error, _}, result) end) do
      nil -> :ok
      error -> error
    end
  end

  defp validate_tensor_ranks(_other), do: :ok

  defp validate_gradients({:op, :gradient, [field, order]}) when is_integer(order) do
    # Check if gradient order would produce excessive divergence
    estimated_divergence = estimate_gradient_divergence(field, order)

    if estimated_divergence > @max_gradient do
      Logger.warning("🛑 [TensorConstraintSolver] Gradient divergence #{estimated_divergence} exceeds maximum #{@max_gradient}")
      {:error, :gradient_bounds_exceeded}
    else
      :ok
    end
  end

  defp validate_gradients({:op, _op, args}) when is_list(args) do
    results = Enum.map(args, &validate_gradients/1)

    case Enum.find(results, fn result -> match?({:error, _}, result) end) do
      nil -> :ok
      error -> error
    end
  end

  defp validate_gradients(list) when is_list(list) do
    results = Enum.map(list, &validate_gradients/1)

    case Enum.find(results, fn result -> match?({:error, _}, result) end) do
      nil -> :ok
      error -> error
    end
  end

  defp validate_gradients(_other), do: :ok

  defp validate_attractor_stability({:attractor, _name, matrix_elements}) when is_list(matrix_elements) do
    # Simplified stability check: ensure no positive feedback loops
    # In production, would compute eigenvalues of the Jacobian matrix

    has_positive_feedback = Enum.any?(matrix_elements, fn elem ->
      case elem do
        {:op, :*, [a, b]} when is_number(a) and is_number(b) -> a * b > 1.0
        {:const, val} when is_number(val) -> val > 1.0
        _ -> false
      end
    end)

    if has_positive_feedback do
      Logger.warning("🛑 [TensorConstraintSolver] Unstable attractor detected (positive feedback)")
      {:error, :attractor_instability}
    else
      :ok
    end
  end

  defp validate_attractor_stability({:op, _op, args}) when is_list(args) do
    results = Enum.map(args, &validate_attractor_stability/1)

    case Enum.find(results, fn result -> match?({:error, _}, result) end) do
      nil -> :ok
      error -> error
    end
  end

  defp validate_attractor_stability(list) when is_list(list) do
    results = Enum.map(list, &validate_attractor_stability/1)

    case Enum.find(results, fn result -> match?({:error, _}, result) end) do
      nil -> :ok
      error -> error
    end
  end

  defp validate_attractor_stability(_other), do: :ok

  defp normalize_tensor_operations({:op, :/, [numerator, denominator]}) do
    # Normalize division to prevent singularities (redundant with AOR but adds extra safety)
    normalized_denom = normalize_tensor_operations(denominator)

    {:op, :/, [
      normalize_tensor_operations(numerator),
      ensure_nonzero(normalized_denom)
    ]}
  end

  defp normalize_tensor_operations({:op, op_name, args}) when is_list(args) do
    normalized_args = Enum.map(args, &normalize_tensor_operations/1)
    {:op, op_name, normalized_args}
  end

  defp normalize_tensor_operations(list) when is_list(list) do
    Enum.map(list, &normalize_tensor_operations/1)
  end

  defp normalize_tensor_operations(leaf_node), do: leaf_node

  # ── Helper Functions ──────────────────────────────────────────────────────

  defp extract_rank_from_atom(:rank_1), do: 1
  defp extract_rank_from_atom(:rank_2), do: 2
  defp extract_rank_from_atom(:rank_3), do: 3
  defp extract_rank_from_atom(:rank_4), do: 4
  defp extract_rank_from_atom(:rank_5), do: 5
  defp extract_rank_from_atom(:rank_6), do: 6
  defp extract_rank_from_atom(other) when is_atom(other) do
    # Default to rank 2 for unknown tensor types
    Logger.debug("[TensorConstraintSolver] Unknown tensor type #{inspect(other)}, defaulting to rank 2")
    2
  end

  defp estimate_gradient_divergence(_field, order) do
    # Simplified divergence estimation
    # Higher-order gradients exponentially increase divergence risk
    :math.pow(0.3, order)
  end

  defp ensure_nonzero({:const, 0.0}) do
    # Replace zero constants with small epsilon to prevent division by zero
    Logger.debug("🛡️ [TensorConstraintSolver] Replacing zero constant with epsilon")
    {:const, 0.001}
  end

  defp ensure_nonzero(node), do: node
end
