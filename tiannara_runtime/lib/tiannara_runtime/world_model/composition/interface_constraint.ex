defmodule TiannaraRuntime.WorldModel.Composition.InterfaceConstraint do
  @moduledoc """
  Phase 17.6.1 — InterfaceConstraint struct.
  A constraint on a domain interface.
  Fields: constraint_id, interface_id, type, expression, metadata.
  """
  defstruct [:constraint_id, :interface_id, :type, :expression, :metadata]

  @type constraint_type :: :range | :equality | :inequality | :custom
  @type t :: %__MODULE__{
          constraint_id: String.t() | nil,
          interface_id: String.t() | nil,
          type: constraint_type() | nil,
          expression: String.t() | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash =
      :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "ic_" <> hash
  end
end
