defmodule Tiannara.Stabilization.HSV do
  @moduledoc """
  Holographic Singularity Vent (HSV).

  Archives runaway ontology density into compressed topological artifacts,
  preventing VRAM overflow, catastrophic memory collapse, and runtime exhaustion.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def archive_singularity(region, density_data) do
    GenServer.call(__MODULE__, {:archive_singularity, region, density_data})
  end

  def archive_singularity(region) when is_map(region) do
    # Default density calculation if not provided
    density_data = calculate_default_density(region)
    GenServer.call(__MODULE__, {:archive_singularity, region, density_data})
  end

  def spawn_event_horizon(region, threshold \\ 0.8) do
    GenServer.call(__MODULE__, {:spawn_event_horizon, region, threshold})
  end

  def cold_storage_offload(ontology_id) do
    GenServer.call(__MODULE__, {:cold_storage_offload, ontology_id})
  end

  def get_singularity_status(region) do
    GenServer.call(__MODULE__, {:get_singularity_status, region})
  end

  def get_archive_stats() do
    GenServer.call(__MODULE__, :get_archive_stats)
  end

  def decompress_archive(archive_id) do
    GenServer.call(__MODULE__, {:decompress_archive, archive_id})
  end

  def monitor_density_levels() do
    GenServer.call(__MODULE__, :monitor_density_levels)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for singularity management
    :ets.new(:singularity_regions, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:event_horizons, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:archives, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:cold_storage, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    # Initialize configuration
    config = %{
      spawn_threshold: 0.8,
      critical_threshold: 0.95,
      archive_compression_ratio: 0.1,
      max_archive_size: 100_000,
      monitoring_interval: 1000,  # 1 second
      conservation_laws: [
        :causal_closure,
        :semantic_invertibility,
        :information_conservation
      ]
    }

    Logger.info("HSV initialized with singularity venting parameters")
    
    {:ok, %{
      config: config,
      active_singularities: 0,
      total_archives: 0,
      total_compressed: 0,
      last_monitoring: System.system_time(:millisecond),
      density_alerts: 0
    }}
  end

  @impl true
  def handle_call({:archive_singularity, region, density_data}, _from, state) do
    # Validate density data
    validated = validate_density_data(density_data)
    
    # Check if singularity should be spawned
    case should_spawn_singularity(validated, state.config.spawn_threshold) do
      true ->
        # Archive the singularity
        archive_result = archive_singularity_region(region, validated, state.config)
        
        Logger.warning("Archive singularity for region #{region}: #{inspect(validated)}")
        
        {:reply, {:ok, archive_result}, update_archive_stats(state, archive_result)}

      false ->
        # No singularity threshold reached, store normally
        Logger.debug("Region #{region} density below singularity threshold")
        {:reply, {:ok, :no_singularity}, state}
    end
  end

  @impl true
  def handle_call({:spawn_event_horizon, region, threshold}, _from, state) do
    case :ets.lookup(:singularity_regions, region) do
      [{^region, density_data}] ->
        if density_data.overall_density > threshold do
          # Spawn event horizon
          horizon_id = generate_horizon_id()
          horizon_data = create_event_horizon(region, density_data, threshold)
          
          :ets.insert(:event_horizons, {horizon_id, horizon_data})
          
          # Update region with horizon information
          updated_region = Map.put(density_data, :event_horizon, horizon_id)
          :ets.insert(:singularity_regions, {region, updated_region})
          
          Logger.info("Spawned event horizon #{horizon_id} for region #{region}")
          
          {:reply, {:ok, horizon_id}, state}
        else
          {:reply, {:error, :below_threshold}, state}
        end

      [] ->
        {:reply, {:error, :region_not_found}, state}
    end
  end

  @impl true
  def handle_call({:cold_storage_offload, ontology_id}, _from, state) do
    # Check if ontology is eligible for cold storage
    case :ets.lookup(:singularity_regions, ontology_id) do
      [{^ontology_id, density_data}] ->
        if density_data.inactive_time > 300_000 or  # 5 minutes inactive
           density_data.access_frequency < 0.1 do   # Low access frequency
          
          # Move to cold storage
          archive_result = offload_to_cold_storage(ontology_id, density_data)
          
          Logger.info("Offloaded ontology #{ontology_id} to cold storage")
          
          {:reply, {:ok, archive_result}, update_archive_stats(state, archive_result)}
        else
          {:reply, {:error, :not_eligible}, state}
        end

      [] ->
        {:reply, {:error, :ontology_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_singularity_status, region}, _from, state) do
    case :ets.lookup(:singularity_regions, region) do
      [{^region, density_data}] ->
        status = %{
          region: region,
          overall_density: density_data.overall_density,
          concept_density: density_data.concept_density,
          causal_density: density_data.causal_density,
          timestamp: density_data.timestamp,
          event_horizon: density_data.event_horizon,
          archived: density_data.archived
        }
        
        {:reply, {:ok, status}, state}

      [] ->
        {:reply, {:error, :region_not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_archive_stats, _from, state) do
    stats = %{
      active_singularities: state.active_singularities,
      total_archives: state.total_archives,
      total_compressed: state.total_compressed,
      archive_count: :ets.info(:archives, :size),
      cold_storage_count: :ets.info(:cold_storage, :size),
      event_horizon_count: :ets.info(:event_horizons, :size),
      density_alerts: state.density_alerts
    }
    
    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_call({:decompress_archive, archive_id}, _from, state) do
    case :ets.lookup(:archives, archive_id) do
      [{^archive_id, archive_data}] ->
        # Verify conservation laws before decompression
        case verify_conservation_laws(archive_data) do
          :ok ->
            # Decompress archive
            decompressed = decompress_archive_data(archive_data)
            
            # Restore original region data
            :ets.insert(:singularity_regions, {archive_data.original_region, decompressed})
            
            # Remove from archives
            :ets.delete(:archives, archive_id)
            
            Logger.info("Decompressed archive #{archive_id} for region #{archive_data.original_region}")
            
            {:reply, {:ok, decompressed}, state}
            
          {:error, reason} ->
            Logger.error("Decompression failed: #{reason}")
            {:reply, {:error, reason}, state}
        end

      [] ->
        {:reply, {:error, :archive_not_found}, state}
    end
  end

  @impl true
  def handle_call(:monitor_density_levels, _from, state) do
    current_time = System.system_time(:millisecond)
    
    # Check all regions for critical density levels
    regions = :ets.tab2list(:singularity_regions)
    
    alerts = Enum.reduce(regions, [], fn {region, density_data}, alerts ->
      if density_data.overall_density > state.config.critical_threshold do
        Logger.warning("CRITICAL: Region #{region} density #{density_data.overall_density} exceeds threshold #{state.config.critical_threshold}")
        [{region, density_data.overall_density} | alerts]
      else
        alerts
      end
    end)
    
    if length(alerts) > 0 do
      {:reply, {:warning, alerts}, %{state | 
        density_alerts: state.density_alerts + length(alerts),
        last_monitoring: current_time
      }}
    else
      Logger.debug("All density levels within normal range")
      {:reply, :ok, %{state | last_monitoring: current_time}}
    end
  end

  # Helper functions
  defp calculate_default_density(region) when is_map(region) do
    # Calculate default density based on region properties
    base_density = 0.5
    
    # Adjust based on region size
    size_factor = case Map.get(region, :size, :medium) do
      :small -> 0.7
      :medium -> 1.0
      :large -> 1.3
    end
    
    # Adjust based on complexity
    complexity = Map.get(region, :complexity, 1.0)
    complexity_factor = min(complexity / 10.0, 2.0)
    
    # Adjust based on age
    age = System.system_time(:millisecond) - Map.get(region, :created_at, System.system_time(:millisecond))
    age_factor = min(age / 1000000.0, 1.5)  # Normalize to millions of milliseconds
    
    final_density = base_density * size_factor * complexity_factor * age_factor
    min(final_density, 1.0)  # Cap at 1.0
  end

  defp validate_density_data(density_data) when is_map(density_data) do
    %{
      overall_density: min(max(Map.get(density_data, :overall_density, 0.0), 0.0), 1.0),
      concept_density: min(max(Map.get(density_data, :concept_density, 0.0), 0.0), 1.0),
      causal_density: min(max(Map.get(density_data, :causal_density, 0.0), 0.0), 1.0),
      timestamp: System.system_time(:millisecond),
      inactive_time: Map.get(density_data, :inactive_time, 0),
      access_frequency: min(max(Map.get(density_data, :access_frequency, 0.0), 0.0), 1.0),
      archived: Map.get(density_data, :archived, false)
    }
  end

  defp validate_density_data(_), do: %{}

  defp should_spawn_singularity(density_data, threshold) do
    density_data.overall_density >= threshold
  end

  defp archive_singularity_region(region, density_data, config) do
    # Create archive ID
    archive_id = generate_archive_id()
    
    # Compress the data
    compressed_data = compress_archived_data(density_data, config)
    
    # Create archive record
    archive = %{
      id: archive_id,
      original_region: region,
      original_density: density_data.overall_density,
      compressed_data: compressed_data,
      archived_at: System.system_time(:millisecond),
      compression_ratio: calculate_compression_ratio(density_data, compressed_data),
      conservation_laws: config.conservation_laws
    }
    
    # Store archive
    :ets.insert(:archives, {archive_id, archive})
    
    # Update region as archived
    archived_region = Map.put(density_data, :archived, true)
    :ets.insert(:singularity_regions, {region, archived_region})
    
    archive
  end

  defp generate_archive_id() do
    "arch_#{System.system_time(:millisecond)}_#{:crypto.strong_rand_bytes(8) |> Base.url_encode64()}"
  end

  defp generate_horizon_id() do
    "horizon_#{System.system_time(:millisecond)}_#{:crypto.strong_rand_bytes(8) |> Base.url_encode64()}"
  end

  defp create_event_horizon(region, density_data, threshold) do
    %{
      id: generate_horizon_id(),
      region: region,
      spawn_threshold: threshold,
      original_density: density_data.overall_density,
      created_at: System.system_time(:millisecond),
      causal_isolation_active: false,
      compression_active: false,
      preservation_fidelity: 0.95
    }
  end

  defp compress_archived_data(density_data, _config) do
    # Simplified compression - in production, use proper compression algorithms
    compressed = %{
      density: density_data.overall_density,
      concepts: :erlang.term_to_binary(density_data.concept_density),
      causal: :erlang.term_to_binary(density_data.causal_density),
      metadata: %{
        compressed_at: System.system_time(:millisecond),
        conservation_check: verify_data_integrity(density_data)
      }
    }
    
    compressed
  end

  defp calculate_compression_ratio(original, compressed) do
    original_size = byte_size(:erlang.term_to_binary(original))
    compressed_size = byte_size(:erlang.term_to_binary(compressed))
    
    if original_size > 0 do
      compressed_size / original_size
    else
      1.0
    end
  end

  defp offload_to_cold_storage(ontology_id, density_data) do
    # Create cold storage entry
    cold_id = "cold_#{System.system_time(:millisecond)}_#{ontology_id}"
    
    cold_entry = %{
      id: cold_id,
      ontology_id: ontology_id,
      data: density_data,
      offloaded_at: System.system_time(:millisecond),
      access_count: 0,
      last_access: 0,
      retrieval_priority: calculate_retrieval_priority(density_data)
    }
    
    :ets.insert(:cold_storage, {cold_id, cold_entry})
    
    # Remove from main regions
    :ets.delete(:singularity_regions, ontology_id)
    
    cold_entry
  end

  defp calculate_retrieval_priority(density_data) do
    # Priority based on access frequency and recency
    recency_factor = if density_data.inactive_time > 0 do
      1.0 / (1.0 + density_data.inactive_time / 60_000)  # Recent access higher priority
    else
      1.0
    end
    
    access_factor = density_data.access_frequency
    
    recency_factor * access_factor
  end

  defp verify_conservation_laws(archive_data) do
    # Check if archived data preserves conservation laws
    conservation_check = archive_data.compressed_data.metadata.conservation_check
    
    case conservation_check do
      %{valid: true} -> :ok
      %{valid: false, reason: reason} -> {:error, reason}
      _ -> {:error, :unknown_conservation_status}
    end
  end

  defp verify_data_integrity(data) do
    # Simplified integrity check - in production, use proper checksums
    %{
      valid: true,  # Assume valid for now
      checksum: :crypto.hash(:sha256, :erlang.term_to_binary(data)) |> Base.encode64(),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp decompress_archive_data(archive_data) do
    # Decompress archived data
    %{
      overall_density: archive_data.compressed_data.density,
      concept_density: :erlang.binary_to_term(archive_data.compressed_data.concepts),
      causal_density: :erlang.binary_to_term(archive_data.compressed_data.causal),
      timestamp: System.system_time(:millisecond),
      inactive_time: 0,
      access_frequency: 1.0,
      archived: false,
      event_horizon: nil
    }
  end

  defp update_archive_stats(state, archive_result) do
    %{state | 
      total_archives: state.total_archives + 1,
      total_compressed: state.total_compressed + archive_result.compression_ratio,
      active_singularities: max(0, state.active_singularities - 1)
    }
  end
end
