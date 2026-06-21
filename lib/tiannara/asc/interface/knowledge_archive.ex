defmodule Tiannara.ASC.Interface.KnowledgeArchive do
  @moduledoc """
  Interface Knowledge Archive — registers interface evolution artifacts for future law discovery.

  Every evolved genome and applied mutation is recorded here, creating a civilizational
  memory that enables queries like:

  - "Which contract mutations most frequently improve maintainability?"
  - "What protocol switches correlate with increased coupling?"
  - "How does schema reuse rate affect long-term stability?"

  This transforms ASC from a genetic algorithm into a scientific civilization that
  accumulates software engineering knowledge across generations.

  ## Integration Points

  - Called by `Mutation.register/1` after every mutation
  - Called by `EvolutionEngine` after each generation
  - Queried by `ASC.Laws.Discoverer` during pattern extraction

  ## Example

      iex> genome = Tiannara.ASC.Interface.Genome.new()
      iex> Tiannara.ASC.Interface.KnowledgeArchive.register_genome(genome)
      :ok
      iex> mutation = %Tiannara.ASC.Interface.Mutation{type: :split_contract}
      iex> Tiannara.ASC.Interface.KnowledgeArchive.register_mutation(mutation)
      :ok

  """

  alias Tiannara.ASC.Interface.{Genome, Mutation}

  @doc """
  Register an evolved interface genome in the Knowledge Archive.

  Stores genome metadata for future pattern discovery:
  - Genome structure (contracts, events, protocols)
  - Fitness scores across dimensions
  - Generation number
  - Timestamp

  This enables longitudinal analysis of interface evolution trends.
  """
  def register_genome(%Genome{} = genome) do
    # TODO: Integrate with persistent KnowledgeArchive when available
    # For now, log registration for observability
    require Logger

    Logger.info(
      "[Interface.KnowledgeArchive] Registered genome #{genome.genome_id} " <>
      "(generation: #{genome.generation}, fitness: #{genome.fitness})"
    )

    # Record in Registry for immediate access
    Tiannara.ASC.Interface.Registry.register_genome(genome)

    :ok
  end

  @doc """
  Register a mutation in the Knowledge Archive.

  Stores mutation provenance for future law discovery:
  - Mutation type and target
  - Before/after states
  - Fitness delta (impact measurement)
  - Timestamp and generation

  This is the critical data source for discovering laws like:
  "Contract splitting → Increased maintainability"
  """
  def register_mutation(%Mutation{} = mutation) do
    # TODO: Integrate with persistent KnowledgeArchive when available
    # For now, log registration for observability
    require Logger

    Logger.info(
      "[Interface.KnowledgeArchive] Registered mutation #{mutation.id} " <>
      "(type: #{mutation.type}, target: #{mutation.target_type}:#{mutation.target_id}, " <>
      "fitness_delta: #{mutation.fitness_delta})"
    )

    # Record telemetry in Observatory
    record_mutation_telemetry(mutation)

    :ok
  end

  @doc """
  Query genomes by fitness range for pattern analysis.

  Returns all genomes within the specified fitness bounds.
  Useful for identifying high-performing interface patterns.
  """
  def query_genomes_by_fitness(min_fitness \\ 0.0, max_fitness \\ 1.0) do
    # TODO: Implement ETS query when Registry supports filtering
    # For now, return empty list
    []
  end

  @doc """
  Query mutations by type for law discovery.

  Returns all mutations of a specific type (e.g., :split_contract).
  Enables analysis of mutation effectiveness across generations.
  """
  def query_mutations_by_type(type) do
    # TODO: Implement ETS query when Registry supports filtering
    # For now, return empty list
    []
  end

  @doc """
  Calculate mutation diversity metric.

  Measures the variety of mutation types applied across evolution history.
  High diversity indicates exploration; low diversity indicates exploitation.

  Formula: unique_mutation_types / total_mutations
  """
  def calculate_mutation_diversity do
    # TODO: Calculate from Registry data
    # For now, return default value
    0.5
  end

  @doc """
  Extract mutation success patterns for law discovery.

  Analyzes which mutation types most frequently improve fitness.
  Returns a map of mutation_type → {success_rate, avg_fitness_delta}.
  """
  def extract_success_patterns do
    # TODO: Aggregate from Registry data
    # For now, return empty map
    %{}
  end

  # Private helpers

  defp record_mutation_telemetry(%Mutation{} = mutation) do
    # Update Observatory metrics
    telemetry = Mutation.record_telemetry(mutation)

    # Log telemetry for debugging
    require Logger
    Logger.debug(
      "[Interface.KnowledgeArchive] Telemetry: #{inspect(telemetry)}"
    )

    :ok
  end
end
