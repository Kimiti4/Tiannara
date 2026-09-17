defmodule Tiannara.Meta.OPC.Stabilization.RecursionGuard do
  @moduledoc """
  Phase 5F.6 — Recursion Guard

  Validates that observer physics ASTs do not exceed safe recursion depth.
  Prevents stack overflows and infinite loops in the GPU shader execution
  pipeline.

  ## Constraint

  depth(AST) ≤ @max_depth (default: 64)

  ## Usage

      ast = {:op, :+, [{:const, 1.0}, {:const, 2.0}]}
      :ok = RecursionGuard.validate(ast)
  """

  require Logger

  @max_depth 64

  @doc """
  Validates that the AST does not exceed the maximum recursion depth.

  ## Returns
  - `:ok` — Depth within bounds
  - `{:error, :recursive_overflow}` — Depth limit exceeded
  """
  def validate(ast, max_depth \\ @max_depth) do
    d = depth(ast)

    if d > max_depth do
      Logger.warning(
        "🛑 [RecursionGuard] AST depth #{d} exceeds maximum #{max_depth}"
      )

      {:error, :recursive_overflow}
    else
      Logger.debug("✅ [RecursionGuard] AST depth #{d} within bounds")
      :ok
    end
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp depth({:op, _, args}) when is_list(args) do
    1 + Enum.max(Enum.map(args, &depth/1), fn -> 0 end)
  end

  defp depth(list) when is_list(list) do
    1 + Enum.max(Enum.map(list, &depth/1), fn -> 0 end)
  end

  defp depth(_leaf), do: 0
end
