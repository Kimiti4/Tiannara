defmodule Tiannara.SOPL.LawSpeciesExtinction do
  @moduledoc """
  SOPL-4: Law Species Extinction (Species Archaeology)
  
  Unlike %LawRuin{} which tracks the failure of a single universe,
  this struct tracks the systemic collapse of an entire family of realities.
  It is the foundational data source for SOPL-5, answering:
  "Why do classes of universes disappear?"
  """
  defstruct [
    :id,
    :species_id,
    :extinction_epoch,
    :niche_context,           # Which niche were they trying to occupy when they failed?
    :primary_collapse_vector, # The specific pathology that wiped out the family
    :systemic_vulnerabilities,# Structural flaws discovered across all member universes
    :legacy_fragments         # Any sub-components (Constraint, Truth) that are worth salvaging
  ]
end
