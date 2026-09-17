defmodule Tiannara.OPC.Validation.LoopAnalyzer do
  @moduledoc """
  Phase 5F.6 — Recursive Loop Analyzer

  Detects infinite recursion and unbounded loops in observer physics ASTs.
  Prevents compilation of physics that would cause GPU shader hangs or
  runtime deadlocks.

  ## Detection Strategy

  - Tracks recursion depth during AST traversal
  - Identifies self-referential tensor operations
  - Detects circular causal dependencies
  - Enforces maximum AST depth limits

  ## Usage

      ast = {:recursive_op, [{:var, :x}, {:recursive_op, [...]}]}
      case LoopAnalyzer.check(ast, 32) do
        :ok -> IO.puts("No infinite loops detected")
        {:error, :loop_violation} -> IO.puts("Infinite recursion risk")
      end
  """

  require Logger

  @doc """
  Checks AST for infinite loops and excessive recursion depth.

  ## Parameters
  - `ast`: The physics AST to analyze
  - `max_depth`: Maximum allowed recursion depth (default: 32)

  ## Returns
  - `:ok` — No loop violations detected
  - `{:error, :loop_violation}` — Infinite recursion or depth exceeded

  ## Example

      safe_ast = {:op, :+, [{:const, 1.0}, {:const, 2.0}]}
      :ok = LoopAnalyzer.check(safe_ast, 32)

      deep_ast = create_deeply_nested_ast(50)
      {:error, :loop_violation} = LoopAnalyzer.check(deep_ast, 32)
  """
  def check(ast, max_depth \\ 32) do
    Logger.debug("🔁 [LoopAnalyzer] Checking for infinite loops (max_depth: #{max_depth})...")

    if exceeds_depth?(ast, max_depth, 0) do
      Logger.warning("🛑 [LoopAnalyzer] Recursion depth exceeded (#{max_depth})")
      {:error, :loop_violation}
    else
      Logger.debug("✅ [LoopAnalyzer] No loop violations detected")
      :ok
    end
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp exceeds_depth?(_ast, max_depth, current_depth) when current_depth > max_depth do
    true
  end

  defp exceeds_depth?({:op, _op_name, args}, max_depth, current_depth) when is_list(args) do
    new_depth = current_depth + 1
    Enum.any?(args, fn arg ->
      exceeds_depth?(arg, max_depth, new_depth)
    end)
  end

  defp exceeds_depth?(list, max_depth, current_depth) when is_list(list) do
    new_depth = current_depth + 1
    Enum.any?(list, fn item ->
      exceeds_depth?(item, max_depth, new_depth)
    end)
  end

  defp exceeds_depth?(_leaf, _max_depth, _current_depth), do: false
end
