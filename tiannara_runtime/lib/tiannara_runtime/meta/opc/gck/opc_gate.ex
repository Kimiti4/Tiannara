defmodule Tiannara.Meta.OPC.GCK.OPCGate do
  @moduledoc """
  Phase 5F.6 — GCK OPC Gate

  Hard pre-compilation barrier that runs all stabilization validators in
  sequence before any OIR is generated or GPU kernel is dispatched.

  ## Pipeline

      AST + Instructions
            ↓
      TensorConstraintSolver  (rank bounds)
            ↓
      RecursionGuard          (depth bounds)
            ↓
      EntropyEstimator        (entropy bounds)
            ↓
      ShaderComplexityGuard   (instruction count)
            ↓
      :ok  →  proceed to OIR generation

  ## Usage

      :ok = OPCGate.validate(ast, instructions)
  """

  require Logger

  alias Tiannara.Meta.OPC.Stabilization.TensorConstraintSolver
  alias Tiannara.Meta.OPC.Stabilization.RecursionGuard
  alias Tiannara.Meta.OPC.Stabilization.EntropyEstimator
  alias Tiannara.Meta.OPC.Stabilization.ShaderComplexityGuard

  @doc """
  Runs all GCK stabilization checks against the given AST and instruction list.

  ## Parameters
  - `ast`: The regularized observer physics AST
  - `instructions`: Compiled OIR instruction list

  ## Returns
  - `:ok` — All checks passed; safe to proceed
  - `{:error, reason}` — One or more checks failed
  """
  def validate(ast, instructions) do
    Logger.debug("🛡️ [OPCGate] Running GCK validation pipeline")

    with :ok <- TensorConstraintSolver.validate(ast),
         :ok <- RecursionGuard.validate(ast),
         {:ok, _entropy} <- EntropyEstimator.estimate(ast),
         :ok <- ShaderComplexityGuard.validate(instructions) do
      Logger.debug("✅ [OPCGate] All GCK checks passed")
      :ok
    else
      {:error, reason} ->
        Logger.warning("🛑 [OPCGate] GCK check failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
