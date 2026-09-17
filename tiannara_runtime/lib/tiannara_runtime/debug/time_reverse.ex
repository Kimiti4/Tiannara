defmodule Tiannara.Debug.TimeReverse do
  @moduledoc """
  Time-Reversed Evolution Debugging Mode - Reconstructs causal formation in reverse.
  
  Instead of forward replay (event → event → event), this module enables:
  
  **Mode A - Standard Replay**: Forward timeline navigation
  **Mode B - Entropy Reverse Walk**: final_state → intermediate → origin_seed
  **Mode C - Causal Unfolding**: Reconstruct WHY a system had to evolve that way
  
  ## Key Features
  
  - Invert entropy flow to trace back to origin conditions
  - Reconstruct causal dependencies in reverse chronological order
  - Identify critical bifurcation points where evolution could have diverged
  - Generate "causal fossils" - immutable snapshots of extinct world states
  
  ## Usage
  
      # Reverse replay from current state to origin
      {:ok, reversed_timeline} = TimeReverse.reverse_replay(graph, "W1")
      
      # Get entropy-decreasing trajectory
      {:ok, trajectory} = TimeReverse.entropy_reverse_walk("W1", target_entropy: 0.1)
      
      # Analyze causal necessity (why did evolution follow this path?)
      {:ok, analysis} = TimeReverse.causal_unfolding(graph, "W1")
  """

  use GenServer
  require Logger

  alias Tiannara.Causality.Graph

  @type reversal_mode :: :standard | :entropy_reverse | :causal_unfolding
  @type reversal_result :: %{
    mode: reversal_mode(),
    timeline: [reversal_step()],
    origin_conditions: map() | nil,
    bifurcation_points: [bifurcation_point()]
  }

  @type reversal_step :: %{
    step_number: non_neg_integer(),
    node_id: String.t(),
    timestamp: DateTime.t(),
    entropy_level: float(),
    action: String.t(),
    reversed_causality: [String.t()] | nil
  }

  @type bifurcation_point :: %{
    node_id: String.t(),
    alternative_paths: [String.t()],
    selection_reason: String.t()
  }

  defstruct [:mode, :timeline, :origin_conditions, :bifurcation_points]

  # ==================== GenServer API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("⏳ TimeReverse debugger initialized (entropy inversion engine)")
    {:ok, %{}}
  end

  # ==================== Public API ====================

  @doc """
  Perform standard forward replay of world's causal history.
  """
  def standard_replay(world_id, max_steps \\ 100) do
    GenServer.call(__MODULE__, {:replay, world_id, :standard, max_steps})
  end

  @doc """
  Reverse walk through entropy levels from current state back to origin seed.
  
  Options:
    - target_entropy: Stop when reaching this entropy level (default: 0.1)
    - max_steps: Maximum reversal steps (default: 50)
  """
  def entropy_reverse_walk(world_id, opts \\ []) do
    target_entropy = Keyword.get(opts, :target_entropy, 0.1)
    max_steps = Keyword.get(opts, :max_steps, 50)
    
    GenServer.call(__MODULE__, {:replay, world_id, :entropy_reverse, max_steps, target_entropy})
  end

  @doc """
  Causal unfolding analysis - reconstruct why evolution followed this specific path.
  
  Identifies:
  - Critical bifurcation points
  - Alternative paths not taken
  - Selection pressures that determined outcomes
  """
  def causal_unfolding(world_id, max_depth \\ 20) do
    GenServer.call(__MODULE__, {:replay, world_id, :causal_unfolding, max_depth})
  end

  @doc """
  Capture causal snapshot before world termination (for KillSwitch integration).
  
  Creates immutable branch in evolutionary archive.
  """
  def capture_causal_snapshot(world_id, reason) do
    GenServer.cast(__MODULE__, {:capture_snapshot, world_id, reason})
  end

  @doc """
  Get reversal statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def handle_call({:replay, world_id, :standard, max_steps}, _from, state) do
    # Query causal graph for world's history
    case Graph.query_world_causality(world_id, max_steps) do
      {:ok, causality_data} ->
        timeline = build_standard_timeline(causality_data)
        
        result = %__MODULE__{
          mode: :standard,
          timeline: timeline,
          origin_conditions: find_origin_conditions(timeline),
          bifurcation_points: identify_bifurcations(causality_data)
        }
        
        {:reply, {:ok, result}, state}
      
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:replay, world_id, :entropy_reverse, max_steps, target_entropy}, _from, state) do
    # Reverse walk through entropy levels
    case Graph.query_world_causality(world_id, max_steps) do
      {:ok, causality_data} ->
        # Sort nodes by entropy descending (reverse temporal order)
        sorted_nodes = sort_by_entropy_desc(causality_data.nodes)
        
        timeline = Enum.with_index(sorted_nodes, 1) |> Enum.map(fn {node, step_num} ->
          %{
            step_number: step_num,
            node_id: node.id,
            timestamp: node.timestamp,
            entropy_level: Map.get(node.payload, :entropy, 0.5),
            action: "entropy_decrease",
            reversed_causality: get_predecessors(node.id, causality_data.edges)
          }
        end)
        
        # Stop when reaching target entropy
        filtered_timeline = Enum.take_while(timeline, fn step ->
          step.entropy_level >= target_entropy
        end)
        
        result = %__MODULE__{
          mode: :entropy_reverse,
          timeline: filtered_timeline,
          origin_conditions: extract_origin_state(List.last(filtered_timeline)),
          bifurcation_points: []
        }
        
        Logger.info("⏪ Entropy reverse walk: #{length(filtered_timeline)} steps (target: #{target_entropy})")
        {:reply, {:ok, result}, state}
      
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:replay, world_id, :causal_unfolding, max_depth}, _from, state) do
    # Analyze causal necessity
    case Graph.query_world_causality(world_id, max_depth) do
      {:ok, causality_data} ->
        # Identify critical decision points
        bifurcations = analyze_bifurcation_points(causality_data)
        
        # Reconstruct selection pressures
        selection_analysis = reconstruct_selection_pressures(causality_data)
        
        result = %__MODULE__{
          mode: :causal_unfolding,
          timeline: build_causal_narrative(causality_data),
          origin_conditions: %{
            initial_entropy: find_initial_entropy(causality_data),
            dominant_species: find_dominant_species(causality_data),
            key_mutations: extract_key_mutations(causality_data)
          },
          bifurcation_points: bifurcations
        }
        
        Logger.info("🔍 Causal unfolding complete: #{length(bifurcations)} bifurcation points identified")
        {:reply, {:ok, result}, state}
      
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_cast({:capture_snapshot, world_id, reason}, state) do
    # Capture full causal state before termination
    case Graph.query_world_causality(world_id, 1000) do
      {:ok, causality_data} ->
        snapshot = %{
          world_id: world_id,
          reason: reason,
          timestamp: DateTime.utc_now(),
          total_nodes: length(causality_data.nodes),
          total_edges: length(causality_data.edges),
          causal_density: calculate_causal_density(causality_data),
          data: causality_data
        }
        
        # Store in ETS for archival
        :ets.insert(:causal_snapshots, {world_id, snapshot})
        
        Logger.info("📸 Captured causal snapshot for #{world_id} (#{reason})")
      
      {:error, _} ->
        Logger.warning("⚠️  Failed to capture causal snapshot for #{world_id}")
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    snapshot_count = :ets.info(:causal_snapshots, :size)
    
    stats = %{
      total_snapshots: snapshot_count,
      active_replays: 0  # TODO: Track active reversal sessions
    }
    
    {:reply, {:ok, stats}, state}
  end

  # ==================== Private Helpers ====================

  defp build_standard_timeline(causality_data) do
    # Sort nodes chronologically
    sorted = Enum.sort_by(causality_data.nodes, fn {_id, node} -> node.timestamp end)
    
    Enum.with_index(sorted, 1) |> Enum.map(fn {{_id, node}, step_num} ->
      %{
        step_number: step_num,
        node_id: node.id,
        timestamp: node.timestamp,
        entropy_level: Map.get(node.payload, :entropy, 0.5),
        action: describe_node_action(node),
        reversed_causality: nil
      }
    end)
  end

  defp sort_by_entropy_desc(nodes) do
    Enum.sort_by(nodes, fn {_id, node} ->
      Map.get(node.payload, :entropy, 0.5)
    end, :desc)
  end

  defp get_predecessors(node_id, edges) do
    Enum.filter(edges, fn {_edge_id, edge} -> edge.to == node_id end)
    |> Enum.map(fn {_edge_id, edge} -> edge.from end)
  end

  defp find_origin_conditions(timeline) do
    case List.last(timeline) do
      nil -> nil
      last_step ->
        %{
          earliest_timestamp: last_step.timestamp,
          initial_entropy: last_step.entropy_level
        }
    end
  end

  defp identify_bifurcations(causality_data) do
    # Find nodes with multiple outgoing edges (decision points)
    Enum.filter(causality_data.edges, fn {_edge_id, edge} -> edge.type == :direct end)
    |> Enum.group_by(fn {_edge_id, edge} -> edge.from end)
    |> Enum.filter(fn {_from_id, edges} -> length(edges) > 1 end)
    |> Enum.map(fn {from_id, edges} ->
      %{
        node_id: from_id,
        alternative_paths: Enum.map(edges, fn {_edge_id, e} -> e.to end),
        selection_reason: "entropy_optimization"
      }
    end)
  end

  defp analyze_bifurcation_points(causality_data) do
    # Advanced bifurcation analysis with selection pressure context
    identify_bifurcations(causality_data)
    |> Enum.map(fn bifurcation ->
      # Enrich with entropy context
      node = causality_data.nodes[bifurcation.node_id]
      entropy = if node, do: Map.get(node.payload, :entropy, 0.5), else: 0.5
      
      %{bifurcation | selection_reason: "entropy_#{if entropy > 0.5, do: "high", else: "low"}_pressure"}
    end)
  end

  defp reconstruct_selection_pressures(causality_data) do
    # Analyze what forces drove evolution
    %{
      avg_entropy: calculate_avg_entropy(causality_data.nodes),
      mutation_rate: estimate_mutation_rate(causality_data),
      dominant_fitness: find_peak_fitness(causality_data.nodes)
    }
  end

  defp build_causal_narrative(causality_data) do
    # Create narrative explanation of causal chain
    build_standard_timeline(causality_data)
    |> Enum.map(fn step ->
      %{step | action: "#{step.action} (driven by selection pressure)"}
    end)
  end

  defp extract_origin_state(final_step) do
    %{
      final_entropy: final_step.entropy_level,
      reversal_complete: true
    }
  end

  defp find_initial_entropy(causality_data) do
    case Enum.min_by(causality_data.nodes, fn {_id, node} -> node.timestamp end) do
      {_id, node} -> Map.get(node.payload, :entropy, 0.5)
      nil -> 0.5
    end
  end

  defp find_dominant_species(causality_data) do
    # Extract species information from nodes
    "unknown"  # TODO: Implement species tracking
  end

  defp extract_key_mutations(causality_data) do
    # Find mutation-type nodes
    Enum.filter(causality_data.nodes, fn {_id, node} -> node.type == :mutation end)
    |> Enum.map(fn {_id, node} -> node.id end)
  end

  defp describe_node_action(node) do
    case node.type do
      :event -> "event_occurred"
      :mutation -> "genome_mutated"
      :kill -> "world_terminated"
      :merge -> "chimeric_collapse"
      :law_change -> "physics_law_mutated"
    end
  end

  defp calculate_causal_density(causality_data) do
    node_count = length(causality_data.nodes)
    edge_count = length(causality_data.edges)
    
    if node_count > 0 do
      edge_count / (node_count * (node_count - 1))
    else
      0.0
    end
  end

  defp calculate_avg_entropy(nodes) do
    entropies = Enum.map(nodes, fn {_id, node} -> Map.get(node.payload, :entropy, 0.5) end)
    if length(entropies) > 0 do
      Enum.sum(entropies) / length(entropies)
    else
      0.5
    end
  end

  defp estimate_mutation_rate(causality_data) do
    mutation_count = Enum.count(causality_data.nodes, fn {_id, node} -> node.type == :mutation end)
    total_count = length(causality_data.nodes)
    
    if total_count > 0 do
      mutation_count / total_count
    else
      0.0
    end
  end

  defp find_peak_fitness(nodes) do
    fitnesses = Enum.map(nodes, fn {_id, node} -> Map.get(node.payload, :fitness, 0.5) end)
    if length(fitnesses) > 0 do
      Enum.max(fitnesses)
    else
      0.5
    end
  end
end
