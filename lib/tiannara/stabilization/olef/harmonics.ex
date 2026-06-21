defmodule Tiannara.Stabilization.OLEF.Harmonics do
  @moduledoc """
  Manages load harmonics in the OLEF system.

  Controls harmonic oscillations to balance load distribution across the field.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def inject_harmonics(params) do
    GenServer.call(__MODULE__, {:inject_harmonics, params})
  end

  def get_harmonic_state() do
    GenServer.call(__MODULE__, :get_harmonic_state)
  end

  def calculate_harmonic_pressure(region, base_pressure, time \\ nil) do
    GenServer.call(__MODULE__, {:calculate_harmonic_pressure, region, base_pressure, time})
  end

  def optimize_harmonics(load_distribution) do
    GenServer.call(__MODULE__, {:optimize_harmonics, load_distribution})
  end

  def get_harmonic_history() do
    GenServer.call(__MODULE__, :get_harmonic_history)
  end

  def reset_harmonics() do
    GenServer.call(__MODULE__, :reset_harmonics)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for harmonics
    :ets.new(:harmonic_params, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:harmonic_history, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:harmonic_optimization, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Set default harmonic parameters
    default_params = %{
      frequency: 1.0,          # Hz
      amplitude: 0.2,          # 20% pressure variation
      phase: 0.0,             # Radians
      damping: 0.95,          # Damping coefficient
      coupling_strength: 0.1   # Inter-region coupling
    }

    :ets.insert(:harmonic_params, {:defaults, default_params})

    Logger.info("Harmonics controller initialized")
    
    {:ok, %{
      harmonic_count: 0,
      last_optimization: 0,
      optimization_count: 0,
      field_coupling_active: false
    }}
  end

  @impl true
  def handle_call({:inject_harmonics, params}, _from, state) do
    # Validate and normalize harmonic parameters
    validated = validate_harmonic_params(params)
    
    # Store harmonic parameters
    timestamp = System.system_time(:millisecond)
    :ets.insert(:harmonic_params, {timestamp, validated})
    
    # Record in history
    :ets.insert(:harmonic_history, {timestamp, validated})
    
    Logger.info("Injected harmonics with frequency #{validated.frequency} Hz, amplitude #{validated.amplitude}")
    
    {:reply, {:ok, validated}, %{state | 
      harmonic_count: state.harmonic_count + 1,
      last_optimization: timestamp
    }}
  end

  @impl true
  def handle_call(:get_harmonic_state, _from, state) do
    current_params = get_current_harmonic_params()
    
    reply = %{
      current_params: current_params,
      harmonic_count: state.harmonic_count,
      field_coupling_active: state.field_coupling_active,
      last_optimization: state.last_optimization
    }
    
    {:reply, {:ok, reply}, state}
  end

  @impl true
  def handle_call({:calculate_harmonic_pressure, region, base_pressure, time}, _from, state) do
    current_params = get_current_harmonic_params()
    effective_time = time || System.system_time(:millisecond) / 1000.0  # Convert to seconds
    
    # Calculate harmonic component
    harmonic_component = calculate_harmonic_component(
      region, 
      current_params, 
      effective_time,
      base_pressure
    )
    
    # Apply coupling if active
    total_pressure = 
      if state.field_coupling_active do
        coupling_component = calculate_coupling_component(region, effective_time)
        base_pressure + harmonic_component + coupling_component
      else
        base_pressure + harmonic_component
      end
    
    {:reply, {:ok, total_pressure}, state}
  end

  @impl true
  def handle_call({:optimize_harmonics, load_distribution}, _from, state) do
    # Analyze load distribution and optimize harmonic parameters
    optimized = optimize_harmonic_parameters(load_distribution)
    
    # Store optimization results
    timestamp = System.system_time(:millisecond)
    :ets.insert(:harmonic_optimization, {timestamp, optimized})
    
    # Apply optimized parameters
    :ets.insert(:harmonic_params, {timestamp, optimized})
    
    Logger.info("Optimized harmonics for #{map_size(load_distribution)} regions")
    
    {:reply, {:ok, optimized}, %{state | 
      optimization_count: state.optimization_count + 1,
      last_optimization: timestamp
    }}
  end

  @impl true
  def handle_call(:get_harmonic_history, _from, state) do
    history = :ets.tab2list(:harmonic_history)
    |> Enum.map(fn {timestamp, params} -> 
      %{timestamp: timestamp, params: params}
    end)
    |> Enum.sort_by(& &1.timestamp)
    
    {:reply, {:ok, history}, state}
  end

  @impl true
  def handle_call(:reset_harmonics, _from, state) do
    # Clear all harmonic parameters and history
    :ets.delete_all_objects(:harmonic_params)
    :ets.delete_all_objects(:harmonic_history)
    :ets.delete_all_objects(:harmonic_optimization)
    
    # Restore defaults
    default_params = %{
      frequency: 1.0,
      amplitude: 0.2,
      phase: 0.0,
      damping: 0.95,
      coupling_strength: 0.1
    }
    
    :ets.insert(:harmonic_params, {System.system_time(:millisecond), default_params})
    
    Logger.info("Reset harmonics to default parameters")
    
    {:reply, :ok, %{state | 
      harmonic_count: 0,
      optimization_count: 0,
      field_coupling_active: false
    }}
  end

  # Helper functions
  defp validate_harmonic_params(params) when is_map(params) do
    %{
      frequency: max(min(Map.get(params, :frequency, 1.0), 10.0), 0.1),  # 0.1-10 Hz
      amplitude: max(min(Map.get(params, :amplitude, 0.2), 1.0), 0.0),    # 0-100%
      phase: Map.get(params, :phase, 0.0),                                # 0-2π
      damping: max(min(Map.get(params, :damping, 0.95), 1.0), 0.8),      # 0.8-1.0
      coupling_strength: max(min(Map.get(params, :coupling_strength, 0.1), 0.5), 0.0)  # 0-50%
    }
  end

  defp validate_harmonic_params(_), do: default_harmonic_params()

  defp default_harmonic_params() do
    %{
      frequency: 1.0,
      amplitude: 0.2,
      phase: 0.0,
      damping: 0.95,
      coupling_strength: 0.1
    }
  end

  defp get_current_harmonic_params() do
    case :ets.last(:harmonic_params) do
      :"$end_of_table" -> default_harmonic_params()
      timestamp ->
        case :ets.lookup(:harmonic_params, timestamp) do
          [{^timestamp, params}] -> params
          [] -> default_harmonic_params()
        end
    end
  end

  defp calculate_harmonic_component(region, params, time, base_pressure) do
    # Region-specific frequency modifier (creates spatial variation)
    region_freq_modifier = case region do
      "region_" <> id -> 
        # Simple frequency variation based on region ID
        base_freq = String.to_integer(id)
        1.0 + 0.1 * :math.sin(base_freq * 0.1)
      _ -> 1.0
    end
    
    effective_frequency = params.frequency * region_freq_modifier
    
    # Calculate harmonic oscillation
    harmonic = params.amplitude * base_pressure * 
              :math.sin(2 * :math.pi() * effective_frequency * time + params.phase)
    
    # Apply damping
    damped_harmonic = harmonic * params.damping
    
    damped_harmonic
  end

  defp calculate_coupling_component(region, time) do
    # Simplified coupling calculation
    # In production, this would use proper field coupling equations
    
    coupling_strength = 0.05  # Default coupling strength
    
    # Calculate phase coupling with neighboring regions
    phase_coupling = :math.sin(time * 0.5) * coupling_strength
    
    # Spatial coupling based on region
    spatial_coupling = case region do
      "region_" <> id -> 
        base_id = String.to_integer(id)
        :math.sin(base_id * 0.1) * coupling_strength
      _ -> 0.0
    end
    
    phase_coupling + spatial_coupling
  end

  defp optimize_harmonic_parameters(load_distribution) do
    # Analyze load distribution and determine optimal harmonic parameters
    
    load_values = Map.values(load_distribution)
    
    # Calculate load statistics
    load_mean = Enum.sum(load_values) / max(length(load_values), 1)
    load_std = calculate_standard_deviation(load_values)
    load_variance = :math.pow(load_std, 2)
    
    # Determine optimal amplitude based on variance
    # Higher variance requires higher amplitude for better balancing
    optimal_amplitude = min(0.5, 0.1 + load_variance * 2.0)
    
    # Determine optimal frequency based on load dynamics
    # Higher standard deviation suggests faster dynamics
    optimal_frequency = min(5.0, 1.0 + load_std)
    
    # Optimize coupling strength
    optimal_coupling = min(0.3, 0.1 + load_variance)
    
    %{
      frequency: optimal_frequency,
      amplitude: optimal_amplitude,
      phase: 0.0,
      damping: 0.95,
      coupling_strength: optimal_coupling,
      load_stats: %{
        mean: load_mean,
        std: load_std,
        variance: load_variance
      }
    }
  end

  defp calculate_standard_deviation(values) do
    if length(values) > 1 do
      mean = Enum.sum(values) / length(values)
      sum_sq = Enum.map(values, fn x -> :math.pow(x - mean, 2) end) |> Enum.sum()
      variance = sum_sq / length(values)
      :math.sqrt(variance)
    else
      0.0
    end
  end
end
