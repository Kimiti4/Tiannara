defmodule Tiannara.OPC.V3.Compiler.SafetyInjector do
  @moduledoc """
  Safety Injector Pass
  Injects safety checks and bounds into the IR to prevent runtime errors
  """

  alias Tiannara.OPC.V3.IR.OIR

  def apply(%OIR{} = oir) do
    inject_safety_checks(oir)
  end

  defp inject_safety_checks(%OIR{type: :binary, op: :div, children: [numerator, denominator]} = node) do
    # For division operations, inject safety check for division by zero
    safe_denominator = ensure_non_zero(denominator)
    
    %OIR{node | children: [numerator, safe_denominator], 
          meta: Map.put(node.meta, :safety_checked, true)}
  end

  defp inject_safety_checks(%OIR{type: :binary, op: :modulo, children: [numerator, denominator]} = node) do
    # For modulo operations, ensure denominator is not zero
    safe_denominator = ensure_non_zero(denominator)
    
    %OIR{node | children: [numerator, safe_denominator], 
          meta: Map.put(node.meta, :safety_checked, true)}
  end

  defp inject_safety_checks(%OIR{type: :unary, op: :square_root, children: [operand]} = node) do
    # For square root operations, ensure operand is non-negative
    safe_operand = ensure_non_negative(operand)
    
    %OIR{node | children: [safe_operand], 
          meta: Map.put(node.meta, :safety_checked, true)}
  end

  defp inject_safety_checks(%OIR{children: children} = node) when is_list(children) do
    new_children = Enum.map(children, &inject_safety_checks/1)
    %OIR{node | children: new_children}
  end

  defp inject_safety_checks(%OIR{} = node) do
    node
  end

  defp ensure_non_zero(%OIR{type: :number, value: 0} = node) do
    # Replace zero with a small positive value to prevent division by zero
    %OIR{node | value: 1.0e-10, meta: Map.put(node.meta, :zero_substituted, true)}
  end

  defp ensure_non_zero(%OIR{type: :number, value: val} = node) when val < 1.0e-10 and val > -1.0e-10 do
    # Replace near-zero values with a small positive value
    %OIR{node | value: 1.0e-10, meta: Map.put(node.meta, :zero_substituted, true)}
  end

  defp ensure_non_zero(node), do: node

  defp ensure_non_negative(%OIR{type: :number, value: val} = node) when val < 0 do
    # Make negative values positive for square root safety
    %OIR{node | value: abs(val), meta: Map.put(node.meta, :sign_adjusted, true)}
  end

  defp ensure_non_negative(node), do: node
end
