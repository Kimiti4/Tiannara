defmodule Tiannara.Meta.OPC.Stabilization.ShaderComplexityGuard do
  @moduledoc """
  Phase 5F.6 — Shader Complexity Guard

  Validates that a compiled OIR instruction list does not exceed the
  maximum GPU shader instruction count. Prevents shader bombs that
  would stall or crash the GPU execution pipeline.

  ## Constraint

  length(instructions) ≤ @max_instruction_count (default: 2048)

  ## Usage

      instructions = [{:load_const, 1.0}, {:binary_exec, :+}]
      :ok = ShaderComplexityGuard.validate(instructions)
  """

  require Logger

  @max_instruction_count 2048

  @doc """
  Validates that the instruction list does not exceed the maximum count.

  ## Returns
  - `:ok` — Instruction count within bounds
  - `{:error, :shader_complexity_exceeded}` — Too many instructions
  """
  def validate(instructions) when is_list(instructions) do
    count = length(instructions)

    if count > @max_instruction_count do
      Logger.warning(
        "🛑 [ShaderComplexityGuard] Instruction count #{count} exceeds maximum #{@max_instruction_count}"
      )

      {:error, :shader_complexity_exceeded}
    else
      Logger.debug("✅ [ShaderComplexityGuard] Instruction count #{count} within bounds")
      :ok
    end
  end

  def validate(_non_list) do
    Logger.warning("🛑 [ShaderComplexityGuard] Invalid instruction list provided")
    {:error, :invalid_instruction_list}
  end
end
