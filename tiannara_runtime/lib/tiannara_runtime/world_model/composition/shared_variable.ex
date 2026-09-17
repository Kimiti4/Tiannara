defmodule TiannaraRuntime.WorldModel.Composition.SharedVariable do
  @moduledoc """
  Phase 17.6.1 — SharedVariable struct.
  A variable that exists in multiple domain models and must be resolved to a common value.
  Fields: variable_id, name, domain_mappings, resolved_value, conflict, resolution_strategy, metadata.
  """
  defstruct [
    :variable_id, :name, :domain_mappings,
    :resolved_value, :conflict, :resolution_strategy, :metadata
  ]

  @type resolution_strategy :: :average | :priority | :custom
  @type t :: %__MODULE__{
          variable_id: String.t() | nil,
          name: String.t() | nil,
          domain_mappings: %{String.t() => String.t()} | nil,
          resolved_value: term() | nil,
          conflict: boolean() | nil,
          resolution_strategy: resolution_strategy() | nil,
          metadata: map() | nil
        }

  def generate_id(canonical) when is_map(canonical) do
    hash =
      :crypto.hash(:sha256, Jason.encode!(canonical)) |> Base.encode16(case: :lower)
    "sv_" <> hash
  end
end
