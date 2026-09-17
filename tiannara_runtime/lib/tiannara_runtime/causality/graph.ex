defmodule Tiannara.Causality.Graph do
  @moduledoc """
  Mutable Causal Ontology Engine - Evolving directed graph of cause-effect relationships.
  
  Instead of treating causality as static logs, this module maintains a dynamic graph
  that re-optimizes itself for coherence under entropy pressure.
  
  ## Core Concepts
  
  **Nodes**: Events, mutations, kills, merges, law changes
  **Edges**: Directed causal links with weights and stability metrics
  **Mutation Pressure**: Entropy-driven force that rewires weak edges
  **Retrocausal Alignment**: Future events can reweight past edges
  
  ## Graph Mutation Rules
  
  1. **Edge Rewriting**: High entropy → weak edges rewired
  2. **Causal Compression**: Repeated patterns collapse into macro-nodes
  3. **Retrocausal Stitching**: Strong future predictions reweight past edges
  
  ## Data Model
  
      Node: %{
        id: String.t(),
        type: :event | :mutation | :kill | :merge | :law_change,
        world_id: String.t(),
        timestamp: DateTime.t(),
        payload: map(),
        causal_strength: float()
      }
      
      Edge: %{
        from: String.t(),
        to: String.t(),
        weight: float(),
        type: :direct | :inferred | :retrocausal | :speculative,
        stability: float()
      }
  """

  use GenServer
  require Logger

  @type node_id :: String.t()
  @type node_type :: :event | :mutation | :kill | :merge | :law_change

  @type t :: %__MODULE__{
    nodes: %{node_id() => causal_node()},
    edges: %{String.t() => edge()},
    mutation_pressure: float(),
    entropy_alignment: float()
  }

  @type causal_node :: %{
    id: node_id(),
    type: node_type(),
    world_id: String.t(),
    timestamp: DateTime.t(),
    payload: map(),
    causal_strength: float()
  }

  @type edge :: %{
    from: node_id(),
    to: node_id(),
    weight: float(),
    type: :direct | :inferred | :retrocausal | :speculative,
    stability: float()
  }

  defstruct [
    nodes: %{},
    edges: %{},
    mutation_pressure: 0.0,
    entropy_alignment: 0.0
  ]

  # ==================== GenServer API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🕸️  Causality.Graph initialized (mutable ontology engine)")
    {:ok, %__MODULE__{}}
  end

  # ==================== Public API ====================

  @doc """
  Add a causal node to the graph.
  """
  def add_node(node_id, type, world_id, payload, causal_strength \\ 1.0) do
    GenServer.cast(__MODULE__, {:add_node, node_id, type, world_id, payload, causal_strength})
  end

  @doc """
  Create a causal edge between two nodes.
  """
  def add_edge(from_id, to_id, weight \\ 1.0, type \\ :direct) do
    GenServer.cast(__MODULE__, {:add_edge, from_id, to_id, weight, type})
  end

  @doc """
  Mutate the graph based on current entropy pressure.
  
  This triggers:
  - Edge rewiring (weak edges removed/redirected)
  - Pattern compression (repeated sequences → macro-nodes)
  - Retrocausal alignment (future events influence past weights)
  """
  def mutate_graph(entropy_level, world_states) do
    GenServer.call(__MODULE__, {:mutate, entropy_level, world_states})
  end

  @doc """
  Query causal history for a specific world.
  Returns sorted list of nodes and connecting edges.
  """
  def query_world_causality(world_id, max_depth \\ 10) do
    GenServer.call(__MODULE__, {:query_world, world_id, max_depth})
  end

  @doc """
  Get full causal subgraph for visualization.
  """
  def get_subgraph(node_ids) do
    GenServer.call(__MODULE__, {:get_subgraph, node_ids})
  end

  @doc """
  Apply retrocausal stitching - let future events reweight past edges.
  """
  def apply_retrocausal_alignment(future_node_id, past_nodes, prediction_strength) do
    GenServer.cast(__MODULE__, {:retrocausal, future_node_id, past_nodes, prediction_strength})
  end

  @doc """
  Compress repeated causal patterns into macro-nodes.
  """
  def compress_patterns do
    GenServer.cast(__MODULE__, :compress_patterns)
  end

  @doc """
  Get graph statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def handle_cast({:add_node, node_id, type, world_id, payload, causal_strength}, state) do
    node = %{
      id: node_id,
      type: type,
      world_id: world_id,
      timestamp: DateTime.utc_now(),
      payload: payload,
      causal_strength: causal_strength
    }

    updated_nodes = Map.put(state.nodes, node_id, node)
    {:noreply, %{state | nodes: updated_nodes}}
  end

  @impl true
  def handle_cast({:add_edge, from_id, to_id, weight, type}, state) do
    edge_id = "#{from_id}->#{to_id}"
    
    edge = %{
      from: from_id,
      to: to_id,
      weight: weight,
      type: type,
      stability: 1.0
    }

    updated_edges = Map.put(state.edges, edge_id, edge)
    {:noreply, %{state | edges: updated_edges}}
  end

  @impl true
  def handle_cast({:retrocausal, future_node_id, past_nodes, prediction_strength}, state) do
    # Reweight edges from past nodes based on future prediction strength
    updated_edges = Enum.reduce(past_nodes, state.edges, fn past_node_id, edges ->
      edge_id = "#{past_node_id}->#{future_node_id}"
      
      case Map.get(edges, edge_id) do
        nil ->
          # Create new retrocausal edge
          Map.put(edges, edge_id, %{
            from: past_node_id,
            to: future_node_id,
            weight: prediction_strength,
            type: :retrocausal,
            stability: prediction_strength * 0.8
          })
        
        existing_edge ->
          # Strengthen existing edge
          new_weight = min(existing_edge.weight + prediction_strength * 0.3, 1.0)
          Map.put(edges, edge_id, %{existing_edge | weight: new_weight})
      end
    end)

    Logger.debug("🔮 Applied retrocausal alignment: #{length(past_nodes)} past nodes → #{future_node_id}")
    {:noreply, %{state | edges: updated_edges}}
  end

  @impl true
  def handle_cast(:compress_patterns, state) do
    # TODO: Implement pattern detection and macro-node creation
    # This would identify repeated causal sequences (A→B→C→D) and collapse them
    Logger.debug("🗜️  Pattern compression triggered (not yet implemented)")
    {:noreply, state}
  end

  @impl true
  def handle_call({:mutate, entropy_level, _world_states}, _from, state) do
    # Apply entropy-driven mutation to graph
    mutated_state = state
      |> reweight_edges(entropy_level)
      |> prune_weak_edges(entropy_level)
      |> update_mutation_pressure(entropy_level)

    Logger.info("⚡ Graph mutated (entropy: #{entropy_level}, edges_pruned: #{map_size(state.edges) - map_size(mutated_state.edges)})")
    {:reply, {:ok, mutated_state}, mutated_state}
  end

  @impl true
  def handle_call({:query_world, world_id, _max_depth}, _from, state) do
    # Find all nodes for this world
    world_nodes = Enum.filter(state.nodes, fn {_id, node} -> node.world_id == world_id end)
    
    # Get edges connecting these nodes (up to max_depth)
    node_ids = Enum.map(world_nodes, fn {id, _} -> id end)
    relevant_edges = Enum.filter(state.edges, fn {_edge_id, edge} ->
      edge.from in node_ids or edge.to in node_ids
    end)

    result = %{
      nodes: world_nodes,
      edges: relevant_edges,
      total_nodes: length(world_nodes),
      total_edges: length(relevant_edges)
    }

    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:get_subgraph, node_ids}, _from, state) do
    # Extract subgraph containing specified nodes and their connections
    subgraph_nodes = Enum.filter(state.nodes, fn {id, _} -> id in node_ids end)
    
    subgraph_edges = Enum.filter(state.edges, fn {_edge_id, edge} ->
      edge.from in node_ids and edge.to in node_ids
    end)

    {:reply, {:ok, %{nodes: subgraph_nodes, edges: subgraph_edges}}, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_nodes: map_size(state.nodes),
      total_edges: map_size(state.edges),
      mutation_pressure: state.mutation_pressure,
      entropy_alignment: state.entropy_alignment,
      node_types: count_node_types(state.nodes),
      edge_types: count_edge_types(state.edges)
    }

    {:reply, {:ok, stats}, state}
  end

  # ==================== Private Helpers ====================

  defp reweight_edges(state, entropy_level) do
    # High entropy weakens edges (causal uncertainty increases)
    updated_edges = Enum.map(state.edges, fn {edge_id, edge} ->
      new_weight = edge.weight * (1.0 - entropy_level * 0.2)
      new_stability = edge.stability * (1.0 - entropy_level * 0.15)
      
      {edge_id, %{edge | weight: max(new_weight, 0.0), stability: max(new_stability, 0.0)}}
    end)
    |> Enum.into(%{})

    %{state | edges: updated_edges}
  end

  defp prune_weak_edges(state, entropy_level) do
    # Remove edges below stability threshold (higher threshold at high entropy)
    threshold = 0.1 + entropy_level * 0.2
    
    pruned_edges = Enum.filter(state.edges, fn {_edge_id, edge} ->
      edge.stability >= threshold
    end)
    |> Enum.into(%{})

    %{state | edges: pruned_edges}
  end

  defp update_mutation_pressure(state, entropy_level) do
    # Mutation pressure increases with entropy
    new_pressure = min(state.mutation_pressure * 0.9 + entropy_level * 0.3, 1.0)
    %{state | mutation_pressure: new_pressure}
  end

  defp count_node_types(nodes) do
    Enum.reduce(nodes, %{}, fn {_id, node}, acc ->
      Map.update(acc, node.type, 1, &(&1 + 1))
    end)
  end

  defp count_edge_types(edges) do
    Enum.reduce(edges, %{}, fn {_id, edge}, acc ->
      Map.update(acc, edge.type, 1, &(&1 + 1))
    end)
  end
end
