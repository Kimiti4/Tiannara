defmodule Tiannara.Core.WorldModel.Discovery do
  @moduledoc """
  A first-class entity representing a systemic discovery.
  Contains evolutionary links to parents and tracks complexity costs.
  """
  
  @enforce_keys [:id, :name, :domain, :originator_civ_id]

  defstruct [
    :id,
    :name,
    :domain,
    :originator_civ_id,
    parents: [],             # List of parent discovery IDs (Evolutionary Tree)
    prerequisites: [],       # List of required discovery IDs before this can be naturally discovered
    infected_by: [],         # List of memetic/viral entity IDs influencing this
    complexity_cost: 10,     # Maintenance cost in Ontological Capital/Compute
    maintenance_cost: %{},   # Explicit cost map, e.g., %{energy: 5}
    production_bonus: %{},   # Passive income, e.g., %{energy: 10} for Agriculture
    unlocks_beliefs: [],     # Ontological nodes unlocked by this
    impact_score: 0.0,       # Float reflecting ecosystem importance
    stability: 1.0,          # 0.0 to 1.0. How "real" or "stable" this discovery is.
    prestige: 0,             # Boosted by Epistemic Archaeology on rediscovery
    created_at: nil
  ]

  def new(attrs \\ %{}) do
    default = %{
      created_at: DateTime.utc_now()
    }
    struct(__MODULE__, Map.merge(default, attrs))
  end
end
