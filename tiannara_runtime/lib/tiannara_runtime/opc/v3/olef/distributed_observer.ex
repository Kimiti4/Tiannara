defmodule Tiannara.OPC.V3.OLEF.DistributedObserver do
  @moduledoc """
  Distributed Observer for Cognitive Physics Simulation
  Represents individual observers in the distributed pressure mesh
  """

  defstruct [
    :id,
    :position,
    :state,
    :capabilities,
    :pressure_sensitivity,
    :observation_history,
    :connected_observers
  ]

  @type t :: %__MODULE__{
    id: String.t(),
    position: {integer(), integer()},
    state: map(),
    capabilities: list(atom()),
    pressure_sensitivity: float(),
    observation_history: list(map()),
    connected_observers: list(String.t())
  }

  @doc """
  Creates a new distributed observer
  """
  def new(spec) when is_map(spec) or is_list(spec) do
    spec_map = if is_list(spec), do: Enum.into(spec, %{}), else: spec

    %__MODULE__{
      id: Map.get(spec_map, :id, generate_observer_id()),
      position: Map.get(spec_map, :position, {0, 0}),
      state: Map.get(spec_map, :state, %{}),
      capabilities: Map.get(spec_map, :capabilities, [:observe, :report]),
      pressure_sensitivity: Map.get(spec_map, :pressure_sensitivity, 1.0),
      observation_history: Map.get(spec_map, :observation_history, []),
      connected_observers: Map.get(spec_map, :connected_observers, [])
    }
  end

  def new(position, capabilities \\ [:observe, :report]) when is_tuple(position) do
    %__MODULE__{
      id: generate_observer_id(),
      position: position,
      state: %{},
      capabilities: capabilities,
      pressure_sensitivity: 1.0,
      observation_history: [],
      connected_observers: []
    }
  end

  @doc """
  Generates a unique observer ID
  """
  defp generate_observer_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  @doc """
  Makes an observation of the pressure field at the observer's position
  """
  def observe(%__MODULE__{} = observer, pressure_field) do
    current_pressure = Map.get(pressure_field, observer.position, 0.0)
    
    # Apply sensitivity factor
    perceived_pressure = current_pressure * observer.pressure_sensitivity
    
    observation = %{
      timestamp: System.os_time(:millisecond),
      position: observer.position,
      pressure: perceived_pressure,
      raw_pressure: current_pressure,
      observer_id: observer.id
    }
    
    updated_history = [observation | Enum.take(observer.observation_history, 99)]  # Keep last 100 observations
    
    %{
      observer |
      state: Map.put(observer.state, :last_observation, observation),
      observation_history: updated_history
    }
  end

  @doc """
  Reports current state and observations
  """
  def report(%__MODULE__{} = observer) do
    %{
      id: observer.id,
      position: observer.position,
      capabilities: observer.capabilities,
      pressure_sensitivity: observer.pressure_sensitivity,
      last_observation: Map.get(observer.state, :last_observation),
      observation_count: length(observer.observation_history),
      connected_count: length(observer.connected_observers)
    }
  end

  @doc """
  Updates observer state based on external input
  """
  def update_state(%__MODULE__{} = observer, new_state_updates) when is_map(new_state_updates) do
    updated_state = Map.merge(observer.state, new_state_updates)
    %{observer | state: updated_state}
  end

  @doc """
  Connects observer to another observer
  """
  def connect_to(%__MODULE__{} = observer, other_observer_id) when is_binary(other_observer_id) do
    if other_observer_id in observer.connected_observers do
      observer  # Already connected
    else
      updated_connections = [other_observer_id | observer.connected_observers]
      %{observer | connected_observers: updated_connections}
    end
  end

  @doc """
  Disconnects from another observer
  """
  def disconnect_from(%__MODULE__{} = observer, other_observer_id) when is_binary(other_observer_id) do
    updated_connections = Enum.reject(observer.connected_observers, &(&1 == other_observer_id))
    %{observer | connected_observers: updated_connections}
  end

  @doc """
  Processes an incoming pressure wave from another observer
  """
  def receive_pressure_wave(%__MODULE__{} = observer, source_observer_id, pressure_value, propagation_delay) do
    # Calculate received pressure accounting for propagation delay and sensitivity
    delayed_pressure = pressure_value * observer.pressure_sensitivity * (1.0 - min(propagation_delay, 1.0))
    
    updated_state = Map.put(observer.state, :received_pressure, delayed_pressure)
    
    observation = %{
      timestamp: System.os_time(:millisecond),
      source_observer: source_observer_id,
      received_pressure: delayed_pressure,
      propagation_delay: propagation_delay,
      observer_id: observer.id
    }
    
    updated_history = [observation | Enum.take(observer.observation_history, 99)]
    
    %{
      observer |
      state: updated_state,
      observation_history: updated_history
    }
  end

  @doc """
  Checks if observer has specific capability
  """
  def has_capability?(%__MODULE__{} = observer, capability) when is_atom(capability) do
    capability in observer.capabilities
  end

  @doc """
  Gets recent observations within a time window
  """
  def get_recent_observations(%__MODULE__{} = observer, time_window_ms \\ 5000) do
    cutoff_time = System.os_time(:millisecond) - time_window_ms
    
    Enum.filter(observer.observation_history, fn obs ->
      obs.timestamp >= cutoff_time
    end)
  end

  @doc """
  Resets observer state while preserving identity and configuration
  """
  def reset(%__MODULE__{} = observer) do
    %{observer |
      state: %{},
      observation_history: []
    }
  end
end
