defmodule Tiannara.SOPL.LawSpeciesRecord do
  @moduledoc """
  SOPL-4: Law Species Record
  
  The ultimate output of SOPL-4. A canonical record of a viable universe class.
  Used as the primary input for SOPL-5 (Meta-Law Evolution).
  """
  defstruct [
    :species_id,
    :niches,            # List of Niche IDs this species thrives in
    :persistence,       # Sentinel Longevity score
    :innovation,        # Sentinel Innovation Yield score
    :resilience,        # Resistance to systemic pathologies
    :truth_retention,   # Sentinel Truth score
    :adaptive_capacity, # Inherent resistance to causal drift
    :descendants,       # List of child species
    :extinction_risk    # Computed probability of systemic collapse
  ]
end

defmodule Tiannara.SOPL.PeriodicTable do
  @moduledoc """
  SOPL-4: The Law Periodic Table
  
  Compiles and maintains the authoritative map of all viable universe classes.
  It maps LawSpecies to their optimal niches, creating a taxonomy of reality.
  """
  alias Tiannara.SOPL.LawSpeciesRecord
  require Logger

  @doc """
  Generates the periodic table by cross-referencing live LawSpecies with their
  Sentinel telemetry and historical Species Extinctions.
  """
  def generate_table(species_list, sentinel_reports, extinctions) do
    Logger.info("🌌 [SOPL-4] Compiling Law Periodic Table...")
    
    records = Enum.map(species_list, fn species ->
      report = Enum.find(sentinel_reports, & &1.species_id == species.id) || %{}
      
      extinction_events = Enum.count(extinctions, & &1.species_id == species.id)
      instance_count = length(Map.get(species, :universes, []))
      risk = if instance_count > 0, do: min(1.0, extinction_events / instance_count), else: 1.0

      %LawSpeciesRecord{
        species_id: species.id,
        niches: Map.keys(Map.get(species, :niche_specialization, %{})),
        persistence: Map.get(report, :longevity, 0.0),
        innovation: Map.get(report, :innovation_yield, 0.0),
        resilience: calculate_resilience(species, risk),
        truth_retention: Map.get(report, :truth_retention, 0.0),
        adaptive_capacity: Map.get(species, :adaptive_capacity, 0.0),
        descendants: Map.get(species, :descendants, []),
        extinction_risk: risk
      }
    end)
    
    Logger.info("📊 [SOPL-4] Periodic Table compiled: #{length(records)} Elements of Reality discovered.")
    records
  end

  defp calculate_resilience(species, risk) do
    # Resilience is high if it resists known pathologies and has a low systemic extinction risk
    base = 1.0 - risk
    
    # We assume an empty pathology_profile is bad (hasn't been tested), 
    # and a profile explicitly noting immunities is good.
    # We'll mock the extraction here for structural purposes.
    pathology_immunity_bonus = length(Map.get(species, :pathology_profile, [])) * 0.05
    min(1.0, base + pathology_immunity_bonus)
  end
end
