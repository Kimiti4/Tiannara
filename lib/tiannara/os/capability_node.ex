defmodule TiannaraOS.CapabilityNode do
  @moduledoc """
  Represents a single evolving capability in a civilization's technological graph.
  
  Unlike previous static capability atoms, CapabilityNodes are dynamic evolutionary
  entities. They track their own maturity, efficiency, and topological relationships
  to other capabilities (parents and children).
  
  When synthesized (e.g., Energy + Materials -> Electrochemistry), they form
  directed acyclic graphs of knowledge that inherit and mutate across generations.
  """

  @derive Jason.Encoder
  defstruct [
    :id,                 # atom() - unique identifier (e.g., :energy_storage_v4)
    :domain_vector,      # map() - %{domain_atom => weight_float}
    version: 1,          # integer() - mutation depth starting at 1
    
    efficiency: 0.5,     # float() - raw performance multiplier (0.0 to 1.0+)
    reliability: 0.5,    # float() - failure resistance (0.0 to 1.0)
    novelty: 0.5,        # float() - uniqueness compared to peer nodes
    maturity: 0.0,       # float() - validation metric across time
    
    parent_nodes: [],    # list(atom()) - parent node IDs this was synthesized from
    child_nodes: [],     # list(atom()) - child node IDs derived from this
    depth: 1,            # integer() - path length from origin domain (Technological Depth)
    
    discovered_by: nil,  # atom() | nil - origin program ID
    
    usage_count: 0,      # integer() - number of times utilized as a prerequisite
    adoption_count: 0,   # integer() - number of descending programs holding this capability
    
    fitness_score: 0.0,  # float() - efficiency * reliability * adoption * novelty
    selection_score: 0.0,# float() - survival fitness resisting pruning
    last_used_tick: 0,   # integer() - tick when last utilized
    extinction_risk: 0.0,# float() - probability of being pruned
    
    promoted: false      # boolean() - true if promoted to World/Civilization level
  ]

  @type t :: %__MODULE__{
    id: atom(),
    domain_vector: map(),
    version: integer(),
    efficiency: float(),
    reliability: float(),
    novelty: float(),
    maturity: float(),
    parent_nodes: [atom()],
    child_nodes: [atom()],
    depth: integer(),
    discovered_by: atom() | nil,
    usage_count: integer(),
    adoption_count: integer(),
    fitness_score: float(),
    selection_score: float(),
    last_used_tick: integer(),
    extinction_risk: float(),
    promoted: boolean()
  }
end
