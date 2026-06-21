defmodule TiannaraOS.World do
  @moduledoc """
  Represents a single active research world ecosystem in TiannaraOS.
  """

  @derive Jason.Encoder
  defstruct [
    :id,                  # atom
    :name,                # string
    :template_id,         # atom
    :labs,                # list of map: [%{id: atom, name: string}]
    :institutions,        # list of atom (institution IDs)
    :theories,            # list of atom (theory IDs)
    :discovery_registry,  # list of atom (discovery IDs)
    :economy,             # map: %{budget: float, credits_allocated: map}
    :tenant_id,           # string (for isolation verification)
    twin: nil,            # %TiannaraOS.RepositoryTwin{} or nil
    
    # NEW EVOLUTIONARY ECOLOGY FIELDS
    wealth: 100_000.0,
    funding_pool: 500_000.0,
    carrying_capacity: 40,
    capability_maintenance_rate: 0.0001,
    needs_vector: %{},
    capabilities: %{},
    memory: %{}
  ]

  @type t :: %__MODULE__{
    id: atom(),
    name: String.t(),
    template_id: atom(),
    labs: [map()],
    institutions: [atom()],
    theories: [atom()],
    discovery_registry: [atom()],
    economy: map(),
    tenant_id: String.t(),
    twin: any(),
    wealth: float(),
    funding_pool: float(),
    carrying_capacity: integer(),
    capability_maintenance_rate: float(),
    needs_vector: map(),
    capabilities: map(),
    memory: map()
  }
end
