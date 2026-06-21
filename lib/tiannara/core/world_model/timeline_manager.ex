defmodule Tiannara.Core.WorldModel.TimelineManager do
  @moduledoc """
  Timeline Manager for the World Model.

  Manages past, present, future, and counterfactual states.
  """

  use GenServer
  require Logger

  @doc "Start the Timeline Manager server."
  def start_link(opts) do
    shard_id = Keyword.get(opts, :shard_id, :world_0)
    name = Tiannara.ROS.Registry.via(__MODULE__, shard_id)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Add an event to the timeline."
  def add_event(event_id, entity_id, event_type, description, timestamp \\ nil) do
    event = %{
      id: event_id,
      entity_id: entity_id,
      type: event_type,
      description: description,
      timestamp: timestamp || DateTime.utc_now(),
      metadata: %{},
      consequences: []
    }

    GenServer.call(__MODULE__, {:add_event, event})
  end

  @doc "Update an event's metadata."
  def update_event_metadata(event_id, metadata) do
    GenServer.call(__MODULE__, {:update_event_metadata, event_id, metadata})
  end

  @doc "Record consequences of an event."
  def record_event_consequences(event_id, consequences) do
    GenServer.call(__MODULE__, {:record_event_consequences, event_id, consequences})
  end

  @doc "Get an event by ID."
  def get_event(event_id) do
    GenServer.call(__MODULE__, {:get_event, event_id})
  end

  @doc "Get all events."
  def list_events do
    GenServer.call(__MODULE__, :list_events)
  end

  @doc "Get events for a specific entity."
  def get_entity_events(entity_id) do
    GenServer.call(__MODULE__, {:get_entity_events, entity_id})
  end

  @doc "Get events by type."
  def get_events_by_type(event_type) do
    GenServer.call(__MODULE__, {:get_events_by_type, event_type})
  end

  @doc "Get events within a time range."
  def get_events_in_time_range(start_time, end_time) do
    GenServer.call(__MODULE__, {:get_events_in_time_range, start_time, end_time})
  end

  @doc "Create a timeline epoch."
  def create_epoch(epoch_id, name, start_time, end_time \\ nil) do
    epoch = %{
      id: epoch_id,
      name: name,
      start_time: start_time,
      end_time: end_time,
      events: [],
      metadata: %{}
    }

    GenServer.call(__MODULE__, {:create_epoch, epoch})
  end

  @doc "Add event to epoch."
  def add_event_to_epoch(epoch_id, event_id) do
    GenServer.call(__MODULE__, {:add_event_to_epoch, epoch_id, event_id})
  end

  @doc "Get current timeline state."
  def get_current_state do
    GenServer.call(__MODULE__, :get_current_state)
  end

  @doc "Create a counterfactual branch."
  def create_counterfactual(branch_id, base_event_id, alternative_description) do
    counterfactual = %{
      id: branch_id,
      base_event_id: base_event_id,
      alternative_description: alternative_description,
      created_at: DateTime.utc_now(),
      events: [],
      probability: 0.5
    }

    GenServer.call(__MODULE__, {:create_counterfactual, counterfactual})
  end

  @doc "Add event to counterfactual branch."
  def add_event_to_counterfactual(branch_id, event) do
    GenServer.call(__MODULE__, {:add_event_to_counterfactual, branch_id, event})
  end

  @doc "Get timeline statistics."
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  @impl true
  def init(_opts) do
    Logger.info("Initializing Timeline Manager")

    # Initialize state with timeline structure
    state = %{
      events: %{},
      entity_index: %{},
      type_index: %{},
      time_index: %{},
      epochs: %{},
      current_state: %{},
      counterfactuals: %{},
      last_updated: DateTime.utc_now(),
      operation_count: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:add_event, event}, _from, state) do
    event_id = event.id

    # Check for existing event
    if Map.has_key?(state.events, event_id) do
      Logger.warning("Event with ID #{event_id} already exists")
      {:reply, {:error, :event_exists}, state}
    else
      # Add event to timeline
      updated_events = Map.put(state.events, event_id, event)
      
      # Update indexes
      updated_entity_index = update_entity_index(state.entity_index, event)
      updated_type_index = update_type_index(state.type_index, event)
      updated_time_index = update_time_index(state.time_index, event)
      
      # Update current state if event is current
      updated_current_state = if is_current_event?(event) do
        Map.put(state.current_state, event.entity_id, event)
      else
        state.current_state
      end
      
      new_state = %{state |
        events: updated_events,
        entity_index: updated_entity_index,
        type_index: updated_type_index,
        time_index: updated_time_index,
        current_state: updated_current_state,
        last_updated: DateTime.utc_now(),
        operation_count: state.operation_count + 1
      }

      Logger.info("Added timeline event: #{event_id} (type: #{event.type})")
      {:reply, {:ok, event_id}, new_state}
    end
  end

  @impl true
  def handle_call({:update_event_metadata, event_id, metadata}, _from, state) do
    case Map.get(state.events, event_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      event ->
        updated_event = %{event | metadata: Map.merge(event.metadata, metadata)}
        updated_events = Map.put(state.events, event_id, updated_event)
        
        new_state = %{state |
          events: updated_events,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Updated metadata for event: #{event_id}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:record_event_consequences, event_id, consequences}, _from, state) do
    case Map.get(state.events, event_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      event ->
        updated_event = %{event | consequences: consequences ++ event.consequences}
        updated_events = Map.put(state.events, event_id, updated_event)
        
        new_state = %{state |
          events: updated_events,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Recorded consequences for event: #{event_id}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:get_event, event_id}, _from, state) do
    case Map.get(state.events, event_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      event ->
        {:reply, {:ok, event}, state}
    end
  end

  @impl true
  def handle_call(:list_events, _from, state) do
    events = Map.values(state.events)
    {:reply, {:ok, events}, state}
  end

  @impl true
  def handle_call({:get_entity_events, entity_id}, _from, state) do
    event_ids = Map.get(state.entity_index, entity_id, [])
    events = Enum.map(event_ids, &Map.get(state.events, &1))
    
    # Sort by timestamp
    sorted_events = Enum.sort(events, &(&1.timestamp <= &2.timestamp))
    
    {:reply, {:ok, sorted_events}, state}
  end

  @impl true
  def handle_call({:get_events_by_type, event_type}, _from, state) do
    event_ids = Map.get(state.type_index, event_type, [])
    events = Enum.map(event_ids, &Map.get(state.events, &1))
    
    {:reply, {:ok, events}, state}
  end

  @impl true
  def handle_call({:get_events_in_time_range, start_time, end_time}, _from, state) do
    all_events = Map.values(state.events)
    
    in_range_events = Enum.filter(all_events, fn event ->
      event_time = event.timestamp
      event_time >= start_time and event_time <= end_time
    end)
    
    {:reply, {:ok, in_range_events}, state}
  end

  @impl true
  def handle_call({:create_epoch, epoch}, _from, state) do
    epoch_id = epoch.id

    if Map.has_key?(state.epochs, epoch_id) do
      Logger.warning("Epoch with ID #{epoch_id} already exists")
      {:reply, {:error, :epoch_exists}, state}
    else
      updated_epochs = Map.put(state.epochs, epoch_id, epoch)
      
      new_state = %{state |
        epochs: updated_epochs,
        last_updated: DateTime.utc_now(),
        operation_count: state.operation_count + 1
      }

      Logger.info("Created timeline epoch: #{epoch_id}")
      {:reply, {:ok, epoch_id}, new_state}
    end
  end

  @impl true
  def handle_call({:add_event_to_epoch, epoch_id, event_id}, _from, state) do
    case {Map.get(state.epochs, epoch_id), Map.get(state.events, event_id)} do
      {nil, _} ->
        {:reply, {:error, :epoch_not_found}, state}
      {_, nil} ->
        {:reply, {:error, :event_not_found}, state}
      {epoch, event} ->
        updated_epoch = %{epoch | events: [event_id | epoch.events]}
        updated_epochs = Map.put(state.epochs, epoch_id, updated_epoch)
        
        new_state = %{state |
          epochs: updated_epochs,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Added event #{event_id} to epoch #{epoch_id}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call(:get_current_state, _from, state) do
    {:reply, {:ok, state.current_state}, state}
  end

  @impl true
  def handle_call({:create_counterfactual, counterfactual}, _from, state) do
    branch_id = counterfactual.id

    if Map.has_key?(state.counterfactuals, branch_id) do
      Logger.warning("Counterfactual branch with ID #{branch_id} already exists")
      {:reply, {:error, :branch_exists}, state}
    else
      updated_counterfactuals = Map.put(state.counterfactuals, branch_id, counterfactual)
      
      new_state = %{state |
        counterfactuals: updated_counterfactuals,
        last_updated: DateTime.utc_now(),
        operation_count: state.operation_count + 1
      }

      Logger.info("Created counterfactual branch: #{branch_id}")
      {:reply, {:ok, branch_id}, new_state}
    end
  end

  @impl true
  def handle_call({:add_event_to_counterfactual, branch_id, event}, _from, state) do
    case Map.get(state.counterfactuals, branch_id) do
      nil ->
        {:reply, {:error, :branch_not_found}, state}
      counterfactual ->
        updated_counterfactual = %{counterfactual | 
          events: [event | counterfactual.events]
        }
        updated_counterfactuals = Map.put(state.counterfactuals, branch_id, updated_counterfactual)
        
        new_state = %{state |
          counterfactuals: updated_counterfactuals,
          last_updated: DateTime.utc_now(),
          operation_count: state.operation_count + 1
        }

        Logger.info("Added event to counterfactual branch #{branch_id}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_events: map_size(state.events),
      total_epochs: map_size(state.epochs),
      counterfactual_branches: map_size(state.counterfactuals),
      current_entities: map_size(state.current_state),
      time_span: calculate_time_span(state.events),
      last_updated: state.last_updated,
      operation_count: state.operation_count,
      event_distribution: get_event_distribution(state.type_index)
    }

    {:reply, {:ok, stats}, state}
  end

  # Private helper functions

  defp update_entity_index(entity_index, event) do
    event_ids = Map.get(entity_index, event.entity_id, [])
    updated_ids = [event.id | event_ids]
    Map.put(entity_index, event.entity_id, updated_ids)
  end

  defp update_type_index(type_index, event) do
    event_ids = Map.get(type_index, event.type, [])
    updated_ids = [event.id | event_ids]
    Map.put(type_index, event.type, updated_ids)
  end

  defp update_time_index(time_index, event) do
    # Group events by year-month
    time_key = format_time_key(event.timestamp)
    event_ids = Map.get(time_index, time_key, [])
    updated_ids = [event.id | event_ids]
    Map.put(time_index, time_key, updated_ids)
  end

  defp is_current_event?(event) do
    # Consider an event current if it happened within the last 24 hours
    time_diff = DateTime.diff(DateTime.utc_now(), event.timestamp)
    time_diff < 86400  # 24 hours in seconds
  end

  defp format_time_key(datetime) do
    "#{datetime.year}-#{String.pad_leading(to_string(datetime.month), 2, "0")}"
  end

  defp calculate_time_span(events) do
    all_events = Map.values(events)
    if Enum.empty?(all_events) do
      %{start: nil, end: nil, duration: 0}
    else
      timestamps = Enum.map(all_events, & &1.timestamp)
      %{start: Enum.min(timestamps), end: Enum.max(timestamps)}
    end
  end

  defp get_event_distribution(type_index) do
    type_index
    |> Enum.map(fn {type, events} -> {type, length(events)} end)
    |> Enum.into(%{})
  end
end