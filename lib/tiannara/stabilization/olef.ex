defmodule Tiannara.Stabilization.OLEF do
  @moduledoc """
  Ontological Load Entropy Field (OLEF).

  Diffuses computational pressure through ontology space to prevent localized compute overload,
  ontology hotspots, and entropy singularities.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def diffuse_pressure(ontology_id, pressure_points) do
    GenServer.call(__MODULE__, {:diffuse_pressure, ontology_id, pressure_points})
  end

  def redistribute_entropy(entropy_distribution) do
    GenServer.call(__MODULE__, {:redistribute_entropy, entropy_distribution})
  end

  def equalize_load(load_map) do
    GenServer.call(__MODULE__, {:equalize_load, load_map})
  end

  def get_field_state() do
    GenServer.call(__MODULE__, :get_field_state)
  end

  def get_pressure_map(ontology_id) do
    GenServer.call(__MODULE__, {:get_pressure_map, ontology_id})
  end

  def inject_harmonics(harmonics_params) do
    GenServer.call(__MODULE__, {:inject_harmonics, harmonics_params})
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for field management
    :ets.new(:pressure_fields, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:entropy_distribution, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:load_harmonics, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Initialize field parameters
    field_params = %{
      diffusion_rate: 0.85,
      equilibrium_threshold: 0.1,
      max_pressure: 100.0,
      redistribution_interval: 1000,
      harmonics_amplitude: 0.2
    }

    Logger.info("OLEF initialized with diffusion parameters")

    {:ok, %{
      field_params: field_params,
      global_entropy: 0.0,
      field_state: :active,
      last_redistribution: System.system_time(:millisecond),
      pressure_diffusions: 0,
      entropy_rebalances: 0
    }}
  end

  @impl true
  def handle_call({:diffuse_pressure, ontology_id, pressure_points}, _from, state) do
    # Validate pressure points
    validated_points = validate_pressure_points(pressure_points)
    
    # Get current field state
    case :ets.lookup(:pressure_fields, ontology_id) do
      [{^ontology_id, current_field}] ->
        # Apply diffusion algorithm
        diffused_field = apply_diffusion(current_field, validated_points, state.field_params)
        
        # Store updated field
        :ets.insert(:pressure_fields, {ontology_id, diffused_field})
        
        Logger.debug("Diffused pressure for ontology #{ontology_id}")
        
        {:reply, {:ok, diffused_field}, update_diffusion_stats(state)}

      [] ->
        # Create new field
        diffused_field = apply_diffusion(%{}, validated_points, state.field_params)
        :ets.insert(:pressure_fields, {ontology_id, diffused_field})
        
        Logger.info("Created pressure field for ontology #{ontology_id}")
        
        {:reply, {:ok, diffused_field}, update_diffusion_stats(state)}
    end
  end

  @impl true
  def handle_call({:redistribute_entropy, entropy_distribution}, _from, state) do
    # Validate and normalize entropy distribution
    normalized = normalize_entropy_distribution(entropy_distribution)
    
    # Apply redistribution
    redistributed = redistribute_entropy_field(normalized, state.field_params)
    
    # Store new distribution
    :ets.insert(:entropy_distribution, {System.system_time(:millisecond), redistributed})
    
    # Update global entropy
    global_entropy = calculate_global_entropy(redistributed)
    
    Logger.debug("Redistributed entropy: #{global_entropy}")
    
    {:reply, {:ok, redistributed}, %{state | 
      global_entropy: global_entropy,
      entropy_rebalances: state.entropy_rebalances + 1
    }}
  end

  @impl true
  def handle_call({:equalize_load, load_map}, _from, state) do
    # Convert load map to pressure field
    pressure_field = convert_load_to_pressure(load_map)
    
    # Apply load equalization
    equalized = equalize_pressure_field(pressure_field, state.field_params)
    
    # Store equalized field
    equalized_id = "equalized_#{System.system_time(:millisecond)}"
    :ets.insert(:pressure_fields, {equalized_id, equalized})
    
    Logger.info("Equalized load for #{map_size(load_map)} regions")
    
    {:reply, {:ok, equalized}, state}
  end

  @impl true
  def handle_call(:get_field_state, _from, state) do
    field_stats = calculate_field_statistics()
    
    reply = %{
      state: state.field_state,
      global_entropy: state.global_entropy,
      field_stats: field_stats,
      last_redistribution: state.last_redistribution
    }
    
    {:reply, {:ok, reply}, state}
  end

  @impl true
  def handle_call({:get_pressure_map, ontology_id}, _from, state) do
    case :ets.lookup(:pressure_fields, ontology_id) do
      [{^ontology_id, pressure_map}] ->
        {:reply, {:ok, pressure_map}, state}
      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:inject_harmonics, harmonics_params}, _from, state) do
    # Validate harmonics parameters
    validated = validate_harmonics_params(harmonics_params)
    
    # Apply harmonics to all pressure fields
    harmonics_applied = apply_field_harmonics(validated, state.field_params)
    
    # Store harmonics parameters
    :ets.insert(:load_harmonics, {System.system_time(:millisecond), validated})
    
    Logger.debug("Injected harmonics with amplitude #{validated.amplitude}")
    
    {:reply, {:ok, harmonics_applied}, state}
  end

  # Helper functions
  defp validate_pressure_points(pressure_points) when is_map(pressure_points) do
    validated = Enum.reduce(pressure_points, %{}, fn {region, pressure}, acc ->
      normalized_pressure = min(max(pressure, 0.0), 100.0)
      Map.put(acc, region, normalized_pressure)
    end)
    validated
  end

  defp validate_pressure_points(_), do: %{}

  defp apply_diffusion(current_field, pressure_points, params) do
    # Apply diffusion algorithm: new_pressure = current * diffusion_rate + injected * (1 - diffusion_rate)
    Enum.reduce(pressure_points, current_field, fn {region, pressure}, field ->
      current_pressure = Map.get(field, region, 0.0)
      new_pressure = current_pressure * params.diffusion_rate + pressure * (1 - params.diffusion_rate)
      Map.put(field, region, min(new_pressure, params.max_pressure))
    end)
  end

  defp normalize_entropy_distribution(entropy_distribution) when is_map(entropy_distribution) do
    total_entropy = Map.values(entropy_distribution) |> Enum.sum()
    if total_entropy > 0 do
      Enum.map(entropy_distribution, fn {region, entropy} ->
        {region, entropy / total_entropy}
      end) |> Map.new()
    else
      entropy_distribution
    end
  end

  defp normalize_entropy_distribution(_), do: %{}

  defp redistribute_entropy_field(entropy_distribution, params) do
    # Redistribute entropy using Fourier-like transform
    regions = Map.keys(entropy_distribution)
    
    # Calculate entropy gradients
    gradients = calculate_entropy_gradients(entropy_distribution)
    
    # Apply smoothing
    smoothed = Enum.reduce(regions, %{}, fn region, acc ->
      current_entropy = Map.get(entropy_distribution, region, 0.0)
      gradient = Map.get(gradients, region, 0.0)
      
      # Apply smoothing with diffusion
      new_entropy = current_entropy + gradient * params.diffusion_rate
      Map.put(acc, region, max(0.0, new_entropy))
    end)
    
    # Renormalize
    normalize_entropy_distribution(smoothed)
  end

  defp calculate_entropy_gradients(entropy_distribution) do
    # Simplified gradient calculation
    regions = Map.keys(entropy_distribution)
    
    Enum.reduce(regions, %{}, fn region, gradients ->
      # Calculate gradient as difference from neighbors
      neighbors = find_neighbor_regions(region)
      neighbor_values = neighbors |> Enum.map(fn n -> Map.get(entropy_distribution, n, 0.0) end)
      avg_neighbor = Enum.sum(neighbor_values) / max(length(neighbor_values), 1)
      
      current_value = Map.get(entropy_distribution, region, 0.0)
      gradient = avg_neighbor - current_value
      
      Map.put(gradients, region, gradient)
    end)
  end

  defp find_neighbor_regions(region) do
    # Simplified neighbor finding - in production, use proper topology
    case region do
      "region_" <> id -> 
        # Generate neighboring regions based on ID
        base_id = String.to_integer(id)
        [
          "region_#{base_id - 1}",
          "region_#{base_id + 1}",
          "region_#{base_id - 10}",
          "region_#{base_id + 10}"
        ]
      _ -> []
    end
  end

  defp convert_load_to_pressure(load_map) when is_map(load_map) do
    # Convert computational load to pressure values
    Enum.map(load_map, fn {region, load} ->
      # Normalize load to pressure scale (0-100)
      pressure = min(load * 10, 100.0)  # Scale factor of 10
      {region, pressure}
    end) |> Map.new()
  end

  defp convert_load_to_pressure(_), do: %{}

  defp equalize_pressure_field(pressure_field, params) do
    # Apply load equalization algorithm
    avg_pressure = Enum.sum(Map.values(pressure_field)) / max(map_size(pressure_field), 1)
    
    Enum.map(pressure_field, fn {region, pressure} ->
      # Move pressure towards average
      equalized = pressure + (avg_pressure - pressure) * params.diffusion_rate
      {region, min(max(equalized, 0.0), params.max_pressure)}
    end) |> Map.new()
  end

  defp calculate_global_entropy(entropy_distribution) do
    if map_size(entropy_distribution) > 0 do
      # Calculate Shannon entropy
      probabilities = Map.values(entropy_distribution)
      -Enum.sum(probabilities * Enum.map(probabilities, &:math.log/1))
    else
      0.0
    end
  end

  defp calculate_field_statistics() do
    pressure_fields = :ets.tab2list(:pressure_fields)
    total_regions = Enum.map(pressure_fields, fn {_, field} -> map_size(field) end) |> Enum.sum()
    avg_pressure = if total_regions > 0 do
      total_pressure = Enum.map(pressure_fields, fn {_, field} -> Enum.sum(Map.values(field)) end) |> Enum.sum()
      total_pressure / total_regions
    else
      0.0
    end

    %{
      total_regions: total_regions,
      average_pressure: avg_pressure,
      field_count: length(pressure_fields)
    }
  end

  defp validate_harmonics_params(params) when is_map(params) do
    %{
      frequency: Map.get(params, :frequency, 1.0),
      amplitude: min(max(Map.get(params, :amplitude, 0.2), 0.0), 1.0),
      phase: Map.get(params, :phase, 0.0)
    }
  end

  defp validate_harmonics_params(_), do: %{frequency: 1.0, amplitude: 0.2, phase: 0.0}

  defp apply_field_harmonics(harmonics, params) do
    # Apply harmonic oscillation to all pressure fields
    current_time = System.system_time(:millisecond) / 1000.0  # Convert to seconds
    
    :ets.tab2list(:pressure_fields)
    |> Enum.map(fn {ontology_id, field} ->
      # Apply harmonic modulation
      modulated_field = Enum.map(field, fn {region, pressure} ->
        harmonic = harmonics.amplitude * :math.sin(2 * :math.pi() * harmonics.frequency * current_time + harmonics.phase)
        modulated_pressure = pressure * (1.0 + harmonic)
        {region, max(0.0, modulated_pressure)}
      end) |> Map.new()
      
      {ontology_id, modulated_field}
    end)
  end

  defp update_diffusion_stats(%{pressure_diffusions: count} = state) do
    %{state | pressure_diffusions: count + 1}
  end
end
