defmodule Tiannara.ASC.Implementation.ComponentGraph do
  @moduledoc """
  Component Graph — dependency graph of implementation components.

  Represents the structural relationships between components,
  including calls, message passing, and data flow dependencies.

  Enhanced with:
  - Critical path analysis
  - Bottleneck detection
  - Fan-in/fan-out metrics
  """

  @derive Jason.Encoder
  defstruct [
    nodes: [],          # List of component names
    edges: [],          # List of %Edge{} structs
    critical_paths: [], # Paths with highest dependency depth
    bottlenecks: [],    # Components with high fan-in
    fan_in: %{},        # Map: component -> incoming dependency count
    fan_out: %{},       # Map: component -> outgoing dependency count
    complexity: 0.0
  ]

  @type t :: %__MODULE__{
    nodes: [String.t()],
    edges: [Edge.t()],
    critical_paths: [[String.t()]],
    bottlenecks: [String.t()],
    fan_in: %{String.t() => non_neg_integer()},
    fan_out: %{String.t() => non_neg_integer()},
    complexity: float()
  }

  defmodule Edge do
    @moduledoc "A directed edge in the component graph"
    @derive Jason.Encoder
    defstruct [
      from: nil,
      to: nil,
      type: :calls  # :calls, :publishes_to, :subscribes_to, :depends_on
    ]

    @type t :: %__MODULE__{
      from: String.t() | nil,
      to: String.t() | nil,
      type: atom()
    }
  end

  @doc """
  Build a component graph from an ImplementationPlan.
  """
  def build(%Tiannara.ASC.Implementation.Plan{} = plan) do
    nodes = Enum.map(plan.components, & &1.name)

    edges = Enum.flat_map(plan.dependencies, fn dep ->
      [%Edge{
        from: dep.from,
        to: dep.to,
        type: dep.type
      }]
    end)

    fan_in = calculate_fan_in(nodes, edges)
    fan_out = calculate_fan_out(nodes, edges)
    bottlenecks = find_bottlenecks(fan_in)
    critical_paths = find_critical_paths(nodes, edges)
    complexity = calculate_complexity(nodes, edges)

    %__MODULE__{
      nodes: nodes,
      edges: edges,
      critical_paths: critical_paths,
      bottlenecks: bottlenecks,
      fan_in: fan_in,
      fan_out: fan_out,
      complexity: complexity
    }
  end

  @doc """
  Calculate fan-in for each node (number of incoming edges).
  """
  def calculate_fan_in(nodes, edges) do
    initial = Map.new(nodes, fn node -> {node, 0} end)

    Enum.reduce(edges, initial, fn edge, acc ->
      Map.update(acc, edge.to, 1, &(&1 + 1))
    end)
  end

  @doc """
  Calculate fan-out for each node (number of outgoing edges).
  """
  def calculate_fan_out(nodes, edges) do
    initial = Map.new(nodes, fn node -> {node, 0} end)

    Enum.reduce(edges, initial, fn edge, acc ->
      Map.update(acc, edge.from, 1, &(&1 + 1))
    end)
  end

  @doc """
  Find bottleneck components (high fan-in, typically >2).
  """
  def find_bottlenecks(fan_in) do
    fan_in
    |> Enum.filter(fn {_node, count} -> count > 2 end)
    |> Enum.map(fn {node, _count} -> node end)
  end

  @doc """
  Find critical paths (longest dependency chains).
  """
  def find_critical_paths(nodes, edges) do
    adjacency = build_adjacency_list(edges)

    # Find all paths using DFS from each root node
    roots = find_root_nodes(nodes, edges)

    paths = Enum.flat_map(roots, fn root ->
      find_all_paths_from(root, adjacency, [])
    end)

    # Return top 3 longest paths
    paths
    |> Enum.sort_by(&length/1, :desc)
    |> Enum.take(3)
  end

  defp find_root_nodes(nodes, edges) do
    targets = MapSet.new(Enum.map(edges, & &1.to))
    Enum.filter(nodes, fn node -> not MapSet.member?(targets, node) end)
  end

  defp find_all_paths_from(node, adjacency, visited) do
    if Enum.member?(visited, node) do
      []
    else
      neighbors = Map.get(adjacency, node, [])

      if neighbors == [] do
        [[node]]
      else
        new_visited = [node | visited]

        Enum.flat_map(neighbors, fn neighbor ->
          sub_paths = find_all_paths_from(neighbor, adjacency, new_visited)
          Enum.map(sub_paths, fn path -> [node | path] end)
        end)
      end
    end
  end

  @doc """
  Calculate graph complexity using cyclomatic complexity approximation.
  """
  def calculate_complexity(nodes, edges) do
    node_count = length(nodes)
    edge_count = length(edges)

    # Simple formula: E - N + 2 (cyclomatic complexity for connected graphs)
    # Normalized to 0-10 scale
    raw_complexity = max(0, edge_count - node_count + 2)
    normalized = min(10.0, raw_complexity / 2.0)

    Float.round(normalized, 2)
  end

  defp build_adjacency_list(edges) do
    Enum.reduce(edges, %{}, fn edge, acc ->
      Map.update(acc, edge.from, [edge.to], &[edge.to | &1])
    end)
  end

  @doc """
  Detect circular dependencies in the graph.
  Returns list of cycles found (empty if no cycles).
  """
  def detect_cycles(%__MODULE__{} = graph) do
    adjacency = build_adjacency_list(graph.edges)
    visited = MapSet.new()
    rec_stack = MapSet.new()

    Enum.reduce(graph.nodes, [], fn node, cycles ->
      case dfs(node, adjacency, visited, rec_stack, []) do
        {:cycle, cycle} -> [cycle | cycles]
        _ -> cycles
      end
    end)
  end

  defp dfs(node, adjacency, visited, rec_stack, path) do
    cond do
      MapSet.member?(rec_stack, node) ->
        {:cycle, Enum.reverse([node | path])}

      MapSet.member?(visited, node) ->
        :ok

      true ->
        visited = MapSet.put(visited, node)
        rec_stack = MapSet.put(rec_stack, node)
        path = [node | path]

        neighbors = Map.get(adjacency, node, [])

        result = Enum.reduce_while(neighbors, :ok, fn neighbor, _acc ->
          case dfs(neighbor, adjacency, visited, rec_stack, path) do
            {:cycle, cycle} -> {:halt, {:cycle, cycle}}
            _ -> {:cont, :ok}
          end
        end)

        rec_stack = MapSet.delete(rec_stack, node)
        result
    end
  end

  @doc """
  Find all paths from source to target component.
  """
  def find_all_paths(%__MODULE__{} = graph, source, target) do
    adjacency = build_adjacency_list(graph.edges)
    find_paths(source, target, adjacency, [], [])
  end

  defp find_paths(current, target, adjacency, path, all_paths) do
    new_path = [current | path]

    cond do
      current == target ->
        [Enum.reverse(new_path) | all_paths]

      true ->
        neighbors = Map.get(adjacency, current, [])

        Enum.reduce(neighbors, all_paths, fn neighbor, acc ->
          unless Enum.member?(path, neighbor) do
            find_paths(neighbor, target, adjacency, new_path, acc)
          else
            acc
          end
        end)
    end
  end
end
