defmodule TiannaraRuntime.MultiWorld.Events.EventStore do
  @moduledoc """
  Minimal Phase 5E Event Store
  
  Append-only ETS-based event log for world state transitions.
  
  ## Purpose
  
  Captures all world lifecycle events for:
  - ImmuneCortex risk assessment
  - SafetyCortex regulatory decisions
  - Audit trail and debugging
  
  ## Event Types
  
      :world_spawned
      :world_metrics_updated
      :world_risk_assessed
      :world_regulated
      :world_frozen
      :world_terminated
      :world_recovered
  
  ## Usage
  
      EventStore.record_event(:world_spawned, %{world_id: "w1", entropy: 0.3})
      events = EventStore.get_events("w1")
  """

  use GenServer

  @table_name :cis_event_store

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Create ETS table for event storage
    :ets.new(@table_name, [:ordered_set, :public, :named_table])

    Mix.shell().info("📦 EventStore initialized (ETS: #{@table_name})")

    {:ok, %{event_count: 0}}
  end

  @doc """
  Record a world event with timestamp and metadata.
  """
  def record_event(event_type, metadata \\ %{}) when is_atom(event_type) do
    timestamp = System.system_time(:millisecond)
    event_id = "#{metadata.world_id}_#{timestamp}"

    event = %{
      id: event_id,
      type: event_type,
      world_id: Map.get(metadata, :world_id),
      timestamp: timestamp,
      metadata: metadata
    }

    # Insert into ETS (ordered by timestamp)
    :ets.insert(@table_name, {timestamp, event_id, event})

    # Increment counter
    GenServer.cast(__MODULE__, :increment_count)

    event
  end

  @doc """
  Get all events for a specific world, ordered by timestamp.
  """
  def get_events(world_id) do
    # Match all events for this world_id using select
    # Pattern: {timestamp, event_id, %{world_id: ^world_id}}
    pattern = {:_, :_, {:map, :_, [{:world_id, world_id}]}}
    
    matches = :ets.select(@table_name, [{pattern, [], [:'$_']}])

    # Sort by timestamp and extract event data
    matches
    |> Enum.sort_by(fn {timestamp, _id, _event} -> timestamp end)
    |> Enum.map(fn {_timestamp, _id, event} -> event end)
  end

  @doc """
  Get recent events across all worlds (for dashboard monitoring).
  """
  def get_recent_events(limit \\ 50) do
    # Get all events, sort by timestamp descending, take limit
    :ets.tab2list(@table_name)
    |> Enum.sort_by(fn {timestamp, _id, _event} -> timestamp end, :desc)
    |> Enum.take(limit)
    |> Enum.map(fn {_timestamp, _id, event} -> event end)
  end

  @doc """
  Get event count for monitoring.
  """
  def get_event_count do
    GenServer.call(__MODULE__, :get_count)
  end

  @doc """
  Clear all events (for testing only).
  """
  def clear_all do
    :ets.delete_all_objects(@table_name)
    GenServer.cast(__MODULE__, :reset_count)
  end

  # ----------------------------
  # GenServer callbacks
  # ----------------------------

  @impl true
  def handle_cast(:increment_count, state) do
    {:noreply, %{state | event_count: state.event_count + 1}}
  end

  @impl true
  def handle_cast(:reset_count, state) do
    {:noreply, %{state | event_count: 0}}
  end

  @impl true
  def handle_call(:get_count, _from, state) do
    {:reply, state.event_count, state}
  end
end
