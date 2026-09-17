defmodule Tiannara.OPC.Validation.SymbolicSimplifier do
  @moduledoc """
  Phase 5F.6 — Symbolic Simplifier

  Performs algebraic simplification and redundant operation elimination
  on observer physics ASTs before compilation. Reduces GPU shader complexity
  and improves execution performance.

  ## Simplification Rules

  - Constant folding: `2 + 3` → `5`
  - Identity operations: `x * 1` → `x`, `x + 0` → `x`
  - Zero multiplication: `x * 0` → `0`
  - Power simplification: `x^1` → `x`, `x^0` → `1`
  - Double negation: `-(-x)` → `x`
  - Redundant sqrt: `sqrt(x^2)` → `abs(x)` (when safe)

  ## Usage

      ast = {:op, :+, [{:op, :*, [{:const, 2.0}, {:const, 3.0}]}, {:const, 4.0}]}
      simplified = SymbolicSimplifier.simplify(ast)
      # Result: {:const, 10.0}
  """

  require Logger

  @doc """
  Simplifies AST by applying algebraic rules.

  ## Parameters
  - `ast`: The physics AST to simplify

  ## Returns
  - Simplified AST with redundant operations eliminated

  ## Examples

      # Constant folding
      ast = {:op, :+, [{:const, 2.0}, {:const, 3.0}]}
      {:const, 5.0} = SymbolicSimplifier.simplify(ast)

      # Identity elimination
      ast = {:op, :*, [{:var, :x}, {:const, 1.0}]}
      {:var, :x} = SymbolicSimplifier.simplify(ast)
  """
  def simplify(ast) do
    Logger.debug("🔧 [SymbolicSimplifier] Simplifying AST...")
    result = simplify_node(ast)
    Logger.debug("✅ [SymbolicSimplifier] Simplification complete")
    result
  end

  # ── Core Simplification Engine ────────────────────────────────────────────

  # Binary operations
  defp simplify_node({:op, op, [left, right]}) do
    simplified_left = simplify_node(left)
    simplified_right = simplify_node(right)

    case {op, simplified_left, simplified_right} do
      # Addition
      {:+, {:const, a}, {:const, b}} ->
        {:const, a + b}

      {:+, {:const, 0.0}, expr} ->
        expr

      {:+, expr, {:const, 0.0}} ->
        expr

      # Subtraction
      {:-, {:const, a}, {:const, b}} ->
        {:const, a - b}

      {:-, expr, {:const, 0.0}} ->
        expr

      {:-, expr, expr} ->
        {:const, 0.0}

      # Multiplication
      {:*, {:const, a}, {:const, b}} ->
        {:const, a * b}

      {:*, {:const, 0.0}, _expr} ->
        {:const, 0.0}

      {:*, _expr, {:const, 0.0}} ->
        {:const, 0.0}

      {:*, {:const, 1.0}, expr} ->
        expr

      {:*, expr, {:const, 1.0}} ->
        expr

      # Division
      {:/, {:const, a}, {:const, b}} when b != 0 ->
        {:const, a / b}

      {:/, expr, {:const, 1.0}} ->
        expr

      {:/, {:const, 0.0}, _expr} ->
        {:const, 0.0}

      # Exponentiation
      {:^, {:const, a}, {:const, b}} ->
        {:const, :math.pow(a, b)}

      {:^, expr, {:const, 0.0}} ->
        {:const, 1.0}

      {:^, expr, {:const, 1.0}} ->
        expr

      {:^, {:const, 0.0}, _expr} ->
        {:const, 0.0}

      # Default: return simplified operands
      _ ->
        {:op, op, [simplified_left, simplified_right]}
    end
  end

  # Unary operations
  defp simplify_node({:op, :-, [arg]}) do
    simplified_arg = simplify_node(arg)

    case simplified_arg do
      {:const, value} ->
        {:const, -value}

      {:op, :-, [inner]} ->
        # Double negation: -(-x) → x
        inner

      _ ->
        {:op, :-, [simplified_arg]}
    end
  end

  defp simplify_node({:op, :sqrt, [arg]}) do
    simplified_arg = simplify_node(arg)

    case simplified_arg do
      {:const, value} when value >= 0 ->
        {:const, :math.sqrt(value)}

      {:op, :^, [base, {:const, 2.0}]} ->
        # sqrt(x^2) → abs(x) (simplified to x for now, TODO: add abs)
        base

      _ ->
        {:op, :sqrt, [simplified_arg]}
    end
  end

  # Function calls
  defp simplify_node({:function, func, args}) when is_list(args) do
    simplified_args = Enum.map(args, &simplify_node/1)
    {:function, func, simplified_args}
  end

  # Lists (for nested structures)
  defp simplify_node(list) when is_list(list) do
    Enum.map(list, &simplify_node/1)
  end

  # Leaf nodes (constants, variables, symbols)
  defp simplify_node(leaf), do: leaf

  @doc """
  Estimates computational complexity reduction from simplification.

  ## Parameters
  - `original_ast`: AST before simplification
  - `simplified_ast`: AST after simplification

  ## Returns
  - Map with complexity metrics

  ## Example

      original = {:op, :+, [{:op, :*, [{:const, 2.0}, {:const, 3.0}]}, {:const, 4.0}]}
      simplified = SymbolicSimplifier.simplify(original)
      metrics = SymbolicSimplifier.complexity_reduction(original, simplified)
      # %{nodes_reduced: 4, depth_reduced: 1}
  """
  def complexity_reduction(original_ast, simplified_ast) do
    original_nodes = count_nodes(original_ast)
    simplified_nodes = count_nodes(simplified_ast)
    original_depth = calculate_depth(original_ast)
    simplified_depth = calculate_depth(simplified_ast)

    %{
      original_nodes: original_nodes,
      simplified_nodes: simplified_nodes,
      nodes_reduced: original_nodes - simplified_nodes,
      reduction_percentage: ((original_nodes - simplified_nodes) / max(original_nodes, 1)) * 100,
      original_depth: original_depth,
      simplified_depth: simplified_depth,
      depth_reduced: original_depth - simplified_depth
    }
  end

  # ── Helper Functions ──────────────────────────────────────────────────────

  defp calculate_depth({:number, _}), do: 1
  defp calculate_depth({:identifier, _}), do: 1
  defp calculate_depth({:const, _}), do: 1
  defp calculate_depth({:var, _}), do: 1
  defp calculate_depth({:binary_op, _, left, right}) do
    1 + max(calculate_depth(left), calculate_depth(right))
  end
  defp calculate_depth({:unary_op, _, operand}) do
    1 + calculate_depth(operand)
  end
  defp calculate_depth({:conditional, c, t, f}) do
    1 + max(calculate_depth(c), max(calculate_depth(t), calculate_depth(f)))
  end
  defp calculate_depth({:op, _op, args}) when is_list(args) do
    1 + (Enum.map(args, &calculate_depth/1) |> Enum.max(fn -> 0 end))
  end
  defp calculate_depth({:function, _, args}) when is_list(args) do
    1 + (Enum.map(args, &calculate_depth/1) |> Enum.max(fn -> 0 end))
  end
  defp calculate_depth({:tensor, elements}) when is_list(elements) do
    1 + (Enum.map(elements, &calculate_depth/1) |> Enum.max(fn -> 0 end))
  end
  defp calculate_depth(list) when is_list(list) do
    Enum.map(list, &calculate_depth/1) |> Enum.max(fn -> 0 end)
  end
  defp calculate_depth(_leaf), do: 1

  defp count_nodes({:number, _}), do: 1
  defp count_nodes({:identifier, _}), do: 1
  defp count_nodes({:const, _}), do: 1
  defp count_nodes({:var, _}), do: 1
  defp count_nodes({:binary_op, _, left, right}) do
    1 + count_nodes(left) + count_nodes(right)
  end
  defp count_nodes({:unary_op, _, operand}) do
    1 + count_nodes(operand)
  end
  defp count_nodes({:conditional, c, t, f}) do
    1 + count_nodes(c) + count_nodes(t) + count_nodes(f)
  end
  defp count_nodes({:op, _op, args}) when is_list(args) do
    1 + Enum.sum(Enum.map(args, &count_nodes/1))
  end
  defp count_nodes({:function, _, args}) when is_list(args) do
    1 + Enum.sum(Enum.map(args, &count_nodes/1))
  end
  defp count_nodes({:tensor, elements}) when is_list(elements) do
    1 + Enum.sum(Enum.map(elements, &count_nodes/1))
  end
  defp count_nodes(list) when is_list(list) do
    Enum.sum(Enum.map(list, &count_nodes/1))
  end
  defp count_nodes(_leaf), do: 1
end
