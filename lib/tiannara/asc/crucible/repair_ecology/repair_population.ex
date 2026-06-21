defmodule Tiannara.ASC.Crucible.RepairEcology.RepairPopulation do
  @moduledoc """
  Repair Population — maintains all active repair species and tracks population dynamics.

  Responsibilities:
  - Register new species (births)
  - Retire extinct species (deaths)
  - Track population sizes per species
  - Calculate population diversity metrics
  - Emit telemetry for observatory

  ## Metrics Tracked

  - `births` — Total species births
  - `deaths` — Total species deaths
  - `active_species` — Currently active species count
  - `extinct_species` — Retired species count
  - `population_diversity` — Shannon diversity index (0-1)

  ## Example

      iex> population = %Tiannara.ASC.Crucible.RepairEcology.RepairPopulation{}
      iex> population = RepairPopulation.register_species(population, species)
      iex> population.active_species
      1

  """

  alias Tiannara.ASC.Crucible.RepairEcology.RepairSpecies

  @derive Jason.Encoder
  defstruct [
    # Species Registry
    active_species: %{},       # %{species_id => %RepairSpecies{}}
    extinct_species: %{},      # %{species_id => %RepairSpecies{}}

    # Pattern-to-Species Mapping
    pattern_to_species: %{},   # %{pattern_id => species_id}

    # Lifecycle Counters
    births: 0,
    deaths: 0,

    # Temporal
    created_at: nil,
    updated_at: nil
  ]

  @typedoc "Repair population structure"
  @type t :: %__MODULE__{
          active_species: map(),
          extinct_species: map(),
          pattern_to_species: map(),
          births: non_neg_integer(),
          deaths: non_neg_integer(),
          created_at: DateTime.t() | nil,
          updated_at: DateTime.t() | nil
        }

  @doc """
  Initialize a new repair population.

  ## Returns

  - Empty population struct
  """
  def init do
    now = DateTime.utc_now()

    %__MODULE__{
      active_species: %{},
      extinct_species: %{},
      pattern_to_species: %{},
      births: 0,
      deaths: 0,
      created_at: now,
      updated_at: now
    }
  end

  @doc """
  Register a new species (birth event).

  ## Parameters

  - `population` — Current population state
  - `species` — New species to register
  - `patterns` — List of patterns belonging to this species

  ## Returns

  - Updated population with new species registered
  - {:ok, birth_event} for telemetry
  """
  def register_species(%__MODULE__{} = population, %RepairSpecies{} = species, patterns \\ []) do
    now = DateTime.utc_now()

    # Map patterns to species
    new_pattern_mapping =
      Enum.reduce(patterns, population.pattern_to_species, fn pattern, acc ->
        Map.put(acc, pattern.id, species.id)
      end)

    # Add species to active registry
    new_active = Map.put(population.active_species, species.id, species)

    birth_event = %{
      type: :species_birth,
      species_id: species.id,
      species_name: species.name,
      generation: species.generation,
      initial_population: length(patterns),
      timestamp: now
    }

    {
      %__MODULE__{
        population
        | active_species: new_active,
          pattern_to_species: new_pattern_mapping,
          births: population.births + 1,
          updated_at: now
      },
      birth_event
    }
  end

  @doc """
  Retire a species (death/extinction event).

  ## Parameters

  - `population` — Current population state
  - `species_id` — ID of species to retire
  - `cause` — Reason for extinction (:low_fitness, :no_reuse, :consecutive_failures)

  ## Returns

  - Updated population with species moved to extinct
  - {:ok, death_event} for telemetry
  """
  def retire_species(%__MODULE__{} = population, species_id, cause) do
    now = DateTime.utc_now()

    case Map.pop(population.active_species, species_id) do
      {nil, _} ->
        # Species not found
        {population, nil}

      {species, remaining_active} ->
        # Move to extinct
        extinct_species = Map.put(
          population.extinct_species,
          species_id,
          RepairSpecies.mark_extinct(species)
        )

        death_event = %{
          type: :species_death,
          species_id: species_id,
          species_name: species.name,
          cause: cause,
          final_fitness: species.fitness,
          lifespan_generations: now |> DateTime.diff(species.created_at, :second) |> div(60),
          timestamp: now
        }

        {
          %__MODULE__{
            population
            | active_species: remaining_active,
              extinct_species: extinct_species,
              deaths: population.deaths + 1,
              updated_at: now
          },
          death_event
        }
    end
  end

  @doc """
  Update pattern-to-species mapping when a new pattern is added.

  ## Parameters

  - `population` — Current population state
  - `pattern_id` — New pattern ID
  - `species_id` — Species this pattern belongs to

  ## Returns

  - Updated population
  """
  def add_pattern_to_species(%__MODULE__{} = population, pattern_id, species_id) do
    %__MODULE__{
      population
      | pattern_to_species: Map.put(population.pattern_to_species, pattern_id, species_id)
    }
  end

  @doc """
  Get species for a given pattern.

  ## Parameters

  - `population` — Current population state
  - `pattern_id` — Pattern to look up

  ## Returns

  - species_id or nil if not found
  """
  def get_species_for_pattern(%__MODULE__{} = population, pattern_id) do
    Map.get(population.pattern_to_species, pattern_id)
  end

  @doc """
  Calculate population diversity using Shannon diversity index.

  H = -Σ(p_i * ln(p_i))

  Where p_i is the proportion of patterns in species i.

  Higher values (closer to 1.0) indicate more diverse populations.

  ## Parameters

  - `population` — Current population state
  - `total_patterns` — Total number of patterns across all species

  ## Returns

  - Diversity score (0.0-1.0)
  """
  def calculate_diversity(%__MODULE__{} = population, total_patterns) do
    if total_patterns == 0 do
      0.0
    else
      # Calculate proportions
      proportions =
        population.active_species
        |> Map.values()
        |> Enum.map(fn species ->
          species.population_size / total_patterns
        end)

      # Calculate Shannon index
      shannon_h =
        proportions
        |> Enum.filter(&(&1 > 0))  # Filter out zero proportions
        |> Enum.reduce(0.0, fn p, acc ->
          acc - (p * :math.log(p))
        end)

      # Normalize to 0-1 range (max H = ln(S) where S = number of species)
      num_species = length(proportions)
      max_h = if num_species > 1, do: :math.log(num_species), else: 1.0

      Float.round(shannon_h / max_h, 3)
    end
  end

  @doc """
  Get population summary metrics.

  ## Parameters

  - `population` — Current population state

  ## Returns

  - Map of population metrics
  """
  def get_metrics(%__MODULE__{} = population) do
    active_count = map_size(population.active_species)
    extinct_count = map_size(population.extinct_species)

    total_patterns =
      population.active_species
      |> Map.values()
      |> Enum.sum_by(& &1.population_size)

    avg_fitness =
      if active_count > 0 do
        population.active_species
        |> Map.values()
        |> Enum.sum_by(& &1.fitness)
        |> Kernel./(active_count)
      else
        0.0
      end

    %{
      active_species: active_count,
      extinct_species: extinct_count,
      total_patterns: total_patterns,
      births: population.births,
      deaths: population.deaths,
      average_fitness: Float.round(avg_fitness, 3),
      population_diversity: calculate_diversity(population, total_patterns)
    }
  end

  @doc """
  Get the species map for integration with other modules.

  ## Returns

  - Map of species_id -> RepairSpecies (both active and extinct)
  """
  def get_species_map(%__MODULE__{} = population) do
    Map.merge(population.active_species, population.extinct_species)
  end
end
