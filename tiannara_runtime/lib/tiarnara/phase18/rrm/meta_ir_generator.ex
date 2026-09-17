defmodule Tiarnara.Phase18.RRM.MetaIRGenerator do
  @moduledoc """
  Transforms standard Phase 17 DAG IR into self-describing Meta-IR.
  Embeds transformation rules, adaptation bounds, and equivalence checkpoints.
  """
  
  @spec wrap_with_meta(ir :: map(), target :: atom()) :: map()
  def wrap_with_meta(ir, target) do
    %{
      base_ir: ir,
      transformation_rules: generate_default_rules(target),
      adaptation_bounds: %{max_drift: 0.35, max_rounds: 12, equiv_epsilon: 1.0e-5},
      equivalence_checks: extract_invariants(ir),
      target: target,
      version: 1
    }
  end

  defp generate_default_rules(:gpu), do: %{kernel_layout: :coalesced, precision: :f32, unroll_factor: 4}
  defp generate_default_rules(:cpu), do: %{vectorization: :simd, cache_tiling: 64, branch_prediction: true}
  defp generate_default_rules(_),     do: %{fallback: :sequential}

  defp extract_invariants(ir), do: %{nodes: length(ir.nodes), edges: length(ir.edges), max_weight: 1.0}
end