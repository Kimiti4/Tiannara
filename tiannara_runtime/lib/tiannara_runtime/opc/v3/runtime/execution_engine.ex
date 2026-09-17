defmodule Tiannara.OPC.V3.Runtime.ExecutionEngine do
  @moduledoc """
  Execution Engine for OPC v3
  Executes the final EIR (Execution Intermediate Representation)
  """

  alias Tiannara.OPC.V3.IR.EIR

  @doc """
  Executes the given EIR node
  """
  def execute(%EIR{type: :constant, operands: [value]}) do
    {:ok, value}
  end

  def execute(%EIR{type: :operation, op: op, operands: [left, right]}) do
    result = perform_operation(op, left, right)
    {:ok, result}
  end

  def execute(%EIR{type: :operation, op: op, operands: [operand]}) do
    result = perform_unary_operation(op, operand)
    {:ok, result}
  end

  def execute(%EIR{type: :function_call, op: func_name, operands: args}) do
    result = perform_function_call(func_name, args)
    {:ok, result}
  end

  def execute(_) do
    {:error, :unsupported_execution_format}
  end

  defp perform_operation(:add, left, right), do: left + right
  defp perform_operation(:sub, left, right), do: left - right
  defp perform_operation(:mul, left, right), do: left * right
  defp perform_operation(:div, left, right), do: if(right != 0, do: left / right, else: :infinity)
  defp perform_operation(:pow, left, right), do: :math.pow(left, right)
  defp perform_operation(:modulo, left, right), do: rem(trunc(left), trunc(right))

  defp perform_unary_operation(:negate, val), do: -val
  defp perform_unary_operation(:absolute, val), do: abs(val)
  defp perform_unary_operation(:square_root, val), do: :math.sqrt(abs(val))
  defp perform_unary_operation(:sine, val), do: :math.sin(val)
  defp perform_unary_operation(:cosine, val), do: :math.cos(val)
  defp perform_unary_operation(:tangent, val), do: :math.tan(val)
  defp perform_unary_operation(:exponential, val), do: :math.exp(val)
  defp perform_unary_operation(:logarithm, val), do: if(val > 0, do: :math.log(val), else: :negative_input)
  defp perform_unary_operation(:floor, val), do: Float.floor(val)
  defp perform_unary_operation(:ceiling, val), do: Float.ceil(val)

  defp perform_function_call(:min, [a, b]), do: min(a, b)
  defp perform_function_call(:max, [a, b]), do: max(a, b)
  defp perform_function_call(:clamp, [val, min_val, max_val]), do: clamp(val, min_val, max_val)
  defp perform_function_call(:lerp, [a, b, t]), do: a + (b - a) * t
  defp perform_function_call(:normalize, [val, min_range, max_range]) do
    if max_range != min_range do
      (val - min_range) / (max_range - min_range)
    else
      0.0
    end
  end

  defp clamp(val, min_val, max_val) do
    cond do
      val < min_val -> min_val
      val > max_val -> max_val
      true -> val
    end
  end
end
