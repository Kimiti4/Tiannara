defmodule Tiannara.ASC.Interface.Population do
  @moduledoc """
  Interface Population — manages a collection of evolving interface genomes.

  Responsibilities:
  - Spawn initial genomes
  - Track generations
  - Maintain diversity
  - Archive extinct genomes
  - Select parents for reproduction
  - Manage speciation

  The population is the fundamental unit of evolution, containing multiple
  lineages that compete, cooperate, and speciate over time.

  ## Example

      iex> {:ok, pop} = Tiannara.ASC.Interface.Population.new(size: 50)
      iex> pop.generation
      0
      iex> length(pop.genomes)
      50

  """

  alias Tiannara.ASC.Interface.{Genome, Lineage}
  alias Tiannara.ASC.Interface.Fitness

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,                    # Unique population identifier
    generation: 0,              # Current generation number

    # Population state
    genomes: [],                # List of current genomes
    lineages: [],               # List of active lineages
    extinct_lineages: [],       # List of extinct lineage records

    # Species classification
    species: %{},               # Map of species_id -> [genome_ids]

    # Metrics
    fitness_distribution: %{    # Statistical distribution of fitness scores
      min: 0.0,
      max: 0.0,
      mean: 0.0,
      median: 0.0,
      std_dev: 0.0
    },
    diversity_score: 0.0,       # Population diversity metric (0.0-1.0)

    # Tracking
    created_at: nil,            # When population was initialized
    last_updated_at: nil        # When population was last modified
  ]

  @typedoc "Interface population"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          generation: non_neg_integer(),
          genomes: [Genome.t()],
          lineages: [Lineage.t()],
          extinct_lineages: [Lineage.t()],
          species: map(),
          fitness_distribution: map(),
          diversity_score: float(),
          created_at: DateTime.t() | nil,
          last_updated_at: DateTime.t() | nil
        }

  @doc """
  Create a new population with random genomes.

  ## Options

  - `:size` — Number of initial genomes (default: 50)
  - `:generation` — Starting generation number (default: 0)

  ## Returns

  - `{:ok, population}`

  """
  def new(opts \\ []) do
    size = Keyword.get(opts, :size, 50)
    generation = Keyword.get(opts, :generation, 0)

    # Generate random genomes
    genomes = Enum.map(1..size, fn _ -> Genome.new() end)

    # Create lineages for each genome
    lineages = Enum.map(genomes, &Lineage.new/1)

    now = DateTime.utc_now()

    population = %__MODULE__{
      id: generate_id(),
      generation: generation,
      genomes: genomes,
      lineages: lineages,
      extinct_lineages: [],
      species: %{},
      fitness_distribution: calculate_fitness_distribution(genomes),
      diversity_score: calculate_diversity(genomes),
      created_at: now,
      last_updated_at: now
    }

    {:ok, population}
  end

  @doc """
  Advance population to next generation.

  Replaces old genomes with new ones and increments generation counter.

  ## Returns

  - Updated population

  """
  def advance_generation(%__MODULE__{} = population, new_genomes) do
    now = DateTime.utc_now()

    # Archive old lineages that are no longer represented
    old_genome_ids = MapSet.new(Enum.map(population.genomes, & &1.genome_id))
    new_genome_ids = MapSet.new(Enum.map(new_genomes, & &1.genome_id))

    extinct_lineage_ids = MapSet.difference(old_genome_ids, new_genome_ids)
      |> MapSet.to_list()

    # Move extinct lineages from active to extinct list
    {extinct_lineages, surviving_lineages} = Enum.split_with(
      population.lineages,
      fn lineage -> lineage.current_genome.genome_id in extinct_lineage_ids end
    )

    # Mark extinct lineages
    marked_extinct = Enum.map(extinct_lineages, fn lineage ->
      Lineage.mark_extinct(lineage, population.generation + 1)
    end)

    # Create new lineages for genomes without existing lineage
    existing_lineage_genomes = MapSet.new(
      Enum.map(surviving_lineages, & &1.current_genome.genome_id)
    )

    new_lineages = new_genomes
      |> Enum.reject(fn g -> g.genome_id in existing_lineage_genomes end)
      |> Enum.map(&Lineage.new/1)

    all_lineages = surviving_lineages ++ new_lineages

    %{
      population
      | generation: population.generation + 1,
        genomes: new_genomes,
        lineages: all_lineages,
        extinct_lineages: population.extinct_lineages ++ marked_extinct,
        fitness_distribution: calculate_fitness_distribution(new_genomes),
        diversity_score: calculate_diversity(new_genomes),
        last_updated_at: now
    }
  end

  @doc """
  Select parents for reproduction using tournament selection.

  Selects top-performing genomes based on fitness, with some randomness
  to maintain diversity.

  ## Options

  - `:num_parents` — Number of parents to select (default: 2)
  - `:tournament_size` — Size of tournament pool (default: 5)

  ## Returns

  - List of selected parent genomes

  """
  def select_parents(%__MODULE__{genomes: genomes}, opts \\ []) do
    num_parents = Keyword.get(opts, :num_parents, 2)
    tournament_size = Keyword.get(opts, :tournament_size, 5)

    Enum.map(1..num_parents, fn _ ->
      # Randomly select tournament participants
      tournament = Enum.take_random(genomes, min(tournament_size, length(genomes)))

      # Select fittest from tournament
      Enum.max_by(tournament, & &1.fitness)
    end)
  end

  @doc """
  Calculate population diversity score.

  Measures genetic variation across the population.
  Higher values indicate more diverse population.

  Formula: unique_contract_types / total_contracts
  """
  def calculate_diversity(genomes) do
    if length(genomes) == 0 do
      0.0
    else
      # Count unique contract IDs across all genomes
      all_contract_ids = genomes
        |> Enum.flat_map(& &1.contracts)
        |> Enum.map(& &1.id)
        |> MapSet.new()

      total_contracts = genomes
        |> Enum.flat_map(& &1.contracts)
        |> length()

      if total_contracts == 0 do
        0.0
      else
        MapSet.size(all_contract_ids) / total_contracts
      end
    end
  end

  @doc """
  Calculate fitness distribution statistics.

  Returns min, max, mean, median, and standard deviation.
  """
  def calculate_fitness_distribution(genomes) when length(genomes) == 0 do
    %{min: 0.0, max: 0.0, mean: 0.0, median: 0.0, std_dev: 0.0}
  end

  def calculate_fitness_distribution(genomes) do
    fitness_scores = Enum.map(genomes, & &1.fitness)
    sorted = Enum.sort(fitness_scores)

    min_score = List.first(sorted)
    max_score = List.last(sorted)
    mean_score = Enum.sum(sorted) / length(sorted)

    # Median
    mid = div(length(sorted), 2)
    median_score = if rem(length(sorted), 2) == 0 do
      (Enum.at(sorted, mid - 1) + Enum.at(sorted, mid)) / 2
    else
      Enum.at(sorted, mid)
    end

    # Standard deviation
    variance = Enum.reduce(sorted, 0.0, fn score, acc ->
      acc + :math.pow(score - mean_score, 2)
    end) / length(sorted)

    std_dev = :math.sqrt(variance)

    %{
      min: Float.round(min_score, 3),
      max: Float.round(max_score, 3),
      mean: Float.round(mean_score, 3),
      median: Float.round(median_score, 3),
      std_dev: Float.round(std_dev, 3)
    }
  end

  @doc """
  Get population statistics summary.

  Returns comprehensive metrics for observatory recording.
  """
  def get_statistics(%__MODULE__{} = population) do
    %{
      population_id: population.id,
      generation: population.generation,
      total_genomes: length(population.genomes),
      active_lineages: length(population.lineages),
      extinct_lineages: length(population.extinct_lineages),
      species_count: map_size(population.species),
      diversity_score: population.diversity_score,
      fitness_distribution: population.fitness_distribution,
      avg_longevity: calculate_avg_longevity(population.lineages)
    }
  end

  # Private helpers

  defp generate_id do
    "pop_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  defp calculate_avg_longevity(lineages) do
    if length(lineages) == 0 do
      0.0
    else
      longevities = Enum.map(lineages, &Lineage.longevity/1)
      Enum.sum(longevities) / length(longevities)
    end
  end
end
