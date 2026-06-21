defmodule Tiannara.ASC.Interface.Registry do
  @moduledoc """
  Interface Registry — ETS-based persistence for interface genomes and evolution runs.

  Replaces the SQLAlchemy database from the Python implementation with
  in-memory ETS tables for fast access and OTP compatibility.

  ## Tables

  - `:asc_interface_genomes` — Stores all evolved interface genomes
  - `:asc_interface_runs` — Tracks evolution run metadata and history

  ## Usage

      iex> {:ok, _} = Tiannara.ASC.Interface.Registry.start_link([])
      iex> genome = Tiannara.ASC.Interface.Genome.new()
      iex> Tiannara.ASC.Interface.Registry.register_genome(genome)
      :ok
      iex> retrieved = Tiannara.ASC.Interface.Registry.get_genome(genome.genome_id)
      iex> retrieved.genome_id == genome.genome_id
      true

  """

  use GenServer

  @table_genomes :asc_interface_genomes
  @table_runs :asc_interface_runs

  # ---------------------------------------------------------------------------
  # Client API
  # ---------------------------------------------------------------------------

  @doc """
  Start the Registry GenServer and initialize ETS tables.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Register a new interface genome in the registry.

  Stores the genome with timestamp for later retrieval and analysis.

  ## Parameters

  - `genome` — Interface genome struct to register

  ## Returns

  - `:ok` on success

  """
  def register_genome(%Tiannara.ASC.Interface.Genome{} = genome) do
    GenServer.call(__MODULE__, {:register_genome, genome})
  end

  @doc """
  Retrieve a genome by ID.

  ## Parameters

  - `genome_id` — UUID of the genome to retrieve

  ## Returns

  - `%Interface.Genome{}` if found
  - `nil` if not found

  """
  def get_genome(genome_id) when is_binary(genome_id) do
    GenServer.call(__MODULE__, {:get_genome, genome_id})
  end

  @doc """
  List all genomes, optionally filtered by generation or fitness threshold.

  ## Parameters

  - `filters` — Optional filter map (e.g., `%{min_fitness: 0.5}`)

  ## Returns

  - List of genome structs

  """
  def list_genomes(filters \\ %{}) do
    GenServer.call(__MODULE__, {:list_genomes, filters})
  end

  @doc """
  Register a new evolution run.

  Creates a run record to track the evolution process.

  ## Parameters

  - `run_id` — Unique identifier for this run
  - `metadata` — Run metadata (generations, population_size, etc.)

  ## Returns

  - `:ok` on success

  """
  def register_run(run_id, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:register_run, run_id, metadata})
  end

  @doc """
  Update an evolution run with results.

  Stores the best genome, fitness history, and completion status.

  ## Parameters

  - `run_id` — ID of the run to update
  - `results` — Map containing best_genome, history, status, etc.

  ## Returns

  - `:ok` on success

  """
  def update_run(run_id, results) do
    GenServer.call(__MODULE__, {:update_run, run_id, results})
  end

  @doc """
  Get an evolution run by ID.

  ## Parameters

  - `run_id` — ID of the run to retrieve

  ## Returns

  - Run metadata map if found
  - `nil` if not found

  """
  def get_run(run_id) when is_binary(run_id) do
    GenServer.call(__MODULE__, {:get_run, run_id})
  end

  @doc """
  List all evolution runs.

  ## Returns

  - List of run metadata maps

  """
  def list_runs do
    GenServer.call(__MODULE__, :list_runs)
  end

  @doc """
  Delete all genomes and runs (for testing).

  WARNING: This clears all data. Use only in test environments.
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # ---------------------------------------------------------------------------
  # Server callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    # Initialize ETS tables
    :ets.new(@table_genomes, [:named_table, :set, :public, read_concurrency: true])
    :ets.new(@table_runs, [:named_table, :set, :public, read_concurrency: true])

    {:ok, %{}}
  end

  @impl true
  def handle_call({:register_genome, genome}, _from, state) do
    encoded = Tiannara.ASC.Interface.Genome.encode(genome)
    record = Map.put(encoded, :registered_at, DateTime.utc_now())

    :ets.insert(@table_genomes, {genome.genome_id, record})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get_genome, genome_id}, _from, state) do
    result = case :ets.lookup(@table_genomes, genome_id) do
      [{^genome_id, record}] -> Tiannara.ASC.Interface.Genome.decode(record)
      [] -> nil
    end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:list_genomes, filters}, _from, state) do
    all_records = :ets.tab2list(@table_genomes)

    genomes = Enum.map(all_records, fn {_id, record} ->
      Tiannara.ASC.Interface.Genome.decode(record)
    end)

    # Apply filters
    filtered = apply_filters(genomes, filters)

    {:reply, filtered, state}
  end

  @impl true
  def handle_call({:register_run, run_id, metadata}, _from, state) do
    record = Map.merge(%{
      run_id: run_id,
      status: "running",
      started_at: DateTime.utc_now(),
      completed_at: nil,
      best_fitness: 0.0,
      best_genome_id: nil,
      history: [],
      total_generations: Map.get(metadata, :generations, 0),
      population_size: Map.get(metadata, :population_size, 0)
    }, metadata)

    :ets.insert(@table_runs, {run_id, record})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:update_run, run_id, results}, _from, state) do
    case :ets.lookup(@table_runs, run_id) do
      [{^run_id, existing}] ->
        updated = Map.merge(existing, %{
          status: Map.get(results, :status, "completed"),
          best_fitness: Map.get(results, :best_fitness, 0.0),
          best_genome_id: Map.get(results, :best_genome_id),
          history: Map.get(results, :history, []),
          completed_at: DateTime.utc_now()
        })

        :ets.insert(@table_runs, {run_id, updated})
        {:reply, :ok, state}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_run, run_id}, _from, state) do
    result = case :ets.lookup(@table_runs, run_id) do
      [{^run_id, record}] -> record
      [] -> nil
    end

    {:reply, result, state}
  end

  @impl true
  def handle_call(:list_runs, _from, state) do
    all_records = :ets.tab2list(@table_runs)
    runs = Enum.map(all_records, fn {_id, record} -> record end)

    {:reply, runs, state}
  end

  @impl true
  def handle_call(:reset, _from, state) do
    :ets.delete_all_objects(@table_genomes)
    :ets.delete_all_objects(@table_runs)
    {:reply, :ok, state}
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp apply_filters(genomes, filters) do
    genomes
    |> filter_by_min_fitness(Map.get(filters, :min_fitness))
    |> filter_by_generation(Map.get(filters, :generation))
    |> sort_by_fitness(Map.get(filters, :sort_by, :fitness_desc))
  end

  defp filter_by_min_fitness(genomes, nil), do: genomes
  defp filter_by_min_fitness(genomes, min_fitness) do
    Enum.filter(genomes, &(&1.fitness >= min_fitness))
  end

  defp filter_by_generation(genomes, nil), do: genomes
  defp filter_by_generation(genomes, generation) do
    Enum.filter(genomes, &(&1.generation == generation))
  end

  defp sort_by_fitness(genomes, :fitness_desc) do
    Enum.sort_by(genomes, & &1.fitness, :desc)
  end

  defp sort_by_fitness(genomes, :fitness_asc) do
    Enum.sort_by(genomes, & &1.fitness, :asc)
  end

  defp sort_by_fitness(genomes, _), do: genomes
end
