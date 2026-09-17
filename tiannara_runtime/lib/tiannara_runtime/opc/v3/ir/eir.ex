defmodule Tiannara.OPC.V3.IR.EIR do
  @moduledoc """
  Execution Intermediate Representation
  Final form ready for runtime execution or GPU compilation
  """

  defstruct [
    :type,
    :op,
    :operands,
    :result_type,
    :metadata
  ]

  @type t :: %__MODULE__{
    type: :operation | :constant | :variable | :function_call | :tensor_op,
    op: atom(),
    operands: list(any()),
    result_type: :float | :int | :bool | :tensor,
    metadata: map()
  }

  @doc """
  Creates a new EIR node with the given parameters.
  """
  def new(type, op, operands \\ [], result_type \\ :float, metadata \\ %{}) do
    %__MODULE__{
      type: type,
      op: op,
      operands: operands,
      result_type: result_type,
      metadata: metadata
    }
  end
end
