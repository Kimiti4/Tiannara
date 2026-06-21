defmodule Tiannara.UCC.InstitutionGenome do
  @moduledoc """
  The Canonical InstitutionGenome representation.
  Tracks the topological state of the world, identifying supply chains and institutional hubs.
  """
  
  @derive Jason.Encoder
  defstruct [
    :id,
    :lineage_id,
    :epoch,
    :dcr,
    :scp,
    :dci,
    :redundancy,
    :entropy,
    :tfi,
    :fri,
    :lineage_age,
    :migration_persistence,
    :trust_centrality_top_10,
    :radius_of_gyration
  ]
end
