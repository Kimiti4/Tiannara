defmodule Tiannara.OPC.RealityCompiler.RuleCompiler do

  alias Tiannara.OPC.IR.PhysicsRule

  def compile(patterns) do
    Enum.map(patterns, fn p ->
      %PhysicsRule{
        id: generate_id(),
        condition: build_condition(p),
        effect: build_effect(p),
        weight: p.strength
      }
    end)
  end

  defp build_condition(p) do
    %{
      type_match: p.pattern_type,
      invariants: p.invariants
    }
  end

  defp build_effect(p) do
    %{
      mscl_modifier: p.strength * 0.1,
      olef_pressure_bias: Enum.count(p.invariants) * 0.05
    }
  end

  defp generate_id do
    :crypto.strong_rand_bytes(6) |> Base.encode16()
  end
end
