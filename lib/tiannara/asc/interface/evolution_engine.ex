defmodule Tiannara.ASC.Interface.EvolutionEngine do
  @moduledoc """
  Interface Evolution Engine — orchestrates complete evolutionary cycles.

  Responsibilities:
  - Evaluate population fitness
  - Form species through speciation
  - Select parents via tournament selection
  - Perform semantic crossover
  - Apply mutations with provenance
  - Execute cross-species knowledge transfer
  - Recalculate fitness after changes
  - Archive results in Knowledge Archive
  - Emit law candidates from observations

  The engine owns generations and performs one complete cycle per `tick/1` call.

  ## Example

      iex> {:ok, engine} = Tiannara.ASC.Interface.EvolutionEngine.start_link(population_size: 50)
      iex> GenServer.call(engine, :tick)
      {:ok, %{generation: 1, best_fitness: 0.85, species_count: 3}}

  """

  use GenServer

  alias Tiannara.ASC.Interface.{
    Population,
    Speciation,
    Crossover,
    Fitness,
    Transfer,
    LawCandidates
  }

  alias Tiannara.ASC.Interface.Mutations.ContractMutations

  # State
  defstruct [
    population_id: nil,
    generation: 0,
    population: nil,
    species_map: %{},
    transfers: [],
    all_mutations: [],
    law_candidates: [],
    telemetry: %{}
  ]

  @type state :: %__MODULE__{
          population_id: String.t(),
          generation: non_neg_integer(),
          population: Population.t(),
          species_map: map(),
          transfers: [Transfer.t()],
          all_mutations: [Tiannara.ASC.Interface.Mutation.t()],
          law_candidates: [LawCandidates.t()],
          telemetry: map()
        }

  # Client API

  @doc """
  Start evolution engine with initial population.

  ## Options

  - `:population_size` — Number of initial genomes (default: 50)
  - `:mutation_rate` — Probability of mutation per genome (default: 0.2)
  - `:transfer_rate` — Probability of cross-species transfer (default: 0.1)

  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Perform one complete evolutionary cycle.

  Executes:
  1. Species formation
  2. Parent selection
  3. Crossover
  4. Mutation
  5. Knowledge transfer
  6. Fitness evaluation
  7. Archive recording
  8. Law candidate emission

  ## Returns

  - `{:ok, generation_stats}`

  """
  def tick(pid) do
    GenServer.call(pid, :tick)
  end

  @doc """
  Get current evolution statistics.

  Returns comprehensive metrics for observatory recording.
  """
  def get_statistics(pid) do
    GenServer.call(pid, :get_statistics)
  end

  @doc """
  Get all law candidates generated so far.
  """
  def get_law_candidates(pid) do
    GenServer.call(pid, :get_law_candidates)
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    population_size = Keyword.get(opts, :population_size, 50)
    mutation_rate = Keyword.get(opts, :mutation_rate, 0.2)
    transfer_rate = Keyword.get(opts, :transfer_rate, 0.1)

    {:ok, population} = Population.new(size: population_size)

    state = %__MODULE__{
      population_id: population.id,
      generation: 0,
      population: population,
      species_map: %{},
      transfers: [],
      all_mutations: [],
      law_candidates: [],
      telemetry: %{
        mutation_rate: mutation_rate,
        transfer_rate: transfer_rate
      }
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:tick, _from, %__MODULE__{} = state) do
    new_state = evolve(state)
    stats = build_generation_stats(new_state)

    {:reply, {:ok, stats}, new_state}
  end

  @impl true
  def handle_call(:get_statistics, _from, %__MODULE__{} = state) do
    stats = build_comprehensive_stats(state)
    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_call(:get_law_candidates, _from, %__MODULE__{} = state) do
    {:reply, {:ok, state.law_candidates}, state}
  end

  # Core Evolution Logic

  defp evolve(%__MODULE__{} = state) do
    mutation_rate = state.telemetry.mutation_rate
    transfer_rate = state.telemetry.transfer_rate

    # Step 1: Species formation
    {:ok, species_map} = Speciation.classify_population(state.population)

    # Step 2: Calculate fitness for all genomes
    fitted_genomes = Enum.map(state.population.genomes, fn genome ->
      fitness = Fitness.calculate(genome)
      %{genome | fitness: fitness}
    end)

    # Step 3: Select parents
    parents = Population.select_parents(
      %{state.population | genomes: fitted_genomes},
      num_parents: div(length(fitted_genomes), 2)
    )

    # Step 4: Crossover to create offspring
    offspring = perform_crossover(parents)

    # Step 5: Apply mutations
    {mutated_offspring, mutations} = perform_mutations(offspring, mutation_rate)

    # Step 6: Knowledge transfer between species
    {transferred_offspring, transfers} = perform_transfers(
      mutated_offspring,
      species_map,
      transfer_rate
    )

    # Step 7: Advance population to next generation
    new_population = Population.advance_generation(state.population, transferred_offspring)

    # Step 8: Generate law candidates
    all_mutations = state.all_mutations ++ mutations
    new_candidates = LawCandidates.generate_from_mutations(all_mutations)
    all_candidates = state.law_candidates ++ new_candidates

    # Register candidates
    Enum.each(new_candidates, &LawCandidates.register_candidate/1)

    # Step 9: Update state
    %{
      state
      | generation: state.generation + 1,
        population: new_population,
        species_map: species_map,
        transfers: state.transfers ++ transfers,
        all_mutations: all_mutations,
        law_candidates: all_candidates,
        telemetry: Map.put(state.telemetry, :last_tick_at, DateTime.utc_now())
    }
  end

  defp perform_crossover(parents) do
    # Pair up parents and create offspring
    parents
    |> Enum.chunk_every(2)
    |> Enum.flat_map(fn
      [parent_a, parent_b] ->
        child = Crossover.crossover(parent_a, parent_b)
        [child]

      [single_parent] ->
        # If odd number, clone the last parent
        [single_parent]
    end)
  end

  defp perform_mutations(genomes, mutation_rate) do
    {mutated_genomes, all_mutations} = Enum.map_reduce(genomes, [], fn genome, acc_mutations ->
      if :rand.uniform() < mutation_rate do
        # Apply random mutation
        {mutated_genome, mutation} = apply_random_mutation(genome)
        {mutated_genome, acc_mutations ++ [mutation]}
      else
        {genome, acc_mutations}
      end
    end)

    {mutated_genomes, all_mutations}
  end

  defp apply_random_mutation(genome) do
    # Randomly select mutation type
    mutation_types = [:contract, :event, :protocol]
    selected_type = Enum.random(mutation_types)

    case selected_type do
      :contract ->
        ContractMutations.add_contract(genome, "test_capability", "test_subject")

      :event ->
        # For now, just return unchanged genome (would need workflow context)
        {genome, nil}

      :protocol ->
        # For now, just return unchanged genome (would need protocol ID)
        {genome, nil}
    end
  end

  defp perform_transfers(genomes, species_map, transfer_rate) do
    # Group genomes by species
    species_genomes = group_by_species(genomes, species_map)

    # Attempt transfers between different species
    {transferred_genomes, all_transfers} = Enum.reduce(
      species_genomes,
      {genomes, []},
      fn {_species_id, source_genomes}, {current_genomes, acc_transfers} ->
        if length(current_genomes) > 0 and :rand.uniform() < transfer_rate do
          # Select random source and target from different species
          source = Enum.random(source_genomes)
          target = Enum.random(current_genomes)

          if source.genome_id != target.genome_id do
            # Attempt transfer
            case Transfer.apply(source, target, :auth_pattern, "JWT authentication") do
              {:ok, new_target, transfer} ->
                # Replace target in population
                updated_genomes = replace_genome(current_genomes, target, new_target)
                {updated_genomes, acc_transfers ++ [transfer]}

              _ ->
                {current_genomes, acc_transfers}
            end
          else
            {current_genomes, acc_transfers}
          end
        else
          {current_genomes, acc_transfers}
        end
      end
    )

    {transferred_genomes, all_transfers}
  end

  defp group_by_species(genomes, species_map) do
    # Create reverse mapping: genome_id -> species_id
    genome_to_species = Enum.reduce(species_map, %{}, fn {species_id, genome_ids}, acc ->
      Enum.reduce(genome_ids, acc, fn genome_id, acc2 ->
        Map.put(acc2, genome_id, species_id)
      end)
    end)

    # Group genomes by species
    Enum.group_by(genomes, fn genome ->
      Map.get(genome_to_species, genome.genome_id, "unknown")
    end)
  end

  defp replace_genome(genomes, old_genome, new_genome) do
    Enum.map(genomes, fn g ->
      if g.genome_id == old_genome.genome_id do
        new_genome
      else
        g
      end
    end)
  end

  # Statistics Building

  defp build_generation_stats(%__MODULE__{} = state) do
    fitness_scores = Enum.map(state.population.genomes, & &1.fitness)

    best_fitness = if length(fitness_scores) > 0 do
      Enum.max(fitness_scores)
    else
      0.0
    end

    avg_fitness = if length(fitness_scores) > 0 do
      Enum.sum(fitness_scores) / length(fitness_scores)
    else
      0.0
    end

    %{
      generation: state.generation,
      population_size: length(state.population.genomes),
      species_count: map_size(state.species_map),
      best_fitness: best_fitness,
      avg_fitness: avg_fitness,
      mutations_applied: length(state.all_mutations),
      transfers_attempted: length(state.transfers),
      law_candidates_generated: length(state.law_candidates)
    }
  end

  defp build_comprehensive_stats(%__MODULE__{} = state) do
    pop_stats = Population.get_statistics(state.population)

    %{
      population: pop_stats,
      generation: state.generation,
      total_mutations: length(state.all_mutations),
      total_transfers: length(state.transfers),
      law_candidates: length(state.law_candidates),
      species_distribution: state.species_map
    }
  end
end
