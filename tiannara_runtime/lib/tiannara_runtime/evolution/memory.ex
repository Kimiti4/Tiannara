defmodule Tiannara.Evolution.Memory do
  @moduledoc """
  Evolutionary Memory Engine - Tracks WHY states survived, not just WHAT states exist.
  
  Stores complete lineage information for every chimera event including:
    - Parent world IDs
    - Subsystem origin mapping (which parent contributed which subsystem)
    - Selection temperature at time of merge
    - Fitness delta from recombination
    - Historical stability traces
  
  This enables:
    - Full evolutionary replay (Phase 4 requirement)
    - Species lineage tracking
    - Trait inheritance analysis
    - Chimeric DAG construction
  
  ## Memory Record Schema
  {
    "world_id": "CHIMERA-W1-W2",
    "parents": ["W1", "W2"],
    "resolved_subsystems": {
      "cal": "W1",
      "cis": "W2",
      "entropy": "INTER-HYBRID",
      "selection": "W1"
    },
    "selection_temperature": 0.12,
    "fitness_delta": +0.21,
    "timestamp": "2026-05-19T15:30:00Z"
  }
  """

  use GenServer
  require Logger

  @max_memory_records 1000
  @persistence_path "data/evolutionary_memory.db"

  defstruct [
    records: %{},  # %{world_id => record}
    lineage_graph: %{},  # %{child_id => [parent_ids]}
    record_count: 0
  ]

  @type t :: %__MODULE__{
    records: %{String.t() => chimera_record()},
    lineage_graph: %{String.t() => [String.t()]},
    record_count: non_neg_integer()
  }

  @type chimera_record :: %{
    world_id: String.t(),
    parents: [String.t()],
    resolved_subsystems: %{atom() => String.t()},
    selection_temperature: float(),
    fitness_delta: float(),
    timestamp: DateTime.t()
  }

  # Public API

  @doc """
  Starts the Evolutionary Memory GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Records a chimera merge event in evolutionary memory.
  
  ## Parameters
    - event: Map containing chimera event data
      Must include: world_id, parents, resolved_subsystems, selection_temperature, fitness_delta
  
  ## Examples
      iex> event = %{
      ...>   world_id: "CHIMERA-W1-W2",
      ...>   parents: ["W1", "W2"],
      ...>   resolved_subsystems: %{cal: "W1", cis: "W2"},
      ...>   selection_temperature: 0.15,
      ...>   fitness_delta: 0.21
      ...> }
      iex> Memory.record_chimera_event(event)
      :ok
  """
  def record_chimera_event(event) do
    GenServer.call(__MODULE__, {:record_event, event})
  end

  @doc """
  Retrieves the complete evolutionary record for a world.
  
  ## Returns
    - {:ok, record} if found
    - {:error, :not_found} if no record exists
  """
  def get_record(world_id) do
    GenServer.call(__MODULE__, {:get_record, world_id})
  end

  @doc """
  Retrieves all ancestors of a world (recursive lineage traversal).
  
  ## Returns
    - {:ok, [ancestor_ids]} - List of all ancestor world IDs
  """
  def get_ancestors(world_id) do
    GenServer.call(__MODULE__, {:get_ancestors, world_id})
  end

  @doc """
  Retrieves all descendants of a world.
  
  ## Returns
    - {:ok, [descendant_ids]} - List of all descendant world IDs
  """
  def get_descendants(world_id) do
    GenServer.call(__MODULE__, {:get_descendants, world_id})
  end

  @doc """
  Builds the complete Chimeric DAG (Directed Acyclic Graph).
  
  ## Returns
    - {:ok, %{nodes: [...], edges: [...]}} - DAG structure for visualization
  """
  def build_dag do
    GenServer.call(__MODULE__, :build_dag)
  end

  @doc """
  Returns all chimera events within a time range.
  """
  def get_events_in_range(start_time, end_time) do
    GenServer.call(__MODULE__, {:get_events_in_range, start_time, end_time})
  end

  @doc """
  Computes evolutionary statistics across all recorded events.
  
  ## Returns
    - %{
        total_merges: N,
        avg_fitness_delta: X.XX,
        most_common_subsystem_origin: %{cal: "W1", cis: "W2", ...},
        unique_species: N
      }
  """
  def get_statistics do
    GenServer.call(__MODULE__, :get_statistics)
  end

  @doc """
  Clears all memory records (for testing/reset).
  """
  def clear_memory do
    GenServer.call(__MODULE__, :clear)
  end

  # GenServer Callbacks

  @impl true
  def init(_opts) do
    Logger.info(" Evolutionary Memory Engine initialized")
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call({:record_event, event}, _from, state) do
    world_id = event.world_id

    record = %{
      world_id: world_id,
      parents: event.parents,
      resolved_subsystems: event.resolved_subsystems,
      selection_temperature: event.selection_temperature,
      fitness_delta: event.fitness_delta,
      timestamp: event.timestamp || DateTime.utc_now()
    }

    # Store record
    updated_records = Map.put(state.records, world_id, record)

    # Update lineage graph
    updated_lineage = Enum.reduce(event.parents, state.lineage_graph, fn parent_id, acc ->
      Map.update(acc, world_id, [parent_id], fn existing -> [parent_id | existing] end)
    end)

    new_state = %{
      state
      | records: updated_records,
        lineage_graph: updated_lineage,
        record_count: state.record_count + 1
    }

    # Persist to disk (async)
    persist_record(record)

    Logger.info(" Memory recorded: #{world_id} (parents: #{Enum.join(event.parents, ", ")})")

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:get_record, world_id}, _from, state) do
    case Map.fetch(state.records, world_id) do
      {:ok, record} -> {:reply, {:ok, record}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_ancestors, world_id}, _from, state) do
    ancestors = traverse_ancestors(world_id, state.lineage_graph, [])
    {:reply, {:ok, ancestors}, state}
  end

  @impl true
  def handle_call({:get_descendants, world_id}, _from, state) do
    descendants = traverse_descendants(world_id, state.lineage_graph)
    {:reply, {:ok, descendants}, state}
  end

  @impl true
  def handle_call(:build_dag, _from, state) do
    dag = construct_dag(state.records, state.lineage_graph)
    {:reply, {:ok, dag}, state}
  end

  @impl true
  def handle_call({:get_events_in_range, start_time, end_time}, _from, state) do
    filtered = state.records
    |> Map.values()
    |> Enum.filter(fn record ->
      record.timestamp >= start_time and record.timestamp <= end_time
    end)

    {:reply, {:ok, filtered}, state}
  end

  @impl true
  def handle_call(:get_statistics, _from, state) do
    stats = compute_statistics(state.records)
    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_call(:clear, _from, _state) do
    {:reply, :ok, %__MODULE__{}}
  end

  # Lineage Traversal

  defp traverse_ancestors(world_id, lineage_graph, visited) do
    case Map.fetch(lineage_graph, world_id) do
      {:ok, parents} ->
        Enum.reduce(parents, visited, fn parent_id, acc ->
          if parent_id in acc do
            acc
          else
            traverse_ancestors(parent_id, lineage_graph, [parent_id | acc])
          end
        end)

      :error ->
        visited
    end
  end

  defp traverse_descendants(world_id, lineage_graph) do
    # Find all nodes that have world_id as a parent
    descendants = lineage_graph
    |> Enum.filter(fn {_child, parents} -> world_id in parents end)
    |> Enum.map(fn {child_id, _parents} -> child_id end)

    # Recursively get descendants of descendants
    Enum.reduce(descendants, descendants, fn descendant, acc ->
      child_descendants = traverse_descendants(descendant, lineage_graph)
      Enum.uniq(acc ++ child_descendants)
    end)
  end

  # DAG Construction

  defp construct_dag(records, lineage_graph) do
    nodes = records
    |> Map.values()
    |> Enum.map(fn record ->
      %{
        id: record.world_id,
        type: :chimera,
        generation: extract_generation(record),
        fitness_delta: record.fitness_delta,
        timestamp: record.timestamp
      }
    end)

    edges = records
    |> Map.values()
    |> Enum.flat_map(fn record ->
      Enum.map(record.parents, fn parent_id ->
        %{
          from: parent_id,
          to: record.world_id,
          type: :merge,
          subsystem_origins: record.resolved_subsystems
        }
      end)
    end)

    %{nodes: nodes, edges: edges}
  end

  defp extract_generation(record) do
    # Extract generation from world_id if encoded, else default to 0
    case String.split(record.world_id, "-") do
      [_prefix, _id1, _id2] -> 1  # First generation chimera
      parts -> length(parts) - 1  # Approximate
    end
  end

  # Statistics

  defp compute_statistics(records) do
    if map_size(records) == 0 do
      %{
        total_merges: 0,
        avg_fitness_delta: 0.0,
        most_common_subsystem_origin: %{},
        unique_species: 0
      }
    else
      record_list = Map.values(records)

      total_merges = length(record_list)
      
      avg_fitness_delta = record_list
      |> Enum.map(& &1.fitness_delta)
      |> Enum.sum()
      |> then(&(&1 / total_merges))

      # Most common subsystem origin
      subsystem_counts = record_list
      |> Enum.flat_map(&Map.values(&1.resolved_subsystems))
      |> Enum.frequencies()

      most_common = subsystem_counts
      |> Enum.sort_by(fn {_origin, count} -> count end, :desc)
      |> Enum.take(1)
      |> case do
        [{origin, _count}] -> %{origin: origin, count: Enum.sum(subsystem_counts)}
        [] -> %{}
      end

      %{
        total_merges: total_merges,
        avg_fitness_delta: avg_fitness_delta,
        most_common_subsystem_origin: most_common,
        unique_species: map_size(records)
      }
    end
  end

  # Persistence (simplified - use ETS or PostgreSQL in production)

  defp persist_record(record) do
    # TODO: Implement actual disk persistence
    # Options:
    # 1. ETS table for in-memory cache
    # 2. PostgreSQL with JSONB columns
    # 3. SQLite for lightweight storage
    Logger.debug("Persisting record: #{record.world_id}")
    :ok
  end
end
