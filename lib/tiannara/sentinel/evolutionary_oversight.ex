defmodule Tiannara.Sentinel.EvolutionaryOversight do
  @moduledoc """
  Evolutionary Oversight — fitness, diversity, and evolutionary-health
  tracking for SOPL LawSpecies and REA MetaGenomes.

  Monitors the evolutionary dynamics of Tiannara's cognitive ecosystems:
  - Fitness tracking across populations and generations
  - Diversity metrics (Shannon entropy, species richness, phylogenetic diversity)
  - Stagnation detection (plateaus, monoculture, lock-in)
  - Evolutionary health reports and alerts
  """
  use GenServer
  require Logger

  @diversity_low_warning 0.3
  @stagnation_generations 10

  # ── Public API ──

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Records a population snapshot at a given generation.
  Populations are lists of individuals with fitness scores.
  """
  def record_generation(population_id, generation, individuals) do
    GenServer.cast(__MODULE__, {:record_generation, population_id, generation, individuals})
  end

  @doc """
  Records a fitness measurement for an individual or species.
  """
  def record_fitness(entity_id, fitness, opts \\ []) do
    GenServer.cast(__MODULE__, {:record_fitness, entity_id, fitness, opts})
  end

  @doc """
  Returns the current evolutionary health report for a population.
  """
  def population_health(population_id) do
    GenServer.call(__MODULE__, {:population_health, population_id})
  end

  @doc """
  Returns a summary of all tracked populations.
  """
  def all_populations_health do
    GenServer.call(__MODULE__, :all_populations_health)
  end

  @doc """
  Computes Shannon diversity entropy for a population.
  """
  def diversity_entropy(population_id) do
    GenServer.call(__MODULE__, {:diversity_entropy, population_id})
  end

  @doc """
  Detects evolutionary stagnation — generations with minimal fitness improvement.
  """
  def detect_stagnation(population_id, threshold \\ 0.01) do
    GenServer.call(__MODULE__, {:detect_stagnation, population_id, threshold})
  end

  @doc """
  Returns fitness history for a given entity.
  """
  def fitness_history(entity_id) do
    GenServer.call(__MODULE__, {:fitness_history, entity_id})
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    # population_id -> [%{generation: n, individuals: [...], timestamp: ...}]
    :ets.new(:evolution_generations, [:bag, :public, :named_table])
    # entity_id -> [{fitness, timestamp, metadata}]
    :ets.new(:evolution_fitness, [:bag, :public, :named_table])
    # population_id -> %{current_state}
    :ets.new(:evolution_populations, [:set, :public, :named_table])

    Logger.info("🧬 [EVOLUTION] Evolutionary Oversight initialized.")
    {:ok, %{
      generations_table: :evolution_generations,
      fitness_table: :evolution_fitness,
      populations_table: :evolution_populations
    }}
  end

  @impl true
  def handle_cast({:record_generation, pop_id, generation, individuals}, state) do
    entry = {pop_id, %{
      generation: generation,
      individuals: individuals,
      count: length(individuals),
      timestamp: DateTime.utc_now()
    }}
    :ets.insert(state.generations_table, entry)
    :ets.insert(state.populations_table, {pop_id, generation, length(individuals)})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:record_fitness, entity_id, fitness, opts}, state) do
    entry = {entity_id, fitness, DateTime.utc_now(), opts}
    :ets.insert(state.fitness_table, entry)
    {:noreply, state}
  end

  @impl true
  def handle_call({:population_health, pop_id}, _from, state) do
    health = compute_population_health(state, pop_id)
    {:reply, health, state}
  end

  @impl true
  def handle_call(:all_populations_health, _from, state) do
    pop_ids = :ets.tab2list(state.populations_table)
    |> Enum.map(fn {id, _gen, _count} -> id end)
    |> Enum.uniq()

    healths = Enum.map(pop_ids, fn id ->
      {id, compute_population_health(state, id)}
    end)

    {:reply, Map.new(healths), state}
  end

  @impl true
  def handle_call({:diversity_entropy, pop_id}, _from, state) do
    entropy = compute_shannon_entropy(state, pop_id)
    {:reply, entropy, state}
  end

  @impl true
  def handle_call({:detect_stagnation, pop_id, threshold}, _from, state) do
    stagnation = compute_stagnation(state, pop_id, threshold)
    {:reply, stagnation, state}
  end

  @impl true
  def handle_call({:fitness_history, entity_id}, _from, state) do
    history = :ets.match_object(state.fitness_table, {entity_id, :_, :_, :_})
    |> Enum.map(fn {_id, fitness, ts, opts} -> %{fitness: fitness, timestamp: ts, metadata: opts} end)
    |> Enum.sort_by(& &1.timestamp, :desc)
    {:reply, history, state}
  end

  # ── Private Helpers ──

  defp compute_population_health(state, pop_id) do
    generations = get_generations(state.generations_table, pop_id)
    fitness_entries = get_all_fitness(state.fitness_table)

    latest_gen = case generations do
      [] -> nil
      _ -> Enum.max_by(generations, & &1.generation)
    end

    all_individuals = Enum.flat_map(generations, & &1.individuals)
    unique_entities = Enum.uniq(all_individuals)

    fitness_values = Enum.map(fitness_entries, fn {_id, f, _ts, _opts} -> f end)
    mean_fitness = if fitness_values != [], do: Enum.sum(fitness_values) / length(fitness_values), else: 0.0
    max_fitness = if fitness_values != [], do: Enum.max(fitness_values), else: 0.0
    min_fitness = if fitness_values != [], do: Enum.min(fitness_values), else: 0.0

    variance = if length(fitness_values) > 1 do
      mean = mean_fitness
      squared_diffs = Enum.map(fitness_values, fn f -> (f - mean) ** 2 end)
      Enum.sum(squared_diffs) / (length(fitness_values) - 1)
    else 0.0 end

    entropy = compute_shannon_entropy_from_individuals(all_individuals)

    stagnation = compute_stagnation(state, pop_id, 0.01)

    stagnation_risk = case stagnation do
      %{stagnant: true, generations_stagnant: n} when n >= @stagnation_generations -> :critical
      %{stagnant: true, generations_stagnant: n} when n >= 5 -> :high
      %{stagnant: true} -> :moderate
      _ -> :none
    end

    monoculture_risk = if entropy < @diversity_low_warning, do: :high, else: :low

    %{
      population_id: pop_id,
      size: if(latest_gen, do: latest_gen.count, else: 0),
      generations: length(generations),
      latest_generation: if(latest_gen, do: latest_gen.generation, else: nil),
      fitness: %{
        mean: Float.round(mean_fitness, 4),
        max: Float.round(max_fitness, 4),
        min: Float.round(min_fitness, 4),
        variance: Float.round(variance, 4)
      },
      diversity: %{
        shannon_entropy: Float.round(entropy, 4),
        unique_entities: length(unique_entities)
      },
      stagnation: stagnation,
      monoculture_risk: monoculture_risk,
      stagnation_risk: stagnation_risk,
      assessment: health_assessment(entropy, stagnation, mean_fitness)
    }
  end

  defp health_assessment(entropy, stagnation, mean_fitness) do
    issues = []
    issues = if entropy < @diversity_low_warning, do: [:low_diversity | issues], else: issues
    issues = if stagnation.stagnant, do: [:stagnation | issues], else: issues
    issues = if mean_fitness < 0.3, do: [:low_fitness | issues], else: issues

    cond do
      issues == [] -> :healthy
      length(issues) == 1 -> :concerning
      true -> :critical
    end
  end

  defp get_generations(table, pop_id) do
    :ets.match_object(table, {pop_id, :_})
    |> Enum.map(fn {_id, gen} -> gen end)
    |> Enum.sort_by(& &1.generation, :desc)
  end

  defp get_all_fitness(table) do
    :ets.tab2list(table)
  end

  defp compute_shannon_entropy(state, pop_id) do
    individuals = get_generations(state.generations_table, pop_id)
    |> Enum.flat_map(& &1.individuals)

    compute_shannon_entropy_from_individuals(individuals)
  end

  defp compute_shannon_entropy_from_individuals(individuals) do
    total = length(individuals)
    if total == 0 do
      0.0
    else
      freq = Enum.frequencies(individuals)
      Enum.reduce(freq, 0.0, fn {_id, count}, acc ->
        p = count / total
        acc - p * :math.log2(p)
      end)
    end
  end

  defp compute_stagnation(state, pop_id, threshold) do
    generations = get_generations(state.generations_table, pop_id)
    |> Enum.sort_by(& &1.generation)

    if length(generations) < 3 do
      %{stagnant: false, generations_stagnant: 0, message: "Insufficient data"}
    else
      mean_fitness_per_gen = Enum.map(generations, fn gen ->
        fits = Enum.map(gen.individuals, fn ind -> get_entity_fitness(state.fitness_table, ind) end)
        if fits == [], do: 0.0, else: Enum.sum(fits) / length(fits)
      end)

      stagnant_gens = count_consecutive_stagnant(mean_fitness_per_gen, threshold, 0)

      %{
        stagnant: stagnant_gens >= 3,
        generations_stagnant: stagnant_gens,
        fitness_trend: if(length(mean_fitness_per_gen) >= 2, do:
          Float.round(List.last(mean_fitness_per_gen) - hd(mean_fitness_per_gen), 4), else: 0.0),
        threshold: threshold
      }
    end
  end

  defp count_consecutive_stagnant([], _threshold, count), do: count
  defp count_consecutive_stagnant([_a], _threshold, count), do: count
  defp count_consecutive_stagnant([a, b | rest], threshold, count) do
    if abs(b - a) < threshold do
      count_consecutive_stagnant([b | rest], threshold, count + 1)
    else
      count_consecutive_stagnant([b | rest], threshold, 0)
    end
  end

  defp get_entity_fitness(table, entity_id) do
    entries = :ets.match_object(table, {entity_id, :_, :_, :_})
    case entries do
      [] -> 0.0
      list -> list |> Enum.map(fn {_id, f, _ts, _opts} -> f end) |> Enum.max()
    end
  end
end
