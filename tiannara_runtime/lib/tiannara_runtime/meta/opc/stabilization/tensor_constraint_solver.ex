defmodule Tiannara.Meta.OPC.Stabilization.TensorConstraintSolver do
  @moduledoc """
  Phase 5F.6 — Tensor Constraint Solver

  Validates that observer physics ASTs do not exceed safe tensor rank bounds.
  Tensor rank explosions cause combinatorial GPU memory overflow.

  ## Constraint

  rank(T) ≤ @max_tensor_rank (default: 8)

  ## Usage

      ast = {:op, :+, [{:const, 1.0}, {:const, 2.0}]}
      :ok = TensorConstraintSolver.validate(ast)
  """

  require Logger

  @max_tensor_rank 8

  @doc """
  Validates that no tensor operation in the AST exceeds the maximum rank.

  ## Returns
  - `:ok` — All tensor ranks within bounds
  - `{:error, :tensor_overflow}` — Rank limit exceeded
  """
  def validate(ast) do
    rank = tensor_rank(ast)

    if rank > @max_tensor_rank do
      Logger.warning("🛑 [TensorConstraintSolver] Tensor rank #{rank} exceeds maximum #{@max_tensor_rank}")
      {:error, :tensor_overflow}
    else
      Logger.debug("✅ [TensorConstraintSolver] Tensor rank #{rank} within bounds")
      :ok
    end
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp tensor_rank({:op, _, args}) do
    1 + Enum.max(Enum.map(args, &tensor_rank/1), fn -> 0 end)
  end

  defp tensor_rank(_), do: 0
end
