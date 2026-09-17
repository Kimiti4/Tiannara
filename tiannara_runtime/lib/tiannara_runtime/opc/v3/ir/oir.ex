defmodule Tiannara.OPC.V3.IR.OIR do
  @moduledoc """
  Ontological Intermediate Representation (strict, normalized)
  This is the core data model for OPC v3 that ensures type safety and prevents raw atoms from leaking.
  """

  defstruct [
    :type,
    :op,
    :value,
    :children,
    :meta
  ]

  @type t :: %__MODULE__{
    type: :number | :string | :boolean | :binary | :unary | :function | :tensor | :conditional | :identifier,
    op: atom() | nil,
    value: any(),
    children: list(t()),
    meta: map()
  }

  @doc """
  Creates a new OIR node with the given parameters.
  """
  def new(type, op \\ nil, value \\ nil, children \\ [], meta \\ %{}) do
    %__MODULE__{
      type: type,
      op: op,
      value: value,
      children: children,
      meta: meta
    }
  end
end
