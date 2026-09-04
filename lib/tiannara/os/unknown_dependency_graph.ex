defmodule TiannaraOS.UnknownDependencyGraph do
  @moduledoc """
  Unknown Dependency Graph - Represents unknowns as connected research dependencies.

  Instead of treating unknowns as isolated questions, this graph captures the
  dependency relationships between them, enabling the Research Director to
  prioritize bottlenecks rather than individual questions.

  ## Constitutional Role

  The Unknown Dependency Graph sits within the Unknown Registry and provides
  structural insight into knowledge gaps:

  ```
  Universal Battery (unknown)
      ↓ depends on
  Electrolyte Stability (unknown)
      ↓ depends on
  Material Phase Transition (unknown)
      ↓ depends on
  Atomic Lattice Behaviour (unknown)
      ↓ depends on
  Quantum Transport (unknown)
  ```

  ## Dependency Types

  - :requires - Direct prerequisite (must be resolved first)
  - :influences - Affects but not strictly required
  - :parallel - Can be investigated simultaneously
  - :alternative - Alternative approach to same problem
  - :validates - Confirms or refutes another unknown

  ## Graph Operations

  - Find bottleneck unknowns (high in-degree, blocking many others)
  - Calculate dependency depth (longest chain to resolution)
  - Identify independent subgraphs (parallelizable research)
  - Trace impact propagation (what breaks if this remains unknown)
  - Prioritize by blocking factor (how many unknowns are blocked)

  ## Usage

      {:ok, graph} = UnknownDependencyGraph.initialize()
      {:ok, updated} = UnknownDependencyGraph.add_dependency(graph, :battery, :electrolyte, :requires)
      {:ok, bottlenecks} = UnknownDependencyGraph.find_bottlenecks(graph)
      {:ok, priority_order} = UnknownDependencyGraph.topological_sort(graph)
  """

  use GenServer

  require Logger

  defstruct [
    :nodes,
    :edges,
    :metadata,
    :created_at,
    :last_updated
  ]

  @type t :: %__MODULE__{
    nodes: map(),
    edges: [map()],
    metadata: map(),
    created_at: DateTime.t(),
    last_updated: DateTime.t()
  }

  @type node_id :: atom()
  @type dependency_type :: :requires | :influences | :parallel | :alternative | :validates

  # ==================== Public API ====================

  @doc """
  Start the Unknown Dependency Graph GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Initialize the dependency graph.

  ## Returns
  {:ok, UnknownDependencyGraph.t()}
  """
  def initialize do
    GenServer.call(__MODULE__, :initialize)
  end

  @doc """
  Add an unknown node to the graph.

  ## Parameters
  - `unknown_id`: atom() - unique identifier for the unknown
  - `unknown_data`: map() with :question, :domain_id, :priority, etc.

  ## Returns
  {:ok, UnknownDependencyGraph.t()} | {:error, String.t()}
  """
  def add_node(unknown_id, unknown_data) do
    GenServer.call(__MODULE__, {:add_node, unknown_id, unknown_data})
  end

  @doc """
  Add a dependency edge between two unknowns.

  ## Parameters
  - `from_id`: atom() - source unknown (depends on target)
  - `to_id`: atom() - target unknown (prerequisite)
  - `dependency_type`: atom() - type of dependency

  ## Returns
  {:ok, UnknownDependencyGraph.t()} | {:error, String.t()}
  """
  def add_dependency(from_id, to_id, dependency_type \\ :requires) do
    GenServer.call(__MODULE__, {:add_dependency, from_id, to_id, dependency_type})
  end

  @doc """
  Remove a dependency edge.

  ## Parameters
  - `from_id`: atom()
  - `to_id`: atom()

  ## Returns
  {:ok, UnknownDependencyGraph.t()} | {:error, String.t()}
  """
  def remove_dependency(from_id, to_id) do
    GenServer.call(__MODULE__, {:remove_dependency, from_id, to_id})
  end

  @doc """
  Get all dependencies for an unknown (what it depends on).

  ## Parameters
  - `unknown_id`: atom()

  ## Returns
  {:ok, [dependency_info]}
  """
  def get_dependencies(unknown_id) do
    GenServer.call(__MODULE__, {:get_dependencies, unknown_id})
  end

  @doc """
  Get all dependents of an unknown (what depends on it).

  ## Parameters
  - `unknown_id`: atom()

  ## Returns
  {:ok, [dependent_info]}
  """
  def get_dependents(unknown_id) do
    GenServer.call(__MODULE__, {:get_dependents, unknown_id})
  end

  @doc """
  Find bottleneck unknowns that block the most other unknowns.

  Bottlenecks have:
  - High out-degree (many unknowns depend on them)
  - High blocking factor (resolving them unblocks many others)
  - Critical priority

  ## Returns
  {:ok, [bottleneck_info]}
  """
  def find_bottlenecks do
    GenServer.call(__MODULE__, :find_bottlenecks)
  end

  @doc """
  Calculate topological sort order for resolving unknowns.

  Returns unknowns in dependency order: prerequisites first.

  ## Returns
  {:ok, [ordered_unknown_ids]} | {:error, String.t()} (if cycles detected)
  """
  def topological_sort do
    GenServer.call(__MODULE__, :topological_sort)
  end

  @doc """
  Find independent subgraphs that can be researched in parallel.

  ## Returns
  {:ok, [[unknown_id]]} - list of independent subgraphs
  """
  def find_independent_subgraphs do
    GenServer.call(__MODULE__, :find_independent_subgraphs)
  end

  @doc """
  Calculate dependency depth for an unknown (longest chain to leaf).

  ## Parameters
  - `unknown_id`: atom()

  ## Returns
  {:ok, depth_integer}
  """
  def calculate_dependency_depth(unknown_id) do
    GenServer.call(__MODULE__, {:calculate_dependency_depth, unknown_id})
  end

  @doc """
  Trace impact propagation: what unknowns are affected if this one remains unresolved.

  ## Parameters
  - `unknown_id`: atom()

  ## Returns
  {:ok, impacted_unknowns}
  """
  def trace_impact_propagation(unknown_id) do
    GenServer.call(__MODULE__, {:trace_impact_propagation, unknown_id})
  end

  @doc """
  Get graph statistics.

  ## Returns
  {:ok, statistics_map}
  """
  def get_statistics do
    GenServer.call(__MODULE__, :get_statistics)
  end

  @doc """
  Mark an unknown as resolved and update graph.

  Resolved unknowns are removed from active graph but kept in history.

  ## Parameters
  - `unknown_id`: atom()
  - `resolution_data`: map() with resolution details

  ## Returns
  {:ok, UnknownDependencyGraph.t()}
  """
  def mark_resolved(unknown_id, resolution_data) do
    GenServer.call(__MODULE__, {:mark_resolved, unknown_id, resolution_data})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    state = %{
      graph: nil,
      initialized: false
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:initialize, _from, state) do
    if state.initialized do
      {:reply, {:error, "Graph already initialized"}, state}
    else
      graph = %__MODULE__{
        nodes: %{},
        edges: [],
        metadata: %{
          total_nodes: 0,
          total_edges: 0,
          resolved_count: 0
        },
        created_at: DateTime.utc_now(),
        last_updated: DateTime.utc_now()
      }

      new_state = %{state | graph: graph, initialized: true}
      {:reply, {:ok, graph}, new_state}
    end
  end

  @impl true
  def handle_call({:add_node, unknown_id, unknown_data}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      if Map.has_key?(graph.nodes, unknown_id) do
        {:reply, {:error, "Node already exists: #{inspect(unknown_id)}"}, state}
      else
        node = %{
          id: unknown_id,
          data: unknown_data,
          added_at: DateTime.utc_now(),
          status: :active,
          in_degree: 0,
          out_degree: 0
        }

        nodes = Map.put(graph.nodes, unknown_id, node)
        metadata = %{graph.metadata | total_nodes: graph.metadata.total_nodes + 1}

        updated_graph = %{graph |
          nodes: nodes,
          metadata: metadata,
          last_updated: DateTime.utc_now()
        }

        Logger.debug(fn -> "LifecycleRegistry.track_entity would have been called for :unknown_graph, :node_added, unknown=#{inspect(unknown_id)}" end)

        new_state = %{state | graph: updated_graph}
        {:reply, {:ok, updated_graph}, new_state}
      end
    end
  end

  @impl true
  def handle_call({:add_dependency, from_id, to_id, dependency_type}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      with :ok <- validate_nodes_exist(graph, [from_id, to_id]),
           :ok <- validate_no_cycle(graph, from_id, to_id),
           :ok <- validate_dependency_type(dependency_type) do
        # Check if edge already exists
        existing_edge = Enum.find(graph.edges, fn e ->
          e.from == from_id and e.to == to_id
        end)

        if existing_edge do
          {:reply, {:error, "Dependency already exists"}, state}
        else
          edge = %{
            from: from_id,
            to: to_id,
            type: dependency_type,
            created_at: DateTime.utc_now()
          }

          edges = graph.edges ++ [edge]

          # Update degrees
          nodes = update_node_degrees(graph.nodes, from_id, :out_degree, 1)
          nodes = update_node_degrees(nodes, to_id, :in_degree, 1)

          metadata = %{graph.metadata | total_edges: graph.metadata.total_edges + 1}

          updated_graph = %{graph |
            nodes: nodes,
            edges: edges,
            metadata: metadata,
            last_updated: DateTime.utc_now()
          }

          Logger.debug(fn -> "LifecycleRegistry.track_entity would have been called for :unknown_graph, :dependency_added, from=#{inspect(from_id)}, to=#{inspect(to_id)}" end)

          new_state = %{state | graph: updated_graph}
          {:reply, {:ok, updated_graph}, new_state}
        end
      else
        {:error, reason} -> {:reply, {:error, reason}, state}
      end
    end
  end

  @impl true
  def handle_call({:remove_dependency, from_id, to_id}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      edge_index = Enum.find_index(graph.edges, fn e ->
        e.from == from_id and e.to == to_id
      end)

      if edge_index == nil do
        {:reply, {:error, "Dependency not found"}, state}
      else
        {_edge, remaining_edges} = List.pop_at(graph.edges, edge_index)

        # Update degrees
        nodes = update_node_degrees(graph.nodes, from_id, :out_degree, -1)
        nodes = update_node_degrees(nodes, to_id, :in_degree, -1)

        metadata = %{graph.metadata | total_edges: graph.metadata.total_edges - 1}

        updated_graph = %{graph |
          nodes: nodes,
          edges: remaining_edges,
          metadata: metadata,
          last_updated: DateTime.utc_now()
        }

        new_state = %{state | graph: updated_graph}
        {:reply, {:ok, updated_graph}, new_state}
      end
    end
  end

  @impl true
  def handle_call({:get_dependencies, unknown_id}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      if not Map.has_key?(graph.nodes, unknown_id) do
        {:reply, {:error, "Unknown not found: #{inspect(unknown_id)}"}, state}
      else
        dependencies = Enum.filter(graph.edges, fn e -> e.from == unknown_id end)
        |> Enum.map(fn e ->
          %{
            unknown_id: e.to,
            dependency_type: e.type,
            node_data: Map.get(graph.nodes, e.to)
          }
        end)

        {:reply, {:ok, dependencies}, state}
      end
    end
  end

  @impl true
  def handle_call({:get_dependents, unknown_id}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      if not Map.has_key?(graph.nodes, unknown_id) do
        {:reply, {:error, "Unknown not found: #{inspect(unknown_id)}"}, state}
      else
        dependents = Enum.filter(graph.edges, fn e -> e.to == unknown_id end)
        |> Enum.map(fn e ->
          %{
            unknown_id: e.from,
            dependency_type: e.type,
            node_data: Map.get(graph.nodes, e.from)
          }
        end)

        {:reply, {:ok, dependents}, state}
      end
    end
  end

  @impl true
  def handle_call(:find_bottlenecks, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      bottlenecks = graph.nodes
      |> Map.values()
      |> Enum.filter(fn node -> node.status == :active end)
      |> Enum.map(fn node ->
        dependents_count = Enum.count(graph.edges, fn e -> e.to == node.id end)
        blocking_factor = count_blocked_unknowns(graph, node.id)

        %{
          unknown_id: node.id,
          question: node.data.question,
          domain: node.data.domain_id,
          priority: node.data.priority,
          in_degree: node.in_degree,
          out_degree: node.out_degree,
          dependents_count: dependents_count,
          blocking_factor: blocking_factor,
          bottleneck_score: calculate_bottleneck_score(node, dependents_count, blocking_factor)
        }
      end)
      |> Enum.sort_by(& &1.bottleneck_score, :desc)
      |> Enum.take(10)  # Top 10 bottlenecks

      {:reply, {:ok, bottlenecks}, state}
    end
  end

  @impl true
  def handle_call(:topological_sort, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      case perform_topological_sort(graph) do
        {:ok, sorted_ids} -> {:reply, {:ok, sorted_ids}, state}
        {:error, reason} -> {:reply, {:error, reason}, state}
      end
    end
  end

  @impl true
  def handle_call(:find_independent_subgraphs, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      subgraphs = find_connected_components(graph)

      {:reply, {:ok, subgraphs}, state}
    end
  end

  @impl true
  def handle_call({:calculate_dependency_depth, unknown_id}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      if not Map.has_key?(graph.nodes, unknown_id) do
        {:reply, {:error, "Unknown not found: #{inspect(unknown_id)}"}, state}
      else
        depth = calculate_depth_recursive(graph, unknown_id, %{})
        {:reply, {:ok, depth}, state}
      end
    end
  end

  @impl true
  def handle_call({:trace_impact_propagation, unknown_id}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      if not Map.has_key?(graph.nodes, unknown_id) do
        {:reply, {:error, "Unknown not found: #{inspect(unknown_id)}"}, state}
      else
        impacted = traverse_dependents(graph, unknown_id, MapSet.new())
        |> MapSet.to_list()

        {:reply, {:ok, impacted}, state}
      end
    end
  end

  @impl true
  def handle_call(:get_statistics, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      active_nodes = Enum.count(graph.nodes, fn {_id, node} -> node.status == :active end)
      resolved_nodes = Enum.count(graph.nodes, fn {_id, node} -> node.status == :resolved end)

      avg_in_degree = if active_nodes > 0 do
        total_in = Enum.sum(Enum.map(graph.nodes, fn {_id, node} -> node.in_degree end))
        Float.round(total_in / active_nodes, 2)
      else
        0.0
      end

      avg_out_degree = if active_nodes > 0 do
        total_out = Enum.sum(Enum.map(graph.nodes, fn {_id, node} -> node.out_degree end))
        Float.round(total_out / active_nodes, 2)
      else
        0.0
      end

      max_depth = graph.nodes
      |> Map.keys()
      |> Enum.map(fn id ->
        case calculate_depth_recursive(graph, id, %{}) do
          depth when is_integer(depth) -> depth
          _ -> 0
        end
      end)
      |> Enum.max(fn -> 0 end)

      statistics = %{
        total_nodes: graph.metadata.total_nodes,
        active_nodes: active_nodes,
        resolved_nodes: resolved_nodes,
        total_edges: graph.metadata.total_edges,
        average_in_degree: avg_in_degree,
        average_out_degree: avg_out_degree,
        maximum_dependency_depth: max_depth,
        graph_density: if(active_nodes > 1, do: Float.round(graph.metadata.total_edges / (active_nodes * (active_nodes - 1)), 4), else: 0),
        last_updated: graph.last_updated
      }

      {:reply, {:ok, statistics}, state}
    end
  end

  @impl true
  def handle_call({:mark_resolved, unknown_id, _resolution_data}, _from, state) do
    if not state.initialized do
      {:reply, {:error, "Graph not initialized"}, state}
    else
      graph = state.graph

      if not Map.has_key?(graph.nodes, unknown_id) do
        {:reply, {:error, "Unknown not found: #{inspect(unknown_id)}"}, state}
      else
        # Mark node as resolved
        node = Map.get(graph.nodes, unknown_id)
        updated_node = %{node | status: :resolved}

        nodes = Map.put(graph.nodes, unknown_id, updated_node)

        # Remove edges involving this node
        edges = Enum.reject(graph.edges, fn e ->
          e.from == unknown_id or e.to == unknown_id
        end)

        metadata = %{graph.metadata | resolved_count: graph.metadata.resolved_count + 1}

        updated_graph = %{graph |
          nodes: nodes,
          edges: edges,
          metadata: metadata,
          last_updated: DateTime.utc_now()
        }

        Logger.debug(fn -> "LifecycleRegistry.track_entity would have been called for :unknown_graph, :unknown_resolved, unknown=#{inspect(unknown_id)}" end)

        new_state = %{state | graph: updated_graph}
        {:reply, {:ok, updated_graph}, new_state}
      end
    end
  end

  # ==================== Private Functions ====================

  defp validate_nodes_exist(graph, node_ids) do
    missing = Enum.filter(node_ids, fn id ->
      not Map.has_key?(graph.nodes, id)
    end)

    if length(missing) > 0 do
      {:error, "Nodes not found: #{inspect(missing)}"}
    else
      :ok
    end
  end

  defp validate_no_cycle(graph, from_id, to_id) do
    # Check if adding this edge would create a cycle
    # Simple check: see if to_id can reach from_id through existing edges
    if can_reach?(graph, to_id, from_id, MapSet.new()) do
      {:error, "Adding this dependency would create a cycle"}
    else
      :ok
    end
  end

  defp can_reach?(graph, current_id, target_id, visited) do
    if current_id == target_id do
      true
    else
      visited = MapSet.put(visited, current_id)

      neighbors = graph.edges
      |> Enum.filter(fn e -> e.from == current_id end)
      |> Enum.map(fn e -> e.to end)

      Enum.any?(neighbors, fn neighbor ->
        not MapSet.member?(visited, neighbor) and can_reach?(graph, neighbor, target_id, visited)
      end)
    end
  end

  defp validate_dependency_type(type) do
    valid_types = [:requires, :influences, :parallel, :alternative, :validates]

    if type in valid_types do
      :ok
    else
      {:error, "Invalid dependency type: #{inspect(type)}. Must be one of: #{inspect(valid_types)}"}
    end
  end

  defp update_node_degrees(nodes, node_id, degree_field, delta) do
    case Map.get(nodes, node_id) do
      nil -> nodes
      node ->
        current = Map.get(node, degree_field, 0)
        updated_node = Map.put(node, degree_field, max(0, current + delta))
        Map.put(nodes, node_id, updated_node)
    end
  end

  defp count_blocked_unknowns(graph, unknown_id) do
    # Count how many unknowns are transitively blocked by this one
    blocked = traverse_dependents(graph, unknown_id, MapSet.new())
    MapSet.size(blocked)
  end

  defp traverse_dependents(graph, unknown_id, visited) do
    visited = MapSet.put(visited, unknown_id)

    dependents = graph.edges
    |> Enum.filter(fn e -> e.to == unknown_id end)
    |> Enum.map(fn e -> e.from end)

    Enum.reduce(dependents, visited, fn dependent_id, acc ->
      if not MapSet.member?(acc, dependent_id) do
        traverse_dependents(graph, dependent_id, acc)
      else
        acc
      end
    end)
  end

  defp calculate_bottleneck_score(node, dependents_count, blocking_factor) do
    # Priority weight
    priority_weight = case node.data.priority do
      :critical -> 4
      :high -> 3
      :medium -> 2
      :low -> 1
      _ -> 1
    end

    # Score formula: blocking_factor * priority_weight * (1 + log(dependents_count + 1))
    :math.log(dependents_count + 1) * priority_weight * (blocking_factor + 1)
    |> Float.round(2)
  end

  defp perform_topological_sort(graph) do
    # Kahn's algorithm for topological sorting
    active_nodes = graph.nodes
    |> Map.values()
    |> Enum.filter(fn node -> node.status == :active end)
    |> Enum.map(fn node -> node.id end)

    # Calculate in-degrees
    in_degrees = Enum.reduce(active_nodes, %{}, fn id, acc ->
      in_count = Enum.count(graph.edges, fn e -> e.to == id end)
      Map.put(acc, id, in_count)
    end)

    # Start with nodes that have no incoming edges
    queue = in_degrees
    |> Enum.filter(fn {_id, degree} -> degree == 0 end)
    |> Enum.map(fn {id, _degree} -> id end)

    sorted = []
    process_topological_sort(graph, active_nodes, in_degrees, queue, sorted)
  end

  defp process_topological_sort(_graph, _active_nodes, _in_degrees, [], sorted) do
    {:ok, Enum.reverse(sorted)}
  end

  defp process_topological_sort(graph, active_nodes, in_degrees, queue, sorted) do
    [current | rest_queue] = queue

    # Add to sorted list
    sorted = [current | sorted]

    # Find neighbors (nodes that current points to)
    neighbors = graph.edges
    |> Enum.filter(fn e -> e.from == current end)
    |> Enum.map(fn e -> e.to end)
    |> Enum.filter(fn id -> id in active_nodes end)

    # Update in-degrees and add newly available nodes to queue
    {new_in_degrees, new_queue} = Enum.reduce(neighbors, {in_degrees, rest_queue}, fn neighbor, {degrees, q} ->
      new_degree = Map.get(degrees, neighbor, 0) - 1
      degrees = Map.put(degrees, neighbor, new_degree)

      if new_degree == 0 do
        {degrees, q ++ [neighbor]}
      else
        {degrees, q}
      end
    end)

    process_topological_sort(graph, active_nodes, new_in_degrees, new_queue, sorted)
  end

  defp find_connected_components(graph) do
    active_nodes = graph.nodes
    |> Map.keys()
    |> Enum.filter(fn id ->
      case Map.get(graph.nodes, id) do
        nil -> false
        node -> node.status == :active
      end
    end)

    visited = MapSet.new()

    Enum.reduce(active_nodes, {visited, []}, fn node_id, {vis, components} ->
      if not MapSet.member?(vis, node_id) do
        # BFS to find connected component
        {new_visited, component} = bfs_component(graph, node_id, vis)
        {new_visited, [component | components]}
      else
        {vis, components}
      end
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp bfs_component(graph, start_id, visited) do
    queue = [start_id]
    visited = MapSet.put(visited, start_id)
    component = [start_id]

    bfs_traverse(graph, queue, visited, component)
  end

  defp bfs_traverse(_graph, [], visited, component) do
    {visited, Enum.reverse(component)}
  end

  defp bfs_traverse(graph, [current | rest_queue], visited, component) do
    # Find neighbors (both directions)
    neighbors = graph.edges
    |> Enum.filter(fn e -> e.from == current or e.to == current end)
    |> Enum.flat_map(fn e ->
      if e.from == current do
        [e.to]
      else
        [e.from]
      end
    end)
    |> Enum.uniq()

    {new_queue, new_visited, new_component} = Enum.reduce(neighbors, {rest_queue, visited, component}, fn neighbor, {q, vis, comp} ->
      if not MapSet.member?(vis, neighbor) do
        new_vis = MapSet.put(vis, neighbor)
        new_comp = [neighbor | comp]
        {q ++ [neighbor], new_vis, new_comp}
      else
        {q, vis, comp}
      end
    end)

    bfs_traverse(graph, new_queue, new_visited, new_component)
  end

  defp calculate_depth_recursive(graph, unknown_id, memo) do
    case Map.get(memo, unknown_id) do
      depth when is_integer(depth) -> depth
      _ ->
        dependencies = graph.edges
        |> Enum.filter(fn e -> e.from == unknown_id end)
        |> Enum.map(fn e -> e.to end)

        if length(dependencies) == 0 do
          0
        else
          max_dep_depth = Enum.map(dependencies, fn dep_id ->
            calculate_depth_recursive(graph, dep_id, memo)
          end)
          |> Enum.max(fn -> 0 end)

          depth = 1 + max_dep_depth
          depth
        end
    end
  end
end
