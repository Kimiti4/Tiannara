defmodule Tiannara.SOPL.LawLineage do
  @moduledoc """
  SOPL-2: Law Lineage
  
  Unlike %LawRuin{} which tracks extinct laws, LawLineage formally tracks
  the successful evolutionary history (phylogenetics) of laws.
  """
  defstruct [
    :id,
    :genesis_law_id,
    :current_law_id,
    :generations_survived,
    :mutations_accumulated,
    :historical_fitness_avg,
    :produced_species
  ]
end

defmodule Tiannara.SOPL.ConstitutionalPressure do
  @moduledoc """
  SOPL-2: Constitutional Pressure Budget
  
  A detailed mapping of invariant strain for a given law.
  A total pressure close to 0.0 is extremely safe. 
  A total pressure close to 1.0 means imminent collapse.
  """
  defstruct [
    reality_contact: 0.0,
    causal_consistency: 0.0,
    identity_continuity: 0.0,
    conservation: 0.0,
    accountability: 0.0,
    openness: 0.0,
    total_pressure: 0.0
  ]
end
