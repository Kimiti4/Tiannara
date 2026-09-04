defmodule Tiannara.Stabilization.CTL do
  @moduledoc """
  Causal Tensor Lattice (CTL).

  Maintains global causal consistency across branches and realities,
  preventing timeline paradoxes, causal loops, and history corruption.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def validate_causality(causal_graph) do
    GenServer.call(__MODULE__, {:validate_causality, causal_graph})
  end

  def repair_timeline(timeline_id, causal_structure) do
    GenServer.call(__MODULE__, {:repair_timeline, timeline_id, causal_structure})
  end

  def detect_paradox(causal_graph) do
    GenServer.call(__MODULE__, {:detect_paradox, causal_graph})
  end

  def propagate_causal_stress(causal_change) do
    GenServer.call(__MODULE__, {:propagate_causal_stress, causal_change})
  end

  def stabilize_causality(causal_graph) do
    GenServer.call(__MODULE__, {:stabilize_causality, causal_graph})
  end

  def get_causal_consistency_score() do
    GenServer.call(__MODULE__, :get_causal_consistency_score)
  end

  def get_timeline_status(timeline_id) do
    GenServer.call(__MODULE__, {:get_timeline_status, timeline_id})
  end

  def branch_recombine(timeline_ids) do
    GenServer.call(__MODULE__, {:branch_recombine, timeline_ids})
  end

  def get_causal_lattice_stats() do
    GenServer.call(__MODULE__, :get_causal_lattice_stats)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for causal lattice
    :ets.new(:causal_lattice, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:timeline_consistency, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:causal_stress_matrix, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:paradox_history, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Configuration parameters
    config = %{
      paradox_threshold: 0.95,
      repair_threshold: 0.8,
      stress_threshold: 0.7,
      max_consistency_score: 1.0,
      lattice_decay_rate: 0.95,
      temporal_window: 1000  # milliseconds
    }

    Logger.info("CTL initialized with causal lattice parameters")
    
    {:ok, %{
      config: config,
      consistency_score: 1.0,
      detected_paradoxes: 0,
      repairs_performed: 0,
      stress_propagations: 0,
      last_validation: 0
    }}
  end

  @impl true
  def handle_call({:validate_causality, causal_graph}, _from, state) do
    # Validate the causal structure
    validation_result = validate_causal_structure(causal_graph, state.config)
    
    case validation_result do
      {:valid, score} ->
        # Update consistency score
        new_score = update_consistency_score(score, state.consistency_score, state.config)
        
        # Store validation result
        timestamp = System.system_time(:millisecond)
        :ets.insert(:timeline_consistency, {timestamp, causal_graph, score})
        
        Logger.debug("Causal validation passed with score #{score}")
        
        {:reply, {:ok, score}, %{state | 
          consistency_score: new_score,
          last_validation: timestamp
        }}
        
      {:invalid, reason} ->
        Logger.warning("Causal validation failed: #{reason}")
        
        # Check for paradox
        paradox_check = detect_causal_paradox(causal_graph)
        timestamp = System.system_time(:millisecond)
        
        case paradox_check do
          {:paradox, details} ->
            :ets.insert(:paradox_history, {timestamp, causal_graph, details})
            {:reply, {:error, reason, paradox: details}, state}
          :no_paradox ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl true
  def handle_call({:repair_timeline, timeline_id, causal_structure}, _from, state) do
    # Check if repair is needed
    case should_repair(causal_structure, state.config.repair_threshold) do
      true ->
        # Perform causal repair
        repaired = repair_causal_structure(causal_structure, state.config)
        
        # Validate repaired structure
        case validate_causal_structure(repaired, state.config) do
          {:valid, score} ->
            # Store repaired timeline
            :ets.insert(:timeline_consistency, {System.system_time(:millisecond), repaired, score})
            :ets.insert(:causal_lattice, {timeline_id, repaired})
            
            Logger.info("Repaired timeline #{timeline_id} with score #{score}")
            
            {:reply, {:ok, repaired}, %{state | 
              repairs_performed: state.repairs_performed + 1,
              consistency_score: score
            }}
            
          {:invalid, reason} ->
            Logger.error("Failed to repair timeline #{timeline_id}: #{reason}")
            {:reply, {:error, reason}, state}
        end
        
      false ->
        Logger.debug("Timeline #{timeline_id} does not require repair")
        {:reply, {:ok, :no_repair_needed}, state}
    end
  end

  @impl true
  def handle_call({:detect_paradox, causal_graph}, _from, state) do
    paradox_result = detect_causal_paradox(causal_graph)
    
    case paradox_result do
      {:paradox, details} ->
        # Log paradox
        timestamp = System.system_time(:millisecond)
        :ets.insert(:paradox_history, {timestamp, causal_graph, details})
        
        Logger.warning("Detected causal paradox: #{inspect(details)}")
        
        {:reply, {:paradox, details}, %{state | 
          detected_paradoxes: state.detected_paradoxes + 1
        }}
        
      :no_paradox ->
        Logger.debug("No causal paradox detected")
        {:reply, :no_paradox, state}
    end
  end

  @impl true
  def handle_call({:propagate_causal_stress, causal_change}, _from, state) do
    # Propagate causal stress through the lattice
    propagation_result = propagate_stress(causal_change, state.config)
    
    case propagation_result do
      {:stabilized, stress_value} ->
        # Update stress matrix
        timestamp = System.system_time(:millisecond)
        :ets.insert(:causal_stress_matrix, {timestamp, stress_value})
        
        Logger.debug("Propagated causal stress: #{stress_value}")
        
        {:reply, {:ok, stress_value}, %{state | 
          stress_propagations: state.stress_propagations + 1
        }}
        
      {:unstable, stress_value} ->
        Logger.warning("Causal stress propagation unstable: #{stress_value}")
        {:reply, {:warning, stress_value}, state}
    end
  end

  @impl true
  def handle_call(:get_causal_consistency_score, _from, state) do
    {:reply, {:ok, state.consistency_score}, state}
  end

  @impl true
  def handle_call({:stabilize_causality, causal_graph}, _from, state) do
    Logger.info("Stabilizing causal graph")
    
    # Validate causal structure first
    case validate_causal_structure(causal_graph, state.config) do
      {:valid, _score} ->
        # Apply stabilization algorithms
        stabilized_graph = apply_stabilization_algorithms(causal_graph, state.config)
        
        # Update consistency score
        new_consistency_score = calculate_consistency_score(stabilized_graph)
        
        # Store stabilized graph
        :ets.insert(:causal_lattice, {System.system_time(:millisecond), stabilized_graph})
        
        Logger.info("Causal graph stabilized with consistency score #{new_consistency_score}")
        
        {:reply, {:ok, stabilized_graph}, %{state |
          consistency_score: new_consistency_score,
          stabilizations_performed: state.stabilizations_performed + 1
        }}
        
      {:invalid, reason} ->
        Logger.error("Cannot stabilize invalid causal graph: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:get_timeline_status, timeline_id}, _from, state) do
    case :ets.lookup(:causal_lattice, timeline_id) do
      [{^timeline_id, causal_graph}] ->
        # Calculate consistency score for this timeline
        case validate_causal_structure(causal_graph, state.config) do
          {:valid, score} ->
            status = %{
              timeline_id: timeline_id,
              consistency_score: score,
              causal_nodes: count_causal_nodes(causal_graph),
              causal_links: count_causal_links(causal_graph),
              timestamp: System.system_time(:millisecond)
            }
            {:reply, {:ok, status}, state}
          {:invalid, reason} ->
            {:reply, {:error, reason}, state}
        end
        
      [] ->
        {:reply, {:error, :timeline_not_found}, state}
    end
  end

  @impl true
  def handle_call({:branch_recombine, timeline_ids}, _from, state) do
    # Validate all timelines before recombination
    valid_timelines = Enum.filter(timeline_ids, fn id ->
      case :ets.lookup(:causal_lattice, id) do
        [{^id, _}] -> true
        [] -> false
      end
    end)
    
    case length(valid_timelines) do
      0 ->
        {:reply, {:error, :no_valid_timelines}, state}
        
      _ ->
        # Perform branch recombination
        recombined = recombine_branches(valid_timelines, state.config)
        
        # Store recombined timeline
        recombined_id = "recombined_#{System.system_time(:millisecond)}"
        :ets.insert(:causal_lattice, {recombined_id, recombined})
        
        Logger.info("Recombined #{length(valid_timelines)} timelines into #{recombined_id}")
        
        {:reply, {:ok, recombined_id}, state}
    end
  end

  @impl true
  def handle_call(:get_causal_lattice_stats, _from, state) do
    stats = %{
      consistency_score: state.consistency_score,
      timeline_count: :ets.info(:causal_lattice, :size),
      paradox_count: :ets.info(:paradox_history, :size),
      repairs_performed: state.repairs_performed,
      stress_propagations: state.stress_propagations,
      last_validation: state.last_validation,
      config: state.config
    }
    
    {:reply, {:ok, stats}, state}
  end

  # Helper functions
  defp validate_causal_structure(causal_graph, config) when is_map(causal_graph) do
    # Check for temporal loops
    temporal_loops = detect_temporal_loops(causal_graph)
    if temporal_loops > 0 do
      loop_score = temporal_loops / max(1, count_causal_nodes(causal_graph))
      if loop_score > config.paradox_threshold do
        {:invalid, :temporal_paradox_detected}
      else
        {:valid, 1.0 - loop_score}
      end
    else
      # Check for causal consistency
      consistency_score = calculate_causal_consistency(causal_graph)
      
      if consistency_score >= config.repair_threshold do
        {:valid, consistency_score}
      else
        {:invalid, :causal_inconsistency}
      end
    end
  end

  defp validate_causal_structure(_, _), do: {:invalid, :invalid_graph_structure}

  defp detect_temporal_loops(causal_graph) do
    # Simplified temporal loop detection using graph traversal
    # In production, use proper graph algorithms
    
    # Count nodes with self-referential causality
    self_references = Map.values(causal_graph)
    |> Enum.count(fn links -> 
      Enum.any?(links, fn {target, _} -> target == :self end)
    end)
    
    self_references
  end

  defp calculate_causal_consistency(causal_graph) do
    # Calculate consistency score based on causal structure
    total_links = count_causal_links(causal_graph)
    inconsistent_links = count_inconsistent_links(causal_graph)
    
    if total_links > 0 do
      1.0 - (inconsistent_links / total_links)
    else
      1.0
    end
  end

  defp count_causal_nodes(causal_graph) when is_map(causal_graph) do
    map_size(causal_graph)
  end

  defp count_causal_links(causal_graph) when is_map(causal_graph) do
    Map.values(causal_graph) |> Enum.map(&length/1) |> Enum.sum()
  end

  defp count_inconsistent_links(causal_graph) do
    # Count links that create causal inconsistencies
    Map.values(causal_graph)
    |> Enum.map(fn links -> 
      Enum.count(links, fn {_, weight} -> weight < 0.0 end)
    end)
    |> Enum.sum()
  end

  defp should_repair(causal_structure, threshold) do
    case validate_causal_structure(causal_structure, %{repair_threshold: threshold}) do
      {:valid, score} when score < threshold -> true
      _ -> false
    end
  end

  defp repair_causal_structure(causal_graph, _config) do
    # Simplified causal repair algorithm
    repaired = Map.new(causal_graph, fn {node, links} ->
      # Normalize weights and remove inconsistent links
      repaired_links = Enum.map(links, fn {target, weight} ->
        if weight < 0.0 do
          # Repair negative weights
          {target, abs(weight) * 0.5}
        else
          {target, weight}
        end
      end)
      {node, repaired_links}
    end)
    
    repaired
  end

  defp detect_causal_paradox(causal_graph) do
    temporal_loops = detect_temporal_loops(causal_graph)
    
    if temporal_loops > 0 do
      {:paradox, %{
        type: :temporal_loop,
        loop_count: temporal_loops,
        severity: temporal_loops / max(1, count_causal_nodes(causal_graph))
      }}
    else
      :no_paradox
    end
  end

  defp propagate_stress(causal_change, config) do
    # Simplified stress propagation
    stress_value = calculate_stress_magnitude(causal_change)
    
    if stress_value > config.stress_threshold do
      {:unstable, stress_value}
    else
      {:stabilized, stress_value}
    end
  end

  defp calculate_stress_magnitude(causal_change) when is_map(causal_change) do
    # Calculate stress based on change magnitude
    change_weights = Map.values(causal_change) |> Enum.map(&abs/1)
    if length(change_weights) > 0 do
      Enum.sum(change_weights) / length(change_weights)
    else
      0.0
    end
  end

  defp recombine_branches(timeline_ids, _config) do
    # Simplified branch recombination
    # In production, use proper merge algorithms
    
    # Get all causal graphs
    graphs = Enum.map(timeline_ids, fn id ->
      case :ets.lookup(:causal_lattice, id) do
        [{^id, graph}] -> graph
        [] -> %{}
      end
    end)
    
    # Merge graphs (simplified approach)
    merged = Enum.reduce(graphs, %{}, fn graph, acc ->
      Map.merge(acc, graph, fn _node, links1, links2 ->
        # Merge links by averaging weights
        merged_links = case {links1, links2} do
          {[], _} -> links2
          {_, []} -> links1
          {l1, l2} ->
            # Combine links from both timelines
            all_links = l1 ++ l2
            Enum.reduce(all_links, %{}, fn {target, weight}, merged_acc ->
              existing = Map.get(merged_acc, target, 0.0)
              Map.put(merged_acc, target, (existing + weight) / 2)
            end)
        end
        merged_links
      end)
    end)
    
    merged
  end

  defp update_consistency_score(new_score, current_score, config) do
    # Apply lattice decay
    decayed_current = current_score * config.lattice_decay_rate

    # Weighted average with new score
    (decayed_current * 0.7) + (new_score * 0.3)
  end

  defp apply_stabilization_algorithms(causal_graph, config) do
    # Apply repair and normalization passes to the causal graph
    repaired = repair_causal_structure(causal_graph, config)
    repaired
  end

  defp calculate_consistency_score(causal_graph) when is_map(causal_graph) do
    # Score based on the ratio of positive-weighted edges
    all_links =
      causal_graph
      |> Map.values()
      |> List.flatten()

    total = length(all_links)
    if total == 0 do
      1.0
    else
      positive = Enum.count(all_links, fn {_, w} -> w >= 0 end)
      positive / total
    end
  end
end
