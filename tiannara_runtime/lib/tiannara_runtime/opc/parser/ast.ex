defmodule Tiannara.OPC.Parser.AST do
  @moduledoc """
  Phase 5F.6 — OPC Abstract Syntax Tree Definitions
  
  Defines the structure of observer-defined physics expressions.
  Enforces bounded, safe ontological constructs.
  
  ## Node Types
  
  - **number**: Floating-point constants
  - **identifier**: Variable/parameter names (atoms)
  - **binary_op**: Mathematical operations (+, -, *, /, ^)
  - **unary_op**: Single-operand operations (-, sqrt, sin, cos, etc.)
  - **function**: Named function calls with arguments
  - **tensor**: Multi-dimensional array constructs
  - **conditional**: If-then-else logic (bounded)
  """
  
  @type number_node :: {:number, float()}
  @type identifier_node :: {:identifier, atom()}
  @type binary_op_node :: {:binary_op, atom(), t(), t()}
  @type unary_op_node :: {:unary_op, atom(), t()}
  @type function_node :: {:function, atom(), [t()]}
  @type tensor_node :: {:tensor, [t()]}
  @type conditional_node :: {:conditional, t(), t(), t()}
  
  @type t :: 
          number_node
          | identifier_node
          | binary_op_node
          | unary_op_node
          | function_node
          | tensor_node
          | conditional_node

  # Allowed binary operations
  @allowed_binary_ops [:*, :+, :-, :/, :^, :mod]
  
  # Allowed unary operations
  @allowed_unary_ops [:-, :sqrt, :abs, :sin, :cos, :tan, :exp, :log, :floor, :ceil]
  
  # Allowed functions
  @allowed_functions [:clamp, :min, :max, :lerp, :normalize, :sqrt, :abs, :sin, :cos, :tan, :exp, :log, :floor, :ceil]

  @doc """
  Validate that an AST node uses only allowed operations.
  """
  def validate_operations(ast) do
    validate_node(ast)
  end

  defp validate_node({:number, _}), do: :ok
  defp validate_node({:identifier, _}), do: :ok
  
  defp validate_node({:binary_op, op, left, right}) do
    if op in @allowed_binary_ops do
      case validate_node(left) do
        :ok -> validate_node(right)
        error -> error
      end
    else
      {:error, {:invalid_operation, op}}
    end
  end
  
  defp validate_node({:unary_op, op, operand}) do
    if op in @allowed_unary_ops do
      validate_node(operand)
    else
      {:error, {:invalid_unary_op, op}}
    end
  end
  
  defp validate_node({:function, name, args}) do
    if name in @allowed_functions do
      Enum.reduce_while(args, :ok, fn arg, _acc ->
        case validate_node(arg) do
          :ok -> {:cont, :ok}
          error -> {:halt, error}
        end
      end)
    else
      {:error, {:invalid_function, name}}
    end
  end
  
  defp validate_node({:tensor, elements}) do
    Enum.reduce_while(elements, :ok, fn elem, _acc ->
      case validate_node(elem) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end
  
  defp validate_node({:conditional, condition, true_branch, false_branch}) do
    with :ok <- validate_node(condition),
         :ok <- validate_node(true_branch),
         :ok <- validate_node(false_branch) do
      :ok
    end
  end

  @doc """
  Calculate AST depth for complexity limiting.
  """
  def depth({:number, _}), do: 1
  def depth({:identifier, _}), do: 1
  def depth({:binary_op, _, left, right}), do: 1 + max(depth(left), depth(right))
  def depth({:unary_op, _, operand}), do: 1 + depth(operand)
  def depth({:function, _, args}), do: 1 + (Enum.map(args, &depth/1) |> Enum.max(fn -> 0 end))
  def depth({:tensor, elements}), do: 1 + Enum.map(elements, &depth/1) |> Enum.max(fn -> 0 end)
  def depth({:conditional, c, t, f}), do: 1 + max(depth(c), max(depth(t), depth(f)))
end
