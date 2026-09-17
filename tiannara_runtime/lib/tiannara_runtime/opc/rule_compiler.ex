defmodule Tiannara.OPC.RuleCompiler do
  @moduledoc """
  Phase 5F.9 — Rule compiler.
  Compiles inferred patterns into executable physics rule IR.
  """

  alias Tiannara.OPC.IR.PhysicsRule

  def compile(patterns) when is_list(patterns) do
    Enum.map(patterns, fn pattern ->
      %PhysicsRule{
        id: generate_id(),
        condition: build_condition(pattern),
        effect: build_effect(pattern),
        weight: pattern.strength
      }
    end)
  end

  defp build_condition(pattern) do
    %{
      match_type: pattern.pattern_type,
      invariants: pattern.invariants
    }
  end

  defp build_effect(pattern) do
    %{
      mscl_modifier: Float.round(pattern.strength * 0.12, 3),
      olef_pressure_bias: Enum.count(pattern.invariants) * 0.06
    }
  end

  defp generate_id do
    :crypto.strong_rand_bytes(6)
    |> Base.encode16(case: :lower)
  end
end
