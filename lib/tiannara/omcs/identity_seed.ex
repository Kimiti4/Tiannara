defmodule Tiannara.OMCS.IdentitySeed do
  @moduledoc """
  The compressed essence of a civilization.
  This is returned by OMCS.capture_identity/1 and later used by LEOC.
  """

  @enforce_keys [
    :civilization_id,
    :lineage_graph,
    :causal_graph,
    :narrative_graph,
    :ontology_fingerprint
  ]
  
  defstruct [
    :civilization_id,
    :lineage_graph,        # Core ancestry data
    :causal_graph,         # Critical decision -> effect chains
    :narrative_graph,      # Sequence of %Milestone{}
    :ontology_fingerprint, # Condensed thematic/belief representation
    :captured_at           # DateTime
  ]
end
