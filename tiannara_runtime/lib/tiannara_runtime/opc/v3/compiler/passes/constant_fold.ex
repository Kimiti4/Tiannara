defmodule Tiannara.OPC.V3.Compiler.ConstantFold do
  @moduledoc """
  Constant Folding Pass
  Evaluates compile-time constant expressions to optimize the IR
  """

  alias Tiannara.OPC.V3.IR.OIR

  def apply(%OIR{} = oir) do
    fold_constants(oir)
  end

  defp fold_constants(%OIR{type: :binary, op: op, children: [left, right]} = node) do
    # Try to fold constants if both children are constant numbers
    folded_left = fold_constants(left)
    folded_right = fold_constants(right)

    case {folded_left, folded_right} do
      {%OIR{type: :number, value: left_val}, %OIR{type: :number, value: right_val}} ->
        result = perform_operation(op, left_val, right_val)
        %OIR{type: :number, op: nil, value: result, children: [], meta: %{folded: true}}
      
      {new_left, new_right} ->
        %OIR{node | children: [new_left, new_right]}
    end
  end

  defp fold_constants(%OIR{type: :unary, op: op, children: [operand]} = node) do
    folded_operand = fold_constants(operand)

    case folded_operand do
      %OIR{type: :number, value: val} ->
        result = perform_unary_operation(op, val)
        %OIR{type: :number, op: nil, value: result, children: [], meta: %{folded: true}}
      
      new_operand ->
        %OIR{node | children: [new_operand]}
    end
  end

  defp fold_constants(%OIR{children: children} = node) when is_list(children) do
    new_children = Enum.map(children, &fold_constants/1)
    %OIR{node | children: new_children}
  end

  defp fold_constants(%OIR{} = node) do
    node
  end

  defp perform_operation(:add, left, right), do: left + right
  defp perform_operation(:sub, left, right), do: left - right
  defp perform_operation(:mul, left, right), do: left * right
  defp perform_operation(:div, left, right), do: if(right != 0, do: left / right, else: left)
  defp perform_operation(:pow, left, right), do: :math.pow(left, right)
  defp perform_operation(:modulo, left, right), do: rem(trunc(left), trunc(right))
  defp perform_operation(_, left, _right), do: left

  defp perform_unary_operation(:negate, val), do: -val
  defp perform_unary_operation(:absolute, val), do: abs(val)
  defp perform_unary_operation(:square_root, val), do: :math.sqrt(abs(val))
  defp perform_unary_operation(:sine, val), do: :math.sin(val)
  defp perform_unary_operation(:cosine, val), do: :math.cos(val)
  defp perform_unary_operation(:tangent, val), do: :math.tan(val)
  defp perform_unary_operation(:exponential, val), do: :math.exp(val)
  defp perform_unary_operation(:logarithm, val), do: if(val > 0, do: :math.log(val), else: 0)
  defp perform_unary_operation(:floor, val), do: Float.floor(val)
  defp perform_unary_operation(:ceiling, val), do: Float.ceil(val)
  defp perform_unary_operation(_, val), do: val
end
