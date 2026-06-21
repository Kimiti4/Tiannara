defmodule Tiannara.SOPL.LawNiche do
  @moduledoc """
  SOPL-4: Law Niche
  
  Defines specific cosmological environmental conditions. 
  Allows Tiannara to track species that are locally optimal within a specific
  context (e.g., an Adversarial Niche) even if they fail generalized global benchmarks.
  """
  defstruct [
    :id,
    :name,
    :environmental_pressures
  ]

  @doc """
  Returns the predefined foundational niches for SOPL-4 ecology mapping.
  These environments act as stress-tests to discover specialized LawSpecies.
  """
  def foundational_niches do
    [
      # Exploration Engines
      %__MODULE__{
        id: "niche_basin_escape",
        name: "Basin Escape Niche",
        environmental_pressures: %{
          novelty_demand: :high,
          mutation_pressure: :high,
          truth_demand: :moderate
        }
      },
      # Archival Universes
      %__MODULE__{
        id: "niche_deep_truth",
        name: "Deep Truth Niche",
        environmental_pressures: %{
          truth_demand: :extreme,
          continuity_demand: :extreme,
          novelty_demand: :low
        }
      },
      # Innovation Hubs
      %__MODULE__{
        id: "niche_recombination",
        name: "Recombination Niche",
        environmental_pressures: %{
          ecl_activity: :extreme,
          fragment_exchange: :high,
          cross_shard_transfer: :high
        }
      },
      # Evolutionary Stress Champions
      %__MODULE__{
        id: "niche_adversarial",
        name: "Adversarial Niche",
        environmental_pressures: %{
          acm_pressure: :permanent,
          predator_density: :high,
          disease_virulence: :extreme
        }
      },
      # Hard Constraint Universes
      %__MODULE__{
        id: "niche_scarcity",
        name: "Scarcity Niche",
        environmental_pressures: %{
          economic_cap: :harsh,
          resource_density: :low
        }
      }
    ]
  end
end
