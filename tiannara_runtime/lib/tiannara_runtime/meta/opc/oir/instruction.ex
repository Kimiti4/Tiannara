defmodule Tiannara.Meta.OPC.OIR.Instruction do
  @moduledoc """
  Phase 5F.6 — Ontological IR Instruction

  Struct representing a single instruction in the Ontological Intermediate
  Representation (OIR). OIR instructions are the normalised, safety-checked
  operations that the GPU compiler translates into GLSL compute shaders.

  ## Fields

  - `:opcode`   — The operation to perform (e.g. `:add`, `:mul`, `:div`)
  - `:dest`     — Destination register or variable name
  - `:src_a`    — First source operand
  - `:src_b`    — Second source operand (optional for unary ops)
  - `:metadata` — Arbitrary map for safety annotations, epsilon markers, etc.

  ## Example

      %Instruction{
        opcode: :div,
        dest: "r0",
        src_a: "numerator",
        src_b: "denominator_safe",
        metadata: %{epsilon_regularized: true}
      }
  """

  @enforce_keys [:opcode]
  defstruct [
    :opcode,
    :dest,
    :src_a,
    :src_b,
    metadata: %{}
  ]

  @type t :: %__MODULE__{
    opcode:   atom(),
    dest:     String.t() | nil,
    src_a:    term() | nil,
    src_b:    term() | nil,
    metadata: map()
  }
end
