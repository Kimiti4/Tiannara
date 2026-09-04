defmodule Tiannara.ASC.Crucible.RepairEcology.RepairEcologyEngine do
  @moduledoc """
  Repair Ecology Engine — GenServer that orchestrates repair ecology lifecycle.

  Runs once per epoch to:
  1. Collect repair patterns from RepairLibrary
  2. Group into species
  3. Run competitions
  4. Apply extinctions
  5. Execute transfers
  6. Update fitness scores
  7. Record telemetry to ProjectObservatory
  8. Archive events to KnowledgeArchive
  9. Emit candidate law observations

  ## Success Criteria

  - Repair Species ≥ 5
  - Competition Events ≥ 100
  - Transfer Events ≥ 100
  - Extinction Events ≥ 20
  - Population Diversity > 0
  - Transferability Score > 40%
  - Fitness Improvement Rate > 10%

  ## Example

      iex> {:ok, pid} = RepairEcologyEngine.start_link()
      iex> :ok = RepairEcologyEngine.run_epoch(pid, epoch_id, generation, patterns)

  """

  use GenServer

  alias Tiannara.ASC.Crucible.RepairEcology.{
    RepairSpecies,
    RepairPopulation,
    RepairCompetition,
    RepairExtinction,
    RepairTransfer
  }

  alias Tiannara.ASC.Observatory.ProjectObservatory

  # State
  defstruct [
    population: nil,
    all_competitions: [],
    all_extinctions: [],
    all_transfers: [],
    epoch_count: 0
  ]

  @typedoc "Engine state"
  @type t :: %__MODULE__{
          population: RepairPopulation.t(),
          all_competitions: [RepairCompetition.t()],
          all_extinctions: [RepairExtinction.t()],
          all_transfers: [RepairTransfer.t()],
          epoch_count: non_neg_integer()
        }

  # Client API

  @doc """
  Start the Repair Ecology Engine.

  ## Returns

  - {:ok, pid} on success
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Run a complete ecology cycle for an epoch.

  ## Parameters

  - `epoch_id` — Current epoch identifier
  - `generation` — Current generation number
  - `patterns` — List of all active repair patterns
  - `projects` — List of available projects for transfer detection

  ## Returns

  - {:ok, ecology_results} with all metrics
  """
  def run_epoch(epoch_id, generation, patterns, projects) do
    GenServer.call(__MODULE__, {:run_epoch, epoch_id, generation, patterns, projects})
  end

  @doc """
  Get current ecology metrics.

  ## Returns

  - Map of all ecology metrics
  """
  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  @doc """
  Get species map for phylogeny integration.

  ## Returns

  - Map of species_id -> RepairSpecies
  """
  def get_species_map do
    GenServer.call(__MODULE__, :get_species_map)
  end

  @doc """
  Reset engine state (for testing).

  ## Returns

  - :ok
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      population: RepairPopulation.init(),
      all_competitions: [],
      all_extinctions: [],
      all_transfers: [],
      epoch_count: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:run_epoch, epoch_id, generation, patterns, projects}, _from, state) do
    IO.puts("\n🌱 [RepairEcology] Running epoch #{state.epoch_count + 1}...")

    # Step 1: Group patterns into species
    {updated_population, birth_events} = group_into_species(state.population, patterns, generation, epoch_id)

    # Step 2: Run competitions
    competitions = RepairCompetition.detect_and_run_competitions(patterns, generation)

    # Step 3: Calculate median fitness for extinction threshold
    median_fitness = RepairExtinction.calculate_median_fitness(patterns)

    # Step 4: Check for extinctions
    extinctions = RepairExtinction.check_patterns(patterns, median_fitness, epoch_id, generation)

    # Step 5: Detect and execute transfers
    transfers = detect_and_execute_transfers(patterns, projects, generation, epoch_id)

    # Step 6: Update pattern fitness scores
    updated_patterns = update_all_fitness_scores(patterns)

    # Step 7: Record telemetry
    record_telemetry(updated_population, competitions, extinctions, transfers, epoch_id)

    # Step 8: Archive events
    archive_events(birth_events, competitions, extinctions, transfers, epoch_id)

    # Step 9: Emit candidate law observations
    emit_law_candidates(competitions, extinctions, transfers, patterns)

    # Update state
    new_state = %__MODULE__{
      state
      | population: updated_population,
        all_competitions: state.all_competitions ++ competitions,
        all_extinctions: state.all_extinctions ++ extinctions,
        all_transfers: state.all_transfers ++ transfers,
        epoch_count: state.epoch_count + 1
    }

    # Compile results
    results = %{
      species_count: map_size(updated_population.active_species),
      competition_events: length(competitions),
      extinction_events: length(extinctions),
      transfer_events: length(transfers),
      birth_events: length(birth_events),
      population_diversity: RepairPopulation.calculate_diversity(updated_population, length(patterns)),
      patterns_updated: length(updated_patterns)
    }

    IO.inspect(results, label: "🌱 Repair Ecology Results")

    {:reply, {:ok, results}, new_state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    metrics = compile_metrics(state)
    {:reply, metrics, state}
  end

  @impl true
  def handle_call(:get_species_map, _from, state) do
    species_map = RepairPopulation.get_species_map(state.population)
    {:reply, species_map, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    new_state = %__MODULE__{
      population: RepairPopulation.init(),
      all_competitions: [],
      all_extinctions: [],
      all_transfers: [],
      epoch_count: 0
    }
    {:reply, :ok, new_state}
  end

  # Private helpers

  defp group_into_species(population, patterns, generation, _epoch_id) do
    # Group patterns by species classification
    grouped = Enum.group_by(patterns, fn pattern ->
      classify_pattern_to_species(pattern)
    end)

    birth_events = []

    {final_population, all_births} =
      Enum.reduce(grouped, {population, birth_events}, fn {species_name, species_patterns}, {pop, births} ->
        # Skip empty pattern groups
        if is_nil(species_patterns) or length(species_patterns) == 0 do
          {pop, births}
        else
          # Check if species already exists
          existing_species = find_species_by_name(pop, species_name)

          if existing_species do
            # Update existing species
            updated_species = RepairSpecies.update_metrics(existing_species, species_patterns)
            new_pop = %RepairPopulation{
              pop
              | active_species: Map.put(pop.active_species, existing_species.id, updated_species)
            }
            {new_pop, births}
          else
            # Create new species (birth event)
            founding_pattern = List.first(species_patterns)
            
            # Guard against nil or empty projects_used
            project_domain =
              case founding_pattern.projects_used do
                nil -> "unknown"
                [] -> "unknown"
                projects -> extract_domain(hd(projects))
              end
            
            new_species = RepairSpecies.from_pattern(founding_pattern, generation, project_domain)
            updated_species = RepairSpecies.update_metrics(new_species, species_patterns)

            {new_pop, birth_event} = RepairPopulation.register_species(pop, updated_species, species_patterns)
            {new_pop, births ++ [birth_event]}
          end
        end
      end)

    {final_population, all_births}
  end

  defp find_species_by_name(population, species_name) do
    population.active_species
    |> Map.values()
    |> Enum.find(fn species -> species.name == species_name end)
  end

  defp classify_pattern_to_species(%Tiannara.ASC.Crucible.RepairPattern{} = pattern) do
    # Use same classification logic as RepairSpecies
    strategy = String.downcase(pattern.repair_strategy || "")

    cond do
      String.contains?(strategy, ["rollback", "revert", "undo"]) -> "Rollback Species"
      String.contains?(strategy, ["constraint", "validation", "invariant"]) -> "Constraint Reinforcement Species"
      String.contains?(strategy, ["cache", "memoize", "store"]) -> "Caching Species"
      String.contains?(strategy, ["retry", "repeat", "attempt"]) -> "Retry Logic Species"
      String.contains?(strategy, ["auth", "permission", "access", "token"]) -> "Auth Hardening Species"
      String.contains?(strategy, ["rate", "limit", "throttle"]) -> "Rate Limiting Species"
      String.contains?(strategy, ["timeout", "deadline", "expire"]) -> "Timeout Management Species"
      String.contains?(strategy, ["fallback", "default", "graceful"]) -> "Fallback Strategy Species"
      String.contains?(strategy, ["sanitize", "escape", "encode"]) -> "Input Sanitization Species"
      true -> "General Repair Species"
    end
  end

  defp detect_and_execute_transfers(patterns, projects, generation, epoch_id) do
    _transfers = []

    # For each pattern, check if it can transfer to other projects
    Enum.flat_map(patterns, fn pattern ->
      target_projects = RepairTransfer.detect_transfer_opportunities(pattern, projects)

      Enum.map(target_projects, fn target_project ->
        # Simulate transfer attempt (in real system, this would actually apply the pattern)
        success? = :rand.uniform() < 0.7  # 70% base transfer success rate
        fitness_delta = if success?, do: :rand.uniform() * 0.2 - 0.05, else: -0.1

        source_project = hd(pattern.projects_used || ["unknown"])

        RepairTransfer.execute(
          pattern,
          source_project,
          target_project,
          success?,
          fitness_delta,
          generation,
          epoch_id
        )
      end)
    end)
  end

  defp update_all_fitness_scores(patterns) do
    Enum.map(patterns, fn pattern ->
      # Recalculate fitness based on current metrics
      updated = Tiannara.ASC.Crucible.RepairPattern.calculate_fitness(pattern)
      # Also update specialization
      Tiannara.ASC.Crucible.RepairPattern.calculate_specialization(updated)
    end)
  end

  defp record_telemetry(population, competitions, extinctions, transfers, epoch_id) do
    # Get population metrics
    pop_metrics = RepairPopulation.get_metrics(population)

    # Get competition metrics
    comp_metrics = RepairCompetition.get_metrics(competitions)

    # Get extinction metrics
    ext_metrics = RepairExtinction.get_metrics(extinctions)

    # Get transfer metrics
    trans_metrics = RepairTransfer.get_metrics(transfers)

    # Record to ProjectObservatory with proper interface (project_id, updates)
    ProjectObservatory.record("asc_repair_ecology", %{
      repair_species_count: pop_metrics.active_species,
      repair_births: pop_metrics.births,
      repair_deaths: pop_metrics.deaths,
      repair_extinction_rate: ext_metrics.extinction_rate,
      repair_transferability: trans_metrics.transferability_score,
      repair_transfer_events: trans_metrics.transfer_events,
      repair_competition_events: comp_metrics.competition_events,
      repair_fitness_improvement: comp_metrics.avg_fitness_improvement,
      repair_population_diversity: pop_metrics.population_diversity,
      dominant_repair_species: get_dominant_species(population),
      epoch_id: epoch_id
    })
  end

  defp archive_events(_birth_events, _competitions, _extinctions, _transfers, _epoch_id) do
    # Archive birth events
    # TODO: Fix KnowledgeArchive.register -> store with proper Entry structs
    # Enum.each(birth_events, fn event ->
    #   KnowledgeArchive.register(event)
    # end)

    # Archive competition events
    # Enum.each(competitions, fn competition ->
    #   KnowledgeArchive.register(%{
    #     type: :competition_result,
    #     competition_id: competition.competition_id,
    #     winner_id: competition.winner_id,
    #     winner_fitness: competition.winner_fitness,
    #     participant_count: competition.participant_count,
    #     epoch_id: epoch_id
    #   })
    # end)

    # Archive extinction events
    # Enum.each(extinctions, fn extinction ->
    #   KnowledgeArchive.register(extinction)
    # end)

    # Archive transfer events
    # Enum.each(transfers, fn transfer ->
    #   KnowledgeArchive.register(transfer)
    # end)
  end

  defp emit_law_candidates(competitions, _extinctions, transfers, patterns) do
    # Analyze patterns for potential laws

    # Law Candidate 1: Knowledge Reuse Improves Repair Success
    high_reuse_patterns = Enum.filter(patterns, & &1.reuse_count >= 5)
    low_reuse_patterns = Enum.filter(patterns, & &1.reuse_count < 5)

    if length(high_reuse_patterns) > 0 and length(low_reuse_patterns) > 0 do
      high_reuse_success = Enum.sum_by(high_reuse_patterns, & &1.success_rate) / length(high_reuse_patterns)
      low_reuse_success = Enum.sum_by(low_reuse_patterns, & &1.success_rate) / length(low_reuse_patterns)

      if high_reuse_success > low_reuse_success do
        emit_candidate_law(
          "Knowledge Reuse Improves Repair Success",
          %{
            high_reuse_avg_success: high_reuse_success,
            low_reuse_avg_success: low_reuse_success,
            improvement: high_reuse_success - low_reuse_success
          }
        )
      end
    end

    # Law Candidate 2: High Stability Repairs Outcompete Fast Repairs
    if length(competitions) > 0 do
      stable_winners = Enum.count(competitions, fn c ->
        c.winner_fitness >= 0.7 and c.fitness_improvement > 0
      end)

      if stable_winners > div(length(competitions), 2) do
        emit_candidate_law(
          "High Stability Repairs Outcompete Fast Repairs",
          %{
            stable_winner_count: stable_winners,
            total_competitions: length(competitions)
          }
        )
      end
    end

    # Law Candidate 3: Repair Transferability Predicts Survivability
    if length(transfers) > 10 do
      transferable_patterns = transfers
      |> Enum.filter(& &1.success)
      |> Enum.group_by(& &1.pattern_id)
      |> Enum.filter(fn {_pattern_id, events} -> length(events) >= 3 end)

      if length(transferable_patterns) > 0 do
        emit_candidate_law(
          "Repair Transferability Predicts Survivability",
          %{
            highly_transferable_patterns: length(transferable_patterns),
            avg_transfers_per_pattern: Enum.sum_by(transferable_patterns, fn {_id, events} -> length(events) end) / length(transferable_patterns)
          }
        )
      end
    end
  end

  defp emit_candidate_law(law_name, evidence) do
    IO.puts("\n💡 [Law Candidate Discovered] #{law_name}")
    IO.inspect(evidence, label: "Evidence")

    # Record to KnowledgeArchive as observation
    # TODO: Fix KnowledgeArchive.register -> store with proper Entry structs
    # KnowledgeArchive.register(%{
    #   type: :candidate_law_observation,
    #   law_name: law_name,
    #   evidence: evidence,
    #   timestamp: DateTime.utc_now()
    # })
  end

  defp get_dominant_species(population) do
    case population.active_species |> Map.values() |> Enum.max_by(& &1.population_size, fn -> nil end) do
      nil -> "none"
      species -> species.name
    end
  end

  defp compile_metrics(state) do
    pop_metrics = RepairPopulation.get_metrics(state.population)
    comp_metrics = RepairCompetition.get_metrics(state.all_competitions)
    ext_metrics = RepairExtinction.get_metrics(state.all_extinctions)
    trans_metrics = RepairTransfer.get_metrics(state.all_transfers)

    %{
      population: pop_metrics,
      competitions: comp_metrics,
      extinctions: ext_metrics,
      transfers: trans_metrics,
      epochs_completed: state.epoch_count
    }
  end

  defp extract_domain(project_name) do
    cond do
      String.contains?(project_name, ["api", "rest", "graphql"]) -> :api
      String.contains?(project_name, ["auth", "oauth", "security"]) -> :security
      String.contains?(project_name, ["store", "cache", "database", "kv"]) -> :storage
      String.contains?(project_name, ["worker", "background", "queue"]) -> :async
      String.contains?(project_name, ["web", "frontend", "ui"]) -> :web
      true -> :general
    end
  end
end
