defmodule TiannaraOS.Governance.InstitutionGraph do
  @moduledoc """
  InstitutionGraph - Tracks relationships between governance institutions, roles, appointments, and capabilities.
  
  This graph enables archaeology traversal to answer questions like:
  - "Why was this institution created?"
  - "Which role has authority over this capability?"
  - "What is the lineage of this appointment?"
  
  ## Graph Structure
  
  Nodes:
  - Institutions (e.g., Governance Council, Review Board)
  - Roles (e.g., Architect, Auditor, Deployer)
  - Appointments (specific person-in-role assignments)
  - Capabilities (authorized actions)
  
  Edges (10 relationship types):
  - :created_by - Institution created by proposal/role
  - :appointed_by - Appointment made by role/institution
  - :granted_to - Capability granted to role/appointment
  - :reviews - Institution reviews proposals/deployments
  - :deploys - Institution executes deployments
  - :ratifies - Institution ratifies amendments
  - :oversees - Institution oversees another institution
  - :depends_on - Institution depends on another institution
  - :inherits_from - Role inherits capabilities from parent role
  - :replaced_by - Institution/role replaced by new version
  
  ## API
  
      graph = InstitutionGraph.init_standard_graph()
      graph = InstitutionGraph.add_node(graph, :institution, "Governance Council")
      graph = InstitutionGraph.add_edge(graph, :created_by, "Governance Council", "Proposal #42")
      
      # Traverse relationships
      parents = InstitutionGraph.get_parents(graph, "Review Board")
      children = InstitutionGraph.get_children(graph, "Architect")
      lineage = InstitutionGraph.get_lineage(graph, "Appointment-7")
  """

  use GenServer

  @type node_type :: :institution | :role | :appointment | :capability
  @type edge_type :: :created_by | :appointed_by | :granted_to | :reviews | :deploys |
                     :ratifies | :oversees | :depends_on | :inherits_from | :replaced_by

  @type t :: %__MODULE__{
          nodes: map(),
          edges: list(),
          metadata: map()
        }

  defstruct [:nodes, :edges, :metadata]

  @spec init_standard_graph() :: t()
  def init_standard_graph() do
    %__MODULE__{
      nodes: %{
        institutions: MapSet.new([
          "Governance Council",
          "Review Board",
          "Deployment Authority",
          "Observatory",
          "Scientific Governance Board"
        ]),
        roles: MapSet.new([
          "Architect",
          "Auditor",
          "Deployer",
          "Reviewer",
          "Observer",
          "Scientific Governor"
        ]),
        appointments: MapSet.new(),
        capabilities: MapSet.new([
          "propose_amendment",
          "review_proposal",
          "simulate_proposal",
          "ratify_amendment",
          "deploy_migration",
          "rollback_deployment",
          "observe_governance",
          "audit_compliance",
          "appoint_role",
          "revoke_appointment"
        ])
      },
      edges: [
        # Standard relationships
        {:created_by, "Governance Council", "Constitution"},
        {:created_by, "Review Board", "Governance Council"},
        {:created_by, "Deployment Authority", "Governance Council"},
        {:created_by, "Observatory", "Constitution"},
        {:created_by, "Scientific Governance Board", "Constitution"},

        {:reviews, "Review Board", "proposals"},
        {:deploys, "Deployment Authority", "migrations"},
        {:ratifies, "Governance Council", "amendments"},
        {:observes, "Observatory", "governance"},
        {:oversees, "Scientific Governance Board", "research"},

        {:inherits_from, "Auditor", "Observer"},
        {:inherits_from, "Deployer", "Architect"}
      ],
      metadata: %{
        initialized_at: DateTime.utc_now(),
        total_nodes: 20,
        total_edges: 13,
        version: "1.0.0"
      }
    }
  end

  @spec add_node(t(), node_type(), String.t()) :: t()
  def add_node(%__MODULE__{} = graph, type, node_id) do
    updated_nodes = Map.update!(graph.nodes, type, fn nodes ->
      MapSet.put(nodes, node_id)
    end)

    updated_metadata = Map.update!(graph.metadata, :total_nodes, &(&1 + 1))

    %__MODULE__{
      graph
      | nodes: updated_nodes,
        metadata: updated_metadata
    }
  end

  @spec add_edge(t(), edge_type(), String.t(), String.t()) :: t()
  def add_edge(%__MODULE__{} = graph, edge_type, from_node, to_node) do
    updated_edges = graph.edges ++ [{edge_type, from_node, to_node}]
    updated_metadata = Map.update!(graph.metadata, :total_edges, &(&1 + 1))

    %__MODULE__{
      graph
      | edges: updated_edges,
        metadata: updated_metadata
    }
  end

  @spec get_parents(t(), String.t()) :: list()
  def get_parents(%__MODULE__{} = graph, node_id) do
    graph.edges
    |> Enum.filter(fn {_type, _from, to} -> to == node_id end)
    |> Enum.map(fn {type, from, _to} -> {type, from} end)
  end

  @spec get_children(t(), String.t()) :: list()
  def get_children(%__MODULE__{} = graph, node_id) do
    graph.edges
    |> Enum.filter(fn {_type, from, _to} -> from == node_id end)
    |> Enum.map(fn {type, _from, to} -> {type, to} end)
  end

  @spec get_lineage(t(), String.t()) :: list()
  def get_lineage(%__MODULE__{} = graph, node_id) do
    traverse_ancestors(graph, node_id, [])
  end

  defp traverse_ancestors(_graph, _node_id, visited) when length(visited) > 50 do
    # Prevent infinite loops
    visited
  end

  defp traverse_ancestors(graph, node_id, visited) do
    parents = get_parents(graph, node_id)

    if Enum.empty?(parents) do
      Enum.reverse(visited)
    else
      new_visited = [{node_id, parents} | visited]

      parents
      |> Enum.map(fn {_type, parent_id} -> parent_id end)
      |> Enum.reduce(new_visited, fn parent_id, acc ->
        traverse_ancestors(graph, parent_id, acc)
      end)
      |> List.flatten()
      |> Enum.uniq()
    end
  end

  @spec get_relationship_history(t(), String.t()) :: list()
  def get_relationship_history(%__MODULE__{} = graph, node_id) do
    incoming = get_parents(graph, node_id)
    outgoing = get_children(graph, node_id)

    %{
      node_id: node_id,
      incoming_relationships: incoming,
      outgoing_relationships: outgoing,
      total_connections: length(incoming) + length(outgoing)
    }
  end

  @spec find_path(t(), String.t(), String.t()) :: list() | nil
  def find_path(%__MODULE__{} = graph, from_node, to_node) do
    bfs_search(graph, from_node, to_node, [])
  end

  defp bfs_search(_graph, current, target, path) when current == target do
    Enum.reverse([current | path])
  end

  defp bfs_search(graph, current, target, visited) do
    if current in visited do
      nil
    else
      new_visited = [current | visited]

      children = get_children(graph, current)
      |> Enum.map(fn {_type, child_id} -> child_id end)

      Enum.find_value(children, nil, fn child_id ->
        bfs_search(graph, child_id, target, new_visited)
      end)
    end
  end

  @spec get_nodes_by_type(t(), node_type()) :: MapSet.t()
  def get_nodes_by_type(%__MODULE__{} = graph, type) do
    Map.get(graph.nodes, type, MapSet.new())
  end

  @spec get_edges_by_type(t(), edge_type()) :: list()
  def get_edges_by_type(%__MODULE__{} = graph, edge_type) do
    graph.edges
    |> Enum.filter(fn {type, _from, _to} -> type == edge_type end)
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = graph) do
    %{
      nodes: %{
        institutions: MapSet.to_list(graph.nodes.institutions),
        roles: MapSet.to_list(graph.nodes.roles),
        appointments: MapSet.to_list(graph.nodes.appointments),
        capabilities: MapSet.to_list(graph.nodes.capabilities)
      },
      edges: graph.edges,
      metadata: graph.metadata
    }
  end

  @spec get_stats(t()) :: map()
  def get_stats(%__MODULE__{} = graph) do
    %{
      total_institutions: MapSet.size(graph.nodes.institutions),
      total_roles: MapSet.size(graph.nodes.roles),
      total_appointments: MapSet.size(graph.nodes.appointments),
      total_capabilities: MapSet.size(graph.nodes.capabilities),
      total_edges: length(graph.edges),
      edge_types: graph.edges
      |> Enum.map(fn {type, _from, _to} -> type end)
      |> Enum.uniq()
      |> length()
    }
  end

  @spec verify_integrity(t()) :: {:ok, map()} | {:error, String.t()}
  def verify_integrity(%__MODULE__{} = graph) do
    # Check for orphaned nodes
    all_node_ids = get_all_node_ids(graph)
    referenced_nodes = get_referenced_nodes(graph)

    orphans = MapSet.difference(all_node_ids, referenced_nodes)

    if MapSet.size(orphans) > 0 do
      {:error, "Found #{MapSet.size(orphans)} orphaned nodes: #{inspect(MapSet.to_list(orphans))}"}
    else
      {:ok, %{
        total_nodes: MapSet.size(all_node_ids),
        total_edges: length(graph.edges),
        orphans: 0,
        integrity: :valid
      }}
    end
  end

  defp get_all_node_ids(%__MODULE__{} = graph) do
    MapSet.union(
      MapSet.union(graph.nodes.institutions, graph.nodes.roles),
      MapSet.union(graph.nodes.appointments, graph.nodes.capabilities)
    )
  end

  defp get_referenced_nodes(%__MODULE__{} = graph) do
    graph.edges
    |> Enum.flat_map(fn {_type, from, to} -> [from, to] end)
    |> MapSet.new()
  end

  # GenServer callbacks for persistent storage (future implementation)
  @impl true
  def init(_opts) do
    {:ok, init_standard_graph()}
  end

  @impl true
  def handle_call(:get_graph, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:add_node, type, node_id}, state) do
    {:noreply, add_node(state, type, node_id)}
  end

  @impl true
  def handle_cast({:add_edge, edge_type, from, to}, state) do
    {:noreply, add_edge(state, edge_type, from, to)}
  end
end
