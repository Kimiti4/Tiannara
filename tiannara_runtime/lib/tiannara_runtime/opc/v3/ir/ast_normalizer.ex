defmodule Tiannara.OPC.V3.IR.ASTNormalizer do
  @moduledoc """
  Normalizes AST nodes to ensure consistent operator representation
  This removes operator leakage completely by mapping raw atoms to normalized forms
  """

  alias Tiannara.OPC.V3.IR.OIR

  @doc """
  Normalizes an OIR node by standardizing operators and structure
  """
  def normalize(%OIR{type: type, op: op, children: children, value: value, meta: meta} = _node) do
    normalized_op = normalize_op(op)
    
    normalized_children = 
      Enum.map(children, &normalize/1)

    %OIR{
      type: type,
      op: normalized_op,
      children: normalized_children,
      value: value,
      meta: meta
    }
  end

  def normalize(value) when not is_struct(value, OIR), do: value

  @doc """
  Normalizes operators to prevent raw atom leakage
  """
  defp normalize_op(nil), do: nil
  
  defp normalize_op(:+), do: :add
  defp normalize_op(:-), do: :sub
  defp normalize_op(:*), do: :mul
  defp normalize_op(:/), do: :div
  defp normalize_op(:^), do: :pow
  defp normalize_op(:mod), do: :modulo
  defp normalize_op(:sqrt), do: :square_root
  defp normalize_op(:abs), do: :absolute
  defp normalize_op(:sin), do: :sine
  defp normalize_op(:cos), do: :cosine
  defp normalize_op(:tan), do: :tangent
  defp normalize_op(:exp), do: :exponential
  defp normalize_op(:log), do: :logarithm
  defp normalize_op(:min), do: :minimum
  defp normalize_op(:max), do: :maximum
  defp normalize_op(:clamp), do: :value_clamp
  defp normalize_op(:lerp), do: :linear_interpolate
  defp normalize_op(:normalize), do: :vector_normalize
  defp normalize_op(:floor), do: :floor
  defp normalize_op(:ceil), do: :ceiling
  defp normalize_op(op), do: op  # Return the operator as-is if not specifically mapped
end
