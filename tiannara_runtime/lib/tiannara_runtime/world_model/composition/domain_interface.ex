defmodule TiannaraRuntime.WorldModel.Composition.DomainInterface do
  @moduledoc """
  Phase 17.6.1 — DomainInterface struct.
  A contract between two domain models specifying shared variables, direction, and constraints.
  Fields: interface_id, source_domain, target_domain, shared_variables, direction, constraints, priority, description, metadata.
  """
  defstruct [
    :interface_id, :source_domain, :target_domain, :shared_variables,
    :direction, :constraints, :priority, :description, :metadata
  ]

  @type direction :: :bidirectional | :source_to_target | :target_to_source
  @type t :: %__MODULE__{
          interface_id: String.t() | nil,
          source_domain: String.t() | nil,
          target_domain: String.t() | nil,
          shared_variables: [String.t()] | nil,
          direction: direction() | nil,
          constraints: [map()] | nil,
          priority: non_neg_integer() | nil,
          description: String.t() | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash =
      :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "di_" <> hash
  end
end
