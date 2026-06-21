defmodule TiannaraOS.DiscoveryAsset do
  @moduledoc """
  Represents a packaged, commercialized discovery asset inside the Discovery Economy.
  """

  @derive Jason.Encoder
  defstruct [
    :discovery_id,          # atom() - target discovery ID
    :domain_vector,         # %{atom() => float()} - NEW: Vector-based domain identity
    :primary_domain,        # atom() - NEW: Primary domain (highest weight in domain_vector)
    valuation: 0.0,         # float() - dynamic asset valuation
    royalty_rate: 0.05,     # float() - license royalty percent (e.g. 0.05 = 5%)
    license_type: :permissive, # atom() - :permissive | :restrictive | :proprietary
    buyers: [],             # list(atom()) - civilization/tenant IDs who bought access
    deployments: [],        # list(atom()) - active deployment targets (e.g. twin world IDs)
    maturity: :experimental, # atom() - :experimental | :validated | :commercial | :deprecated
    local_confidence: %{},  # %{atom() => float()}
    confidence: 1.0,        # float() - unified global confidence
    utility: 1.0,           # float() - usefulness metric
    transaction_history: [], # list(map()) - transaction log maps
    created_at: nil,        # integer() | nil - timestamp
    updated_at: nil         # integer() | nil - timestamp
  ]

  @type t :: %__MODULE__{
    discovery_id: atom(),
    valuation: float(),
    royalty_rate: float(),
    license_type: :permissive | :restrictive | :proprietary,
    buyers: [atom()],
    deployments: [atom()],
    maturity: :experimental | :validated | :commercial | :deprecated,
    local_confidence: %{atom() => float()},
    confidence: float(),
    utility: float(),
    transaction_history: [map()],
    created_at: integer() | nil,
    updated_at: integer() | nil
  }
end