defmodule Tiannara.OPC.V3.Compiler.TensorLift do
  @moduledoc """
  Tensor Lift Pass
  Optimizes tensor operations by lifting scalar operations to tensor level where possible
  """

  alias Tiannara.OPC.V3.IR.OIR

  def apply(%OIR{} = oir) do
    lift_tensors(oir)
  end

  defp lift_tensors(%OIR{type: :binary, op: op, children: [left, right]} = node) do
    # Check if either child is a tensor and the other is a scalar
    # If so, we might want to broadcast the scalar to match tensor dimensions
    
    lifted_left = lift_tensors(left)
    lifted_right = lift_tensors(right)
    
    # If both are numbers, we could convert to tensors if needed
    cond do
      is_scalar_tensor_op?(lifted_left, lifted_right) ->
        promote_to_tensor_operation(%OIR{node | children: [lifted_left, lifted_right]})
      
      true ->
        %OIR{node | children: [lifted_left, lifted_right]}
    end
  end

  defp lift_tensors(%OIR{children: children} = node) when is_list(children) do
    new_children = Enum.map(children, &lift_tensors/1)
    %OIR{node | children: new_children}
  end

  defp lift_tensors(%OIR{} = node) do
    node
  end

  defp is_scalar_tensor_op?(%OIR{type: :number}, %OIR{type: :tensor}), do: true
  defp is_scalar_tensor_op?(%OIR{type: :tensor}, %OIR{type: :number}), do: true
  defp is_scalar_tensor_op?(_, _), do: false

  defp promote_to_tensor_operation(%OIR{children: [scalar, tensor]} = node) do
    # Check if the first child is a number by accessing its type directly
    [first_child | _] = node.children
    if first_child.type == :number do
      # Promote scalar to broadcast across tensor
      %OIR{node | meta: Map.put(node.meta, :broadcast_applied, true)}
    else
      node
    end
  end

  defp promote_to_tensor_operation(%OIR{children: [tensor, scalar]} = node) do
    # Check if the last child is a number by accessing its type directly
    [_ | [last_child]] = node.children
    if last_child.type == :number do
      # Promote scalar to broadcast across tensor
      %OIR{node | meta: Map.put(node.meta, :broadcast_applied, true)}
    else
      node
    end
  end

  defp promote_to_tensor_operation(node), do: node
end
