defmodule TiannaraRuntime.Identity.CoalitionHistory do
  @moduledoc """
  PHASE 4B: Coalition History Store
  
  Tracks full lifecycle of coalitions from birth to death.
  
  Lifecycle events:
  - birth: coalition formed
  - update: properties changed
  - split: coalition divided into multiple
  - merge: coalition merged with another
  - death: coalition dissolved
  
  Design Principle: Append-only event log per coalition
  """
  
  use GenServer
  require Logger
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Record a coalition lifecycle event.
  """
  def record_event(coalition_id, event_type, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:record, coalition_id, event_type, metadata})
  end
  
  @doc """
  Get full history for a coalition.
  """
  def get_history(coalition_id) do
    GenServer.call(__MODULE__, {:history, coalition_id})
  end
  
  @doc """
  Get all active coalitions.
  """
  def get_active_coalitions() do
    GenServer.call(__MODULE__, :active)
  end
  
  @doc """
  Get lineage (ancestry chain) for a coalition.
  """
  def get_lineage(coalition_id) do
    GenServer.call(__MODULE__, {:lineage, coalition_id})
  end
  
  @doc """
  Get statistics for all coalitions.
  """
  def get_statistics() do
    GenServer.call(__MODULE__, :statistics)
  end

  @doc """
  Get lifecycle statistics for a coalition
  """
  def get_lifecycle_stats(coalition_id) do
    GenServer.call(__MODULE__, {:lifecycle_stats, coalition_id})
  end
  
  # Server Callbacks
  
  @impl true
  def init(_opts) do
    state = %{
      histories: %{},       # coalition_id -> [events]
      active_ids: MapSet.new(),
      parent_map: %{},      # child_id -> parent_id (for lineage)
      total_births: 0,
      total_deaths: 0
    }
    
    Logger.info("✅ CoalitionHistory store initialized")
    {:ok, state}
  end
  
  @impl true
  def handle_cast({:record, coalition_id, event_type, metadata}, state) do
    timestamp = DateTime.utc_now() |> DateTime.to_unix(:millisecond)
    
    event = %{
      type: event_type,
      timestamp: timestamp,
      metadata: metadata
    }
    
    # Update history
    existing_events = Map.get(state.histories, coalition_id, [])
    updated_events = existing_events ++ [event]
    
    # Update active status based on event type
    new_active_ids = case event_type do
      "birth" ->
        MapSet.put(state.active_ids, coalition_id)
      
      "death" ->
        MapSet.delete(state.active_ids, coalition_id)
      
      "split" ->
        # Parent dies, children born
        MapSet.delete(state.active_ids, coalition_id)
        |> add_children(metadata)
      
      "merge" ->
        # Old coalitions die, new one born
        old_ids = Map.get(metadata, "merged_coalitions", [])
        Enum.reduce(old_ids, state.active_ids, &MapSet.delete(&2, &1))
        |> MapSet.put(coalition_id)
      
      _ ->
        state.active_ids
    end
    
    # Update parent map for lineage tracking
    new_parent_map = case event_type do
      "split" ->
        children = Map.get(metadata, "children", [])
        Enum.reduce(children, state.parent_map, fn child_id, acc ->
          Map.put(acc, child_id, coalition_id)
        end)
      
      "merge" ->
        old_ids = Map.get(metadata, "merged_coalitions", [])
        Enum.reduce(old_ids, state.parent_map, fn old_id, acc ->
          Map.put(acc, coalition_id, old_id)
        end)
      
      _ ->
        state.parent_map
    end
    
    # Update counters
    new_state = %{
      state |
      histories: Map.put(state.histories, coalition_id, updated_events),
      active_ids: new_active_ids,
      parent_map: new_parent_map,
      total_births: if(event_type == "birth", do: state.total_births + 1, else: state.total_births),
      total_deaths: if(event_type == "death", do: state.total_deaths + 1, else: state.total_deaths)
    }
    
    Logger.debug("📝 Recorded #{event_type} for coalition #{coalition_id}")
    
    {:ok, new_state}
  end
  
  @impl true
  def handle_call({:history, coalition_id}, _from, state) do
    history = Map.get(state.histories, coalition_id, [])
    {:reply, {:ok, history}, state}
  end
  
  @impl true
  def handle_call(:active, _from, state) do
    active_list = MapSet.to_list(state.active_ids)
    {:reply, {:ok, active_list}, state}
  end
  
  @impl true
  def handle_call({:lineage, coalition_id}, _from, state) do
    lineage = trace_lineage(coalition_id, state.parent_map, [])
    {:reply, {:ok, lineage}, state}
  end
  
  @impl true
  def handle_call(:statistics, _from, state) do
    stats = %{
      total_births: state.total_births,
      total_deaths: state.total_deaths,
      currently_active: MapSet.size(state.active_ids),
      unique_coalitions: map_size(state.histories)
    }
    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_call({:lifecycle_stats, coalition_id}, _from, state) do
    # Basic implementation - could be enhanced with more detailed analysis
    history = Map.get(state.histories, coalition_id, [])
    nodes = Enum.count(history, &(&1.type == "birth")) + 1
    
    stats = %{
      nodes: nodes,
      merges: Enum.count(history, &(&1.type == "merge")),
      entropy: calculate_entropy(history)
    }
    
    {:reply, {:ok, stats}, state}
  end

  defp calculate_entropy(history) do
    # Simplified entropy calculation based on event diversity
    if length(history) < 2 do
      0.0
    else
      event_types = Enum.map(history, &Map.get(&1, :type))
      unique_types = Enum.uniq(event_types) |> length
      max_types = 5 # Maximum possible event types
      
      unique_types / max_types
    end
  end
  
  # Private Functions
  
  defp add_children(active_set, metadata) do
    children = Map.get(metadata, "children", [])
    Enum.reduce(children, active_set, &MapSet.put(&2, &1))
  end
  
  defp trace_lineage(coalition_id, parent_map, acc) do
    case Map.get(parent_map, coalition_id) do
      nil ->
        # No parent, this is the root
        [coalition_id | acc]
      
      parent_id ->
        # Continue tracing up
        trace_lineage(parent_id, parent_map, [coalition_id | acc])
    end
  end
end
