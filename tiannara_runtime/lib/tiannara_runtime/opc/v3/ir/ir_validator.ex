defmodule Tiannara.OPC.V3.IR.Validator do
  @moduledoc """
  Validates OIR nodes to ensure structural integrity and prevent runtime crashes
  This acts as a gatekeeper that prevents invalid IR from passing through
  """

  alias Tiannara.OPC.V3.IR.OIR

  @doc """
  Validates an OIR node and all its children
  """
  def validate(%OIR{type: :number, value: value}) when is_number(value) do
    :ok
  end

  def validate(%OIR{type: :string, value: value}) when is_binary(value) do
    :ok
  end

  def validate(%OIR{type: :boolean, value: value}) when is_boolean(value) do
    :ok
  end

  def validate(%OIR{type: :identifier, value: value}) when is_atom(value) or is_binary(value) do
    :ok
  end

  def validate(%OIR{type: :binary, op: op, children: [left, right]} = _node) when not is_nil(op) do
    with :ok <- validate(left),
         :ok <- validate(right) do
      :ok
    end
  end

  def validate(%OIR{type: :unary, op: op, children: [operand]} = _node) when not is_nil(op) do
    validate(operand)
  end

  def validate(%OIR{type: :function, op: op, children: args} = _node) when not is_nil(op) and is_list(args) do
    Enum.each(args, &validate/1)
    :ok
  end

  def validate(%OIR{type: :tensor, children: elements} = _node) when is_list(elements) do
    Enum.each(elements, &validate/1)
    :ok
  end

  def validate(%OIR{type: :conditional, children: [condition, true_branch, false_branch]} = _node) do
    with :ok <- validate(condition),
         :ok <- validate(true_branch),
         :ok <- validate(false_branch) do
      :ok
    end
  end

  def validate(%OIR{} = _node) do
    {:error, :invalid_oir_node}
  end

  def validate(_), do: {:error, :not_an_oir_node}
end
