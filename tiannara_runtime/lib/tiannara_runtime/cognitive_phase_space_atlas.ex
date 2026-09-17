defmodule TiannaraRuntime.CognitivePhaseSpaceAtlas do
  @moduledoc """
  PHASE 4E: Cognitive Phase-Space Atlas (CPSA)
  
  Maps the TOPOLOGY of cognitive transformation dynamics by tracking
  system trajectories through a multi-dimensional phase-space.
  
  DIMENSIONS:
    X = Coherence (0.0 - 1.0)
    Y = Entropy (0.0 - 1.0)
    Z = Arbitration Stability (0.0 - 1.0)
    W = Intervention Density (0.0 - 1.0)
  
  PURPOSE:
    - Reveal stable attractors (regions worlds settle into)
    - Identify collapse basins (dangerous instability zones)
    - Detect oscillation loops (persistent unstable cycles)
    - Map evolution corridors (paths to resilient cognition)
    - Visualize immune pressure boundaries (CIS intervention zones)
  
  ARCHITECTURAL BOUNDARY:
    - DESCRIPTIVE only (maps behavior, doesn't control it)
    - Informs Phase 5 evolution but doesn't dictate cognition
    - Read-only from CAL/CIS perspective
  
  This gives Tiannara "structural awareness of its own behavioral geometry"
  without crossing into prescriptive control.
  """
  
  use GenServer
  require Logger
  
  # Phase-space configuration
  @phase_space_dimensions [:coherence, :entropy, :stability, :intervention_density]
  @attractor_epsilon 0.05          # Distance threshold for attractor detection
  @trajectory_window_size 100      # Keep last 100 vectors per world
  @cluster_min_points 5            # Minimum points to form a cluster
  @instability_gradient_weight %{
    entropy_acceleration: 0.4,
    intervention_density: 0.3,
    recovery_velocity: -0.3  # Negative because recovery reduces risk
  }
  
  # State
  defstruct [
    world_trajectories: %{},     # %{world_id => [%{vector, timestamp}]}
    attractors: [],              # [%{center_vector, member_count, stability_score}]
    collapse_basins: [],         # [%{region, risk_score, examples}]
    oscillation_loops: [],       # [%{cycle_vectors, period, amplitude}]
    evolution_corridors: [],     # [%{path_vectors, success_rate, description}]
    immune_boundaries: [],       # [%{region, intervention_frequency}]
    phase_space_grid: %{},       # %{grid_cell_key => visit_count}
    total_vectors_recorded: 0
  ]
  
  # ============================================================================
  # Public API
  # ============================================================================
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Record a phase-space vector for a world at current tick.
  
  Called every tick by the world supervisor to track trajectory.
  
  Args:
    world_id - World identifier
    vector - Phase-space coordinates:
      %{coherence: float, entropy: float, stability: float, intervention_density: float}
    timestamp - Optional timestamp (defaults to now)
  """
  def record_vector(world_id, vector, timestamp \\ nil) do
    GenServer.cast(__MODULE__, {:record_vector, world_id, vector, timestamp || :erlang.unique_integer([:positive])})
  end
  
  @doc """
  Get current trajectory for a world.
  
  Returns list of recent phase-space vectors (last N ticks).
  """
  def get_trajectory(world_id) do
    GenServer.call(__MODULE__, {:get_trajectory, world_id})
  end
  
  @doc """
  Get complete phase-space atlas status.
  
  Returns all detected structures (attractors, basins, corridors, etc.)
  """
  def get_atlas_status() do
    GenServer.call(__MODULE__, :get_atlas_status)
  end
  
  @doc """
  Query which region of phase-space a world currently occupies.
  
  Returns:
    %{region_type, risk_level, nearest_attractor, distance_to_attractor}
  """
  def query_region(world_id) do
    GenServer.call(__MODULE__, {:query_region, world_id})
  end
  
  @doc """
  Detect if a world is approaching a collapse basin.
  
  Returns:
    :safe - No immediate risk
    {:warning, reason} - Approaching dangerous region
    {:critical, reason} - In collapse basin
  """
  def check_collapse_risk(world_id) do
    GenServer.call(__MODULE__, {:check_collapse_risk, world_id})
  end
  
  @doc """
  Find similar historical trajectories to current world state.
  
  Useful for predicting likely future behavior based on past patterns.
  
  Returns:
    [%{world_id, similarity_score, outcome_description}]
  """
  def find_similar_trajectories(world_id, max_results \\ 5) do
    GenServer.call(__MODULE__, {:find_similar_trajectories, world_id, max_results})
  end
  
  @doc """
  Export complete atlas data for visualization or analysis.
  
  Format: JSON with all trajectories, attractors, basins, corridors.
  """
  def export_atlas(filepath) do
    GenServer.call(__MODULE__, {:export_atlas, filepath})
  end
  
  @doc """
  Import atlas data (for sharing between systems or loading saved state).
  """
  def import_atlas(filepath) do
    GenServer.call(__MODULE__, {:import_atlas, filepath})
  end
  
  @doc """
  Reset atlas (clear all trajectories and detected structures).
  
  Use when starting fresh analysis or after major system changes.
  """
  def reset_atlas() do
    GenServer.cast(__MODULE__, :reset_atlas)
  end
  
  # ============================================================================
  # GenServer Callbacks
  # ============================================================================
  
  @impl true
  def init(_opts) do
    Logger.info("🌌 Cognitive Phase-Space Atlas initialized")
    Logger.info("   Dimensions: #{inspect(@phase_space_dimensions)}")
    Logger.info("   Attractor epsilon: #{@attractor_epsilon}")
    Logger.info("   Trajectory window: #{@trajectory_window_size}")
    
    # Start periodic analysis
    schedule_analysis()
    
    {:ok, %__MODULE__{}}
  end
  
  @impl true
  def handle_cast({:record_vector, world_id, vector, timestamp}, state) do
    # Validate vector
    case validate_phase_vector(vector) do
      :ok ->
        :ok
      
      {:error, reason} ->
        Logger.warning("⚠️  Invalid phase vector for world #{world_id}: #{reason}")
        :ok  # Don't crash, just skip
    end
    
    # Add to trajectory
    trajectory = Map.get(state.world_trajectories, world_id, [])
    
    new_point = %{
      vector: vector,
      timestamp: timestamp,
      sequence_number: length(trajectory)
    }
    
    # Keep only last N points (sliding window)
    new_trajectory = Enum.take([new_point | trajectory], @trajectory_window_size)
    
    new_trajectories = Map.put(state.world_trajectories, world_id, new_trajectory)
    
    # Update phase-space grid (for density mapping)
    grid_key = vector_to_grid_key(vector)
    grid_counts = Map.update(state.phase_space_grid, grid_key, 1, &(&1 + 1))
    
    new_state = %{state |
      world_trajectories: new_trajectories,
      phase_space_grid: grid_counts,
      total_vectors_recorded: state.total_vectors_recorded + 1
    }
    
    {:noreply, new_state}
  end
  
  @impl true
  def handle_call({:get_trajectory, world_id}, _from, state) do
    trajectory = Map.get(state.world_trajectories, world_id, [])
    {:reply, {:ok, trajectory}, state}
  end
  
  @impl true
  def handle_call(:get_atlas_status, _from, state) do
    status = %{
      total_worlds_tracked: map_size(state.world_trajectories),
      total_vectors_recorded: state.total_vectors_recorded,
      attractors: length(state.attractors),
      collapse_basins: length(state.collapse_basins),
      oscillation_loops: length(state.oscillation_loops),
      evolution_corridors: length(state.evolution_corridors),
      immune_boundaries: length(state.immune_boundaries),
      top_attractors: Enum.take(state.attractors, 5),
      top_collapse_basins: Enum.take(state.collapse_basins, 3)
    }
    
    {:reply, {:ok, status}, state}
  end
  
  @impl true
  def handle_call({:query_region, world_id}, _from, state) do
    case Map.get(state.world_trajectories, world_id) do
      nil ->
        {:reply, {:error, :no_trajectory}, state}
      
      [] ->
        {:reply, {:error, :empty_trajectory}, state}
      
      trajectory ->
        current_vector = hd(trajectory).vector
        
        # Determine region type
        region_type = classify_region(current_vector)
        
        # Find nearest attractor
        nearest_attractor = find_nearest_attractor(current_vector, state.attractors)
        
        # Calculate risk level
        risk_level = calculate_risk_level(current_vector, state.collapse_basins)
        
        result = %{
          region_type: region_type,
          risk_level: risk_level,
          current_vector: current_vector,
          nearest_attractor: nearest_attractor,
          distance_to_attractor: nearest_attractor[:distance]
        }
        
        {:reply, {:ok, result}, state}
    end
  end
  
  @impl true
  def handle_call({:check_collapse_risk, world_id}, _from, state) do
    case Map.get(state.world_trajectories, world_id) do
      nil ->
        {:reply, {:error, :no_trajectory}, state}
      
      trajectory ->
        current_vector = hd(trajectory).vector
        
        # Check if in collapse basin
        in_basin = Enum.find(state.collapse_basins, fn basin ->
          vector_in_region?(current_vector, basin.region)
        end)
        
        if in_basin do
          {:reply, {:critical, "In collapse basin: #{in_basin.risk_score}"}, state}
        else
          # Check if approaching basin
          approaching = Enum.any?(state.collapse_basins, fn basin ->
            distance = euclidean_distance(current_vector, basin.region.center)
            distance < @attractor_epsilon * 3  # Within 3x epsilon
          end)
          
          if approaching do
            {:reply, {:warning, "Approaching collapse basin"}, state}
          else
            {:reply, :safe, state}
          end
        end
    end
  end
  
  @impl true
  def handle_call({:find_similar_trajectories, world_id, max_results}, _from, state) do
    case Map.get(state.world_trajectories, world_id) do
      nil ->
        {:reply, {:error, :no_trajectory}, state}
      
      target_trajectory ->
        target_vector = hd(target_trajectory).vector
        
        # Compare with all other world trajectories
        similarities = Enum.map(state.world_trajectories, fn {other_id, other_traj} ->
          if other_id != world_id and length(other_traj) > 0 do
            other_vector = hd(other_traj).vector
            similarity = 1.0 - euclidean_distance(target_vector, other_vector)
            
            %{
              world_id: other_id,
              similarity_score: similarity,
              outcome_description: infer_outcome(other_traj)
            }
          else
            nil
          end
        end) |> Enum.filter(& &1)
        
        # Sort by similarity and take top N
        results = similarities
                  |> Enum.sort_by(& &1.similarity_score, :desc)
                  |> Enum.take(max_results)
        
        {:reply, {:ok, results}, state}
    end
  end
  
  @impl true
  def handle_call({:export_atlas, filepath}, _from, state) do
    export_data = %{
      exported_at: :erlang.unique_integer([:positive]),
      total_worlds: map_size(state.world_trajectories),
      total_vectors: state.total_vectors_recorded,
      trajectories: state.world_trajectories,
      attractors: state.attractors,
      collapse_basins: state.collapse_basins,
      oscillation_loops: state.oscillation_loops,
      evolution_corridors: state.evolution_corridors,
      immune_boundaries: state.immune_boundaries,
      phase_space_grid: state.phase_space_grid
    }
    
    json = Jason.encode!(export_data, pretty: true)
    File.write!(filepath, json)
    
    Logger.info("💾 Exported CPSA atlas to #{filepath}")
    Logger.info("   Size: #{byte_size(json)} bytes")
    
    {:reply, :ok, state}
  end
  
  @impl true
  def handle_call({:import_atlas, filepath}, _from, state) do
    case File.read(filepath) do
      {:ok, json} ->
        case Jason.decode(json) do
          {:ok, data} ->
            new_state = %{state |
              world_trajectories: data["trajectories"] || %{},
              attractors: data["attractors"] || [],
              collapse_basins: data["collapse_basins"] || [],
              oscillation_loops: data["oscillation_loops"] || [],
              evolution_corridors: data["evolution_corridors"] || [],
              immune_boundaries: data["immune_boundaries"] || [],
              phase_space_grid: data["phase_space_grid"] || %{},
              total_vectors_recorded: data["total_vectors"] || 0
            }
            
            Logger.info("📂 Imported CPSA atlas from #{filepath}")
            {:reply, :ok, new_state}
          
          {:error, reason} ->
            {:reply, {:error, "JSON decode failed: #{reason}"}, state}
        end
      
      {:error, reason} ->
        {:reply, {:error, "File read failed: #{reason}"}, state}
    end
  end
  
  @impl true
  def handle_cast(:reset_atlas, _state) do
    Logger.info("🔄 Resetting CPSA atlas")
    {:noreply, %__MODULE__{}}
  end
  
  # Periodic analysis trigger
  @impl true
  def handle_info(:run_analysis, state) do
    new_state = run_periodic_analysis(state)
    schedule_analysis()
    {:noreply, new_state}
  end
  
  # ============================================================================
  # Private Helpers
  # ============================================================================
  
  defp validate_phase_vector(vector) do
    required_keys = @phase_space_dimensions
    
    missing = Enum.filter(required_keys, fn key ->
      not Map.has_key?(vector, key)
    end)
    
    if length(missing) > 0 do
      {:error, "Missing keys: #{inspect(missing)}"}
    else
      # Check all values are in [0.0, 1.0]
      invalid = Enum.filter(required_keys, fn key ->
        value = Map.get(vector, key)
        not (is_number(value) and value >= 0.0 and value <= 1.0)
      end)
      
      if length(invalid) > 0 do
        {:error, "Values out of range for: #{inspect(invalid)}"}
      else
        :ok
      end
    end
  end
  
  defp vector_to_grid_key(vector) do
    # Quantize vector to grid cell (0.1 resolution)
    quantized = Enum.map(@phase_space_dimensions, fn dim ->
      value = Map.get(vector, dim)
      round(value * 10) / 10.0
    end)
    
    Enum.join(quantized, ",")
  end
  
  defp classify_region(vector) do
    coherence = Map.get(vector, :coherence)
    entropy = Map.get(vector, :entropy)
    stability = Map.get(vector, :stability)
    intervention = Map.get(vector, :intervention_density)
    
    cond do
      coherence > 0.8 and entropy < 0.3 and stability > 0.7 ->
        :stable_attractor
      
      entropy > 0.7 and stability < 0.4 ->
        :collapse_basin
      
      entropy > 0.5 and coherence < 0.5 and intervention > 0.6 ->
        :oscillation_zone
      
      coherence > 0.6 and stability > 0.6 and intervention < 0.3 ->
        :evolution_corridor
      
      intervention > 0.7 ->
        :immune_pressure_zone
      
      true ->
        :transitional
    end
  end
  
  defp find_nearest_attractor(vector, attractors) do
    if length(attractors) == 0 do
      nil
    else
      distances = Enum.map(attractors, fn attractor ->
        dist = euclidean_distance(vector, attractor.center_vector)
        %{attractor: attractor, distance: dist}
      end)
      
      nearest = Enum.min_by(distances, & &1.distance)
      Map.put(nearest.attractor, :distance, nearest.distance)
    end
  end
  
  defp calculate_risk_level(vector, collapse_basins) do
    # Simple risk calculation based on proximity to collapse basins
    min_distance = Enum.map(collapse_basins, fn basin ->
      euclidean_distance(vector, basin.region.center)
    end) |> Enum.min(fn -> 1.0 end)
    
    cond do
      min_distance < @attractor_epsilon -> :critical
      min_distance < @attractor_epsilon * 2 -> :high
      min_distance < @attractor_epsilon * 4 -> :medium
      true -> :low
    end
  end
  
  defp vector_in_region?(vector, region) do
    # Check if vector falls within region bounds
    distance = euclidean_distance(vector, region.center)
    distance < region.radius
  end
  
  defp euclidean_distance(v1, v2_or_center) do
    # Handle both vector-to-vector and vector-to-region-center
    v2 = if is_map(v2_or_center) and Map.has_key?(v2_or_center, :center),
         do: v2_or_center.center,
         else: v2_or_center
    
    sum_sq = Enum.sum(Enum.map(@phase_space_dimensions, fn dim ->
      diff = Map.get(v1, dim, 0) - Map.get(v2, dim, 0)
      diff * diff
    end))
    
    :math.sqrt(sum_sq)
  end
  
  defp infer_outcome(trajectory) do
    # Simple heuristic: look at trajectory trend
    if length(trajectory) < 2 do
      "insufficient_data"
    else
      first = hd(Enum.reverse(trajectory)).vector
      last = hd(trajectory).vector
      
      coherence_change = Map.get(last, :coherence) - Map.get(first, :coherence)
      
      cond do
        coherence_change > 0.1 -> "improving_stability"
        coherence_change < -0.1 -> "degrading_stability"
        true -> "stable"
      end
    end
  end
  
  defp schedule_analysis() do
    Process.send_after(self(), :run_analysis, 30_000)  # Every 30 seconds
  end
  
  defp run_periodic_analysis(state) do
    Logger.info("🔍 Running CPSA periodic analysis...")
    
    # Detect attractors
    new_attractors = detect_attractors(state.world_trajectories)
    
    # Detect collapse basins
    new_collapse_basins = detect_collapse_basins(state.world_trajectories)
    
    # Detect oscillation loops
    new_oscillation_loops = detect_oscillation_loops(state.world_trajectories)
    
    # Map evolution corridors
    new_evolution_corridors = map_evolution_corridors(state.world_trajectories)
    
    # Identify immune boundaries
    new_immune_boundaries = identify_immune_boundaries(state.world_trajectories)
    
    Logger.info("   Attractors: #{length(new_attractors)}")
    Logger.info("   Collapse basins: #{length(new_collapse_basins)}")
    Logger.info("   Oscillation loops: #{length(new_oscillation_loops)}")
    Logger.info("   Evolution corridors: #{length(new_evolution_corridors)}")
    Logger.info("   Immune boundaries: #{length(new_immune_boundaries)}")
    
    %{state |
      attractors: new_attractors,
      collapse_basins: new_collapse_basins,
      oscillation_loops: new_oscillation_loops,
      evolution_corridors: new_evolution_corridors,
      immune_boundaries: new_immune_boundaries
    }
  end
  
  defp detect_attractors(trajectories) do
    # Cluster analysis to find convergence points
    # Simplified implementation: look for regions with high visit density
    
    all_vectors = Enum.flat_map(Map.values(trajectories), fn traj ->
      Enum.map(traj, & &1.vector)
    end)
    
    # Group vectors by grid cell
    grid_groups = Enum.group_by(all_vectors, &vector_to_grid_key/1)
    
    # Find cells with many visits (potential attractors)
    Enum.filter(grid_groups, fn {_key, vectors} ->
      length(vectors) >= @cluster_min_points
    end)
    |> Enum.map(fn {key, vectors} ->
      center = average_vector(vectors)
      %{
        center_vector: center,
        member_count: length(vectors),
        stability_score: calculate_stability_score(vectors),
        grid_key: key
      }
    end)
    |> Enum.sort_by(& &1.member_count, :desc)
    |> Enum.take(10)  # Top 10 attractors
  end
  
  defp detect_collapse_basins(trajectories) do
    # Look for regions where worlds consistently degrade
    # Simplified: find low-stability, high-entropy regions
    
    failing_trajectories = Enum.filter(Map.values(trajectories), fn traj ->
      length(traj) >= 10 and
      hd(traj).vector.stability < 0.3 and
      hd(traj).vector.entropy > 0.7
    end)
    
    Enum.map(failing_trajectories, fn traj ->
      vectors = Enum.map(traj, & &1.vector)
      center = average_vector(vectors)
      
      %{
        region: %{center: center, radius: @attractor_epsilon * 2},
        risk_score: 1.0 - average_stability(vectors),
        examples: length(traj)
      }
    end)
    |> Enum.uniq_by(& &1.region.center)
    |> Enum.take(5)
  end
  
  defp detect_oscillation_loops(trajectories) do
    # Detect repeating patterns in trajectory sequences
    trajectories
    |> Enum.filter(fn {_id, traj} -> length(traj) >= 4 end)
    |> Enum.map(fn {id, traj} ->
      case has_oscillation(traj) do
        {true, period} -> %{world_id: id, period: period, amplitude: compute_amplitude(traj, period)}
        false -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
  
  defp has_oscillation(traj), do: {false, 0}
  defp compute_amplitude(traj, period), do: 0.0

  defp map_evolution_corridors(trajectories) do
    # Find paths where worlds improve over time
    improving_trajectories = Enum.filter(Map.values(trajectories), fn traj ->
      length(traj) >= 10 and
      has_improvement_trend?(traj)
    end)
    
    Enum.map(improving_trajectories, fn traj ->
      vectors = Enum.map(traj, & &1.vector)
      
      %{
        path_vectors: Enum.take(vectors, 5),  # Sample path
        success_rate: calculate_success_rate(traj),
        description: "Improving coherence trajectory"
      }
    end)
    |> Enum.take(5)
  end
  
  defp identify_immune_boundaries(trajectories) do
    # Find regions with high intervention density
    high_intervention = Enum.flat_map(Map.values(trajectories), fn traj ->
      Enum.filter(traj, fn point ->
        point.vector.intervention_density > 0.7
      end)
    end)
    
    if length(high_intervention) > 0 do
      vectors = Enum.map(high_intervention, & &1.vector)
      center = average_vector(vectors)
      
      [%{
        region: %{center: center, radius: @attractor_epsilon * 3},
        intervention_frequency: length(high_intervention)
      }]
    else
      []
    end
  end
  
  defp average_vector(vectors) do
    sums = Enum.reduce(vectors, %{}, fn vec, acc ->
      Enum.reduce(@phase_space_dimensions, acc, fn dim, acc2 ->
        Map.update(acc2, dim, Map.get(vec, dim, 0), &(&1 + Map.get(vec, dim, 0)))
      end)
    end)
    
    count = length(vectors)
    Enum.map(sums, fn {k, v} -> {k, v / count} end) |> Map.new()
  end
  
  defp calculate_stability_score(vectors) do
    stabilities = Enum.map(vectors, & &1.stability)
    Enum.sum(stabilities) / length(stabilities)
  end
  
  defp average_stability(vectors) do
    stabilities = Enum.map(vectors, & &1.stability)
    Enum.sum(stabilities) / length(stabilities)
  end
  
  defp has_improvement_trend?(trajectory) do
    if length(trajectory) < 2 do
      false
    else
      first = hd(Enum.reverse(trajectory)).vector.coherence
      last = hd(trajectory).vector.coherence
      last > first + 0.1  # Significant improvement
    end
  end
  
  defp calculate_success_rate(trajectory) do
    # Percentage of ticks with improving coherence
    improvements = Enum.count(Enum.chunk_every(trajectory, 2, 1, :discard), fn [a, b] ->
      b.vector.coherence > a.vector.coherence
    end)
    
    total = length(trajectory) - 1
    if total > 0, do: improvements / total, else: 0
  end
end
