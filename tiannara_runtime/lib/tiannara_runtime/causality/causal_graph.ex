defmodule TiannaraRuntime.Causality.CausalGraph do
  @moduledoc """
  PHASE 4C.2: Causal Graph Builder
  
  Constructs and maintains a directed graph of causal relationships between events.
  
  Graph Structure:
    Nodes = Events (CAL decisions, CIS interventions, coalition changes)
    Edges = Causal relationships (event A caused/influenced event B)
  
  This enables full decision lineage reconstruction and cognitive forensics.
  
  Usage:
    # Add event node
    CausalGraph.add_node(event_id, event_type, metadata)
    
    # Add causal edge
    CausalGraph.add_edge(source_id, target_id, relationship_type)
    
    # Query graph
    {:ok, subgraph} = CausalGraph.get_causal_chain(event_id)
  """
  
  use GenServer
  require Logger
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Add an event node to the causal graph.
  """
  def add_node(event_id, event_type, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:add_node, event_id, event_type, metadata})
  end
  
  @doc """
  Add a causal edge between two events.
  
  Relationship types:
    - "caused_by": Direct causation
    - "influenced_by": Indirect influence
    - "intervened_by": CIS intervention
    - "arbitrated_by": CAL arbitration decision
  """
  def add_edge(source_id, target_id, relationship_type) do
    GenServer.cast(__MODULE__, {:add_edge, source_id, target_id, relationship_type})
  end
  
  @doc """
  Get full causal chain for an event (ancestors + descendants).
  
  Returns: {:ok, %{nodes: [...], edges: [...]}}
  """
  def get_causal_chain(event_id, max_depth \\ 10) do
    GenServer.call(__MODULE__, {:get_causal_chain, event_id, max_depth})
  end
  
  @doc """
  Get ancestors only (what led to this event).
  
  Returns: {:ok, [node]} ordered from root to event
  """
  def get_ancestors(event_id, max_depth \\ 10) do
    GenServer.call(__MODULE__, {:get_ancestors, event_id, max_depth})
  end
  
  @doc """
  Get descendants only (what resulted from this event).
  
  Returns: {:ok, [node]} ordered by BFS traversal
  """
  def get_descendants(event_id, max_depth \\ 10) do
    GenServer.call(__MODULE__, {:get_descendants, event_id, max_depth})
  end
  
  @doc """
  Get all CIS interventions affecting an event.
  
  Returns: {:ok, [intervention_node]}
  """
  def get_interventions(event_id) do
    GenServer.call(__MODULE__, {:get_interventions, event_id})
  end
  
  @doc """
  Get all CAL decisions influencing an event.
  
  Returns: {:ok, [decision_node]}
  """
  def get_cal_decisions(event_id) do
    GenServer.call(__MODULE__, {:get_cal_decisions, event_id})
  end
  
  @doc """
  Get graph statistics.
  
  Returns: %{node_count, edge_count, root_count, leaf_count}
  """
  def get_stats() do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  # Server Implementation
  
  @impl true
  def init(_opts) do
    state = %{
      nodes: %{},     # event_id -> node_data
      edges: [],      # [{source, target, relationship}]
      adjacency: %{   # event_id -> {incoming: [...], outgoing: [...]}
        # incoming: [{source_id, relationship}]
        # outgoing: [{target_id, relationship}]
      }
    }
    
    Logger.info("🕸️ Causal Graph initialized")
    
    {:ok, state}
  end
  
  @impl true
  def handle_cast({:add_node, event_id, event_type, metadata}, state) do
    node_data = %{
      id: event_id,
      type: event_type,
      metadata: metadata,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    new_nodes = Map.put(state.nodes, event_id, node_data)
    
    # Initialize adjacency if not exists
    new_adjacency = Map.put_new(state.adjacency, event_id, %{
      incoming: [],
      outgoing: []
    })
    
    Logger.debug("🕸️ Added node: #{event_id} (#{event_type})")
    
    {:ok, %{state | nodes: new_nodes, adjacency: new_adjacency}}
  end
  
  @impl true
  def handle_cast({:add_edge, source_id, target_id, relationship}, state) do
    # Validate nodes exist
    if Map.has_key?(state.nodes, source_id) and Map.has_key?(state.nodes, target_id) do
      # Add edge
      new_edges = [{source_id, target_id, relationship} | state.edges]
      
      # Update adjacency
      new_adjacency = state.adjacency
        |> update_in([source_id, :outgoing], fn list -> [{target_id, relationship} | list] end)
        |> update_in([target_id, :incoming], fn list -> [{source_id, relationship} | list] end)
      
      Logger.debug("🕸️ Added edge: #{source_id} → #{target_id} (#{relationship})")
      
      {:ok, %{state | edges: new_edges, adjacency: new_adjacency}}
    else
      Logger.warning("⚠️ Cannot add edge: missing node(s)")
      {:ok, state}
    end
  end
  
  @impl true
  def handle_call({:get_causal_chain, event_id, max_depth}, _from, state) do
    ancestors = get_ancestors_recursive(event_id, state, max_depth, [], MapSet.new())
    descendants = get_descendants_bfs(event_id, state, max_depth)
    
    # Combine and deduplicate
    all_nodes = MapSet.union(
      MapSet.new(ancestors, fn n -> n.id end),
      MapSet.new(descendants, fn n -> n.id end)
    )
    |> MapSet.put(event_id)
    
    # Get relevant edges
    relevant_edges = Enum.filter(state.edges, fn {src, tgt, _rel} ->
      MapSet.member?(all_nodes, src) and MapSet.member?(all_nodes, tgt)
    end)
    
    # Build node list
    node_list = Enum.map(all_nodes, fn id ->
      Map.get(state.nodes, id)
    end)
    |> Enum.filter(& &1)
    
    result = %{
      nodes: node_list,
      edges: relevant_edges,
      center_event: event_id
    }
    
    {:reply, {:ok, result}, state}
  end
  
  @impl true
  def handle_call({:get_ancestors, event_id, max_depth}, _from, state) do
    ancestors = get_ancestors_recursive(event_id, state, max_depth, [], MapSet.new())
    {:reply, {:ok, ancestors}, state}
  end
  
  @impl true
  def handle_call({:get_descendants, event_id, max_depth}, _from, state) do
    descendants = get_descendants_bfs(event_id, state, max_depth)
    {:reply, {:ok, descendants}, state}
  end
  
  @impl true
  def handle_call({:get_interventions, event_id}, _from, state) do
    # Find all CIS intervention nodes that have edges to this event
    interventions = find_related_by_type(event_id, state, "cis_intervention", "incoming")
    {:reply, {:ok, interventions}, state}
  end
  
  @impl true
  def handle_call({:get_cal_decisions, event_id}, _from, state) do
    # Find all CAL decision nodes that have edges to this event
    decisions = find_related_by_type(event_id, state, "cal_decision", "incoming")
    {:reply, {:ok, decisions}, state}
  end
  
  @impl true
  def handle_call(:get_stats, _from, state) do
    root_count = count_roots(state)
    leaf_count = count_leaves(state)
    
    stats = %{
      node_count: map_size(state.nodes),
      edge_count: length(state.edges),
      root_count: root_count,
      leaf_count: leaf_count
    }
    
    {:reply, {:ok, stats}, state}
  end
  
  # Private Functions
  
  defp get_ancestors_recursive(event_id, state, depth, acc, visited) do
    if depth <= 0 or MapSet.member?(visited, event_id) do
      Enum.reverse(acc)
    else
      case Map.get(state.nodes, event_id) do
        nil ->
          Enum.reverse(acc)
        
        node ->
          new_visited = MapSet.put(visited, event_id)
          
          # Get incoming edges
          incoming = get_in(state.adjacency, [event_id, :incoming]) || []
          
          # Recursively get ancestors of parents
          Enum.reduce(incoming, acc, fn {parent_id, _relationship}, current_acc ->
            get_ancestors_recursive(parent_id, state, depth - 1, current_acc, new_visited)
          end)
          |> then(fn result ->
            if MapSet.member?(visited, event_id) do
              result
            else
              [node | result]
            end
          end)
      end
    end
  end
  
  defp get_descendants_bfs(event_id, state, max_depth) do
    queue = [{event_id, 0}]
    visited = MapSet.new([event_id])
    
    bfs_traverse(queue, visited, state, max_depth, [])
  end
  
  defp bfs_traverse([], _visited, _state, _max_depth, acc) do
    Enum.reverse(acc)
  end
  
  defp bfs_traverse([{current_id, depth} | rest], visited, state, max_depth, acc) do
    if depth >= max_depth do
      bfs_traverse(rest, visited, state, max_depth, acc)
    else
      case Map.get(state.nodes, current_id) do
        nil ->
          bfs_traverse(rest, visited, state, max_depth, acc)
        
        node ->
          # Get outgoing edges
          outgoing = get_in(state.adjacency, [current_id, :outgoing]) || []
          
          # Add unvisited children to queue
          {new_queue, new_visited} = Enum.reduce(outgoing, {rest, visited}, fn {child_id, _rel}, {q, v} ->
            if not MapSet.member?(v, child_id) do
              {[{child_id, depth + 1} | q], MapSet.put(v, child_id)}
            else
              {q, v}
            end
          end)
          
          bfs_traverse(new_queue, new_visited, state, max_depth, [node | acc])
      end
    end
  end
  
  defp find_related_by_type(event_id, state, target_type, direction) do
    neighbors = case direction do
      "incoming" ->
        get_in(state.adjacency, [event_id, :incoming]) || []
      "outgoing" ->
        get_in(state.adjacency, [event_id, :outgoing]) || []
    end
    
    Enum.flat_map(neighbors, fn {neighbor_id, _relationship} ->
      case Map.get(state.nodes, neighbor_id) do
        nil -> []
        node ->
          if node.type == target_type do
            [node]
          else
            []
          end
      end
    end)
  end
  
  defp count_roots(state) do
    Enum.count(state.adjacency, fn {_id, adj} ->
      length(adj.incoming) == 0
    end)
  end
  
  defp count_leaves(state) do
    Enum.count(state.adjacency, fn {_id, adj} ->
      length(adj.outgoing) == 0
    end)
  end
end
