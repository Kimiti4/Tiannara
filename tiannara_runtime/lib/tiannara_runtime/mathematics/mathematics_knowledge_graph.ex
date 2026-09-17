defmodule TiannaraRuntime.Mathematics.MathematicsKnowledgeGraph do
  @moduledoc """
  Phase 16.X.2 — Mathematical Knowledge Graph (MKG)

  Stores mathematical knowledge as a deterministic, content-addressed,
  replayable, archaeologically explainable, independently auditable graph.
  Represents the structure of mathematics itself — not scientific evidence.

  Constitutional separation: MKG answers "How is mathematics structurally
  connected?" while the Scientific Knowledge Graph answers "Why do we
  believe something?" The two graphs remain permanently separated.

  Node types (12): AxiomNode, DefinitionNode, StructureNode, LemmaNode,
    ConjectureNode, ProofNode, TheoremNode, CorollaryNode, CounterexampleNode,
    AlgorithmNode, ApplicationNode, MathematicalAssertionNode

  Edge types (10): DEFINES, DEPENDS_ON, PROVES, REFINES, GENERALIZES,
    SPECIALIZES, DERIVES, USES, APPLIES_TO, SUPERSEDES

  Every node carries immutable metadata: id, hash, owner, origin, purpose,
  domain, dependencies, lineage, created_at, version.

  Deterministic traversal: topological ordering → content hash ordering →
  canonical node identifier. Never depends on insertion order.

  Graph root: SHA-256 fingerprint of all nodes and edges.
  """

  @node_table :math_kg_nodes
  @edge_table :math_kg_edges

  @valid_node_types ~w(
    AxiomNode DefinitionNode StructureNode LemmaNode ConjectureNode
    ProofNode TheoremNode CorollaryNode CounterexampleNode
    AlgorithmNode ApplicationNode MathematicalAssertionNode
  )

  @valid_edge_types ~w(
    DEFINES DEPENDS_ON PROVES REFINES GENERALIZES
    SPECIALIZES DERIVES USES APPLIES_TO SUPERSEDES
  )

  # ---------------------------------------------------------------------------
  # ETS Initialization
  # ---------------------------------------------------------------------------

  @doc "Create or retrieve ETS tables for the mathematical knowledge graph."
  @spec init_tables() :: :ok
  def init_tables do
    if :ets.info(@node_table) == :undefined do
      :ets.new(@node_table, [:set, :public, :named_table])
    end
    if :ets.info(@edge_table) == :undefined do
      :ets.new(@edge_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Destroy and recreate both ETS tables (for test isolation)."
  @spec reset_tables() :: :ok
  def reset_tables do
    for table <- [@node_table, @edge_table] do
      if :ets.info(table) != :undefined, do: :ets.delete(table)
    end
    init_tables()
  end

  # ---------------------------------------------------------------------------
  # Node Operations
  # ---------------------------------------------------------------------------

  @doc """
  Add a node to the MKG.

  Automatically populates immutable metadata:
    - id: content-addressed node_id
    - hash: SHA-256 of canonical node content
    - owner: constitutional owner
    - origin: phase of creation
    - purpose: why the node exists
    - domain: mathematical sub-domain
    - dependencies: references to depended-upon node IDs
    - lineage: provenance chain
    - created_at: epoch timestamp
    - version: artifact version
  """
  @spec add_node(String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def add_node(node_type, metadata \\ %{}) when is_binary(node_type) do
    with :ok <- validate_node_type(node_type) do
      enriched = enrich_metadata(node_type, metadata)
      node_id = compute_node_id(node_type, enriched)
      content_hash = compute_content_hash(node_type, enriched)
      now = :erlang.unique_integer([:positive]) |> Integer.to_string()

      node = %{
        "node_id" => node_id,
        "hash" => content_hash,
        "node_type" => node_type,
        "owner" => Map.get(enriched, "owner", "Constitutional Research Council"),
        "origin" => Map.get(enriched, "origin", "Phase 16.X.2"),
        "purpose" => Map.get(enriched, "purpose", "mathematical_knowledge_graph"),
        "domain" => Map.get(enriched, "domain", "general"),
        "dependencies" => Map.get(enriched, "dependencies", []),
        "lineage" => Map.get(enriched, "lineage", []),
        "created_at" => now,
        "version" => Map.get(enriched, "version", "1.0.0"),
        "metadata" => enriched
      }

      :ets.insert(@node_table, {node_id, node})
      {:ok, node_id}
    end
  end

  @doc "Get a node by its content-addressed ID."
  @spec get_node(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_node(node_id) when is_binary(node_id) do
    case :ets.lookup(@node_table, node_id) do
      [{^node_id, node}] -> {:ok, node}
      [] -> {:error, "node not found: #{node_id}"}
    end
  end

  @doc "Query nodes by type. Results sorted deterministically by content hash."
  @spec query_nodes(String.t()) :: {:ok, [map()]}
  def query_nodes(node_type) when is_binary(node_type) do
    nodes =
      @node_table
      |> :ets.tab2list()
      |> Enum.map(fn {_id, node} -> node end)
      |> Enum.filter(fn node -> Map.get(node, "node_type") == node_type end)
      |> Enum.sort_by(fn node -> Map.get(node, "node_id") end)

    {:ok, nodes}
  end

  @doc "List all nodes in the graph, sorted by content hash."
  @spec list_all_nodes() :: {:ok, [map()]}
  def list_all_nodes do
    nodes =
      @node_table
      |> :ets.tab2list()
      |> Enum.map(fn {_id, node} -> node end)
      |> Enum.sort_by(fn node -> Map.get(node, "node_id") end)

    {:ok, nodes}
  end

  @doc "Count nodes by type."
  @spec count_nodes() :: {:ok, map()}
  def count_nodes do
    {:ok, nodes} = list_all_nodes()
    counts =
      Enum.reduce(nodes, %{}, fn node, acc ->
        type = Map.get(node, "node_type")
        Map.update(acc, type, 1, &(&1 + 1))
      end)

    {:ok, counts}
  end

  # ---------------------------------------------------------------------------
  # Edge Operations
  # ---------------------------------------------------------------------------

  @doc "Add a directed edge between two nodes with one of the 10 constitutional edge types."
  @spec add_edge(String.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def add_edge(from_id, to_id, edge_type)
      when is_binary(from_id) and is_binary(to_id) and is_binary(edge_type) do
    with :ok <- validate_edge_type(edge_type),
         {:ok, _} <- get_node(from_id),
         {:ok, _} <- get_node(to_id) do
      edge_id = compute_edge_id(from_id, to_id, edge_type)

      case :ets.lookup(@edge_table, edge_id) do
        [{^edge_id, _edge}] ->
          {:error, "edge already exists: #{edge_id}"}

        [] ->
          edge = %{
            "edge_id" => edge_id,
            "from" => from_id,
            "to" => to_id,
            "edge_type" => edge_type
          }

          :ets.insert(@edge_table, {edge_id, edge})
          {:ok, edge_id}
      end
    end
  end

  @doc "Query edges by type. Results sorted deterministically."
  @spec query_edges(String.t()) :: {:ok, [map()]}
  def query_edges(edge_type) when is_binary(edge_type) do
    edges =
      @edge_table
      |> :ets.tab2list()
      |> Enum.map(fn {_id, edge} -> edge end)
      |> Enum.filter(fn edge -> Map.get(edge, "edge_type") == edge_type end)
      |> Enum.sort_by(fn edge -> Map.get(edge, "edge_id") end)

    {:ok, edges}
  end

  @doc "List all edges, sorted deterministically."
  @spec list_all_edges() :: {:ok, [map()]}
  def list_all_edges do
    edges =
      @edge_table
      |> :ets.tab2list()
      |> Enum.map(fn {_id, edge} -> edge end)
      |> Enum.sort_by(fn edge -> Map.get(edge, "edge_id") end)

    {:ok, edges}
  end

  # ---------------------------------------------------------------------------
  # Deterministic Traversal
  # ---------------------------------------------------------------------------

  @doc """
  Traverse outgoing edges from a node.

  Ordering (never depends on insertion order):
    1. Topological ordering (minimal depth-first finishing order)
    2. Content hash ordering
    3. Canonical node identifier
  """
  @spec traverse(String.t(), String.t() | nil) :: {:ok, [map()]} | {:error, String.t()}
  def traverse(node_id, edge_type \\ nil) when is_binary(node_id) do
    with {:ok, _} <- get_node(node_id) do
      edges =
        @edge_table
        |> :ets.tab2list()
        |> Enum.map(fn {_id, edge} -> edge end)
        |> Enum.filter(fn edge -> Map.get(edge, "from") == node_id end)
        |> then(fn es ->
          if edge_type, do: Enum.filter(es, fn e -> Map.get(e, "edge_type") == edge_type end), else: es
        end)

      neighbor_ids =
        edges
        |> Enum.map(fn edge -> Map.get(edge, "to") end)
        |> Enum.uniq()

      {:ok, all_nodes} = list_all_nodes()
      all_node_ids = Enum.map(all_nodes, fn n -> Map.get(n, "node_id") end)

      topo_order = topological_order(all_node_ids, build_adjacency())

      neighbor_ids_sorted =
        neighbor_ids
        |> Enum.sort_by(fn nid ->
          topo_idx = Enum.find_index(topo_order, fn t -> t == nid end)
          {topo_idx || 999_999, nid}
        end)

      neighbors =
        neighbor_ids_sorted
        |> Enum.map(fn neighbor_id ->
          case :ets.lookup(@node_table, neighbor_id) do
            [{^neighbor_id, node}] -> node
            [] -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      {:ok, neighbors}
    end
  end

  @doc "Follow reverse edges (incoming) to a node. Uses topological ordering."
  @spec traverse_reverse(String.t(), String.t() | nil) :: {:ok, [map()]}
  def traverse_reverse(node_id, edge_type \\ nil) when is_binary(node_id) do
    edges =
      @edge_table
      |> :ets.tab2list()
      |> Enum.map(fn {_id, edge} -> edge end)
      |> Enum.filter(fn edge -> Map.get(edge, "to") == node_id end)
      |> then(fn es ->
        if edge_type, do: Enum.filter(es, fn e -> Map.get(e, "edge_type") == edge_type end), else: es
      end)

    neighbor_ids =
      edges
      |> Enum.map(fn edge -> Map.get(edge, "from") end)
      |> Enum.uniq()

    {:ok, all_nodes} = list_all_nodes()
    all_node_ids = Enum.map(all_nodes, fn n -> Map.get(n, "node_id") end)
    topo_order = topological_order(all_node_ids, build_adjacency())

    neighbor_ids_sorted =
      neighbor_ids
      |> Enum.sort_by(fn nid ->
        topo_idx = Enum.find_index(topo_order, fn t -> t == nid end)
        {topo_idx || 999_999, nid}
      end)

    neighbors =
      neighbor_ids_sorted
      |> Enum.map(fn neighbor_id ->
        case :ets.lookup(@node_table, neighbor_id) do
          [{^neighbor_id, node}] -> node
          [] -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, neighbors}
  end

  @doc "Get the dependency chain for a node (transitive closure of DEPENDS_ON edges)."
  @spec dependencies(String.t()) :: {:ok, [map()]} | {:error, String.t()}
  def dependencies(node_id) when is_binary(node_id) do
    with {:ok, _} <- get_node(node_id) do
      {:ok, transitive_deps(node_id, MapSet.new())}
    end
  end

  # ---------------------------------------------------------------------------
  # Topological Sort
  # ---------------------------------------------------------------------------

  defp topological_order(node_ids, adjacency) do
    visited = MapSet.new()
    order = []

    {_visited, order} =
      Enum.reduce(node_ids, {visited, order}, fn nid, {vis, ord} ->
        if MapSet.member?(vis, nid) do
          {vis, ord}
        else
          topo_dfs(nid, adjacency, vis, ord)
        end
      end)

    order |> Enum.reverse()
  end

  defp topo_dfs(node_id, adjacency, visited, order) do
    visited = MapSet.put(visited, node_id)
    neighbors = Map.get(adjacency, node_id, [])

    {visited, order} =
      Enum.reduce(neighbors, {visited, order}, fn neighbor, {vis, ord} ->
        if MapSet.member?(vis, neighbor) do
          {vis, ord}
        else
          topo_dfs(neighbor, adjacency, vis, ord)
        end
      end)

    {visited, [node_id | order]}
  end

  defp build_adjacency do
    edges =
      @edge_table
      |> :ets.tab2list()
      |> Enum.map(fn {_id, edge} -> edge end)

    Enum.reduce(edges, %{}, fn e, acc ->
      from = Map.get(e, "from")
      to = Map.get(e, "to")
      Map.update(acc, from, [to], fn existing -> [to | existing] end)
    end)
  end

  # ---------------------------------------------------------------------------
  # Graph Root Fingerprint
  # ---------------------------------------------------------------------------

  @doc """
  Compute the deterministic graph root SHA-256 fingerprint.

  Fingerprint covers all nodes (sorted by ID) and all edges (sorted by ID)
  in canonical JSON form. Replay must reconstruct identical graph roots.
  """
  @spec graph_root() :: String.t()
  def graph_root do
    {:ok, all_nodes} = list_all_nodes()
    {:ok, all_edges} = list_all_edges()

    nodes_canonical =
      all_nodes
      |> Enum.map(fn n -> strip_internal(n) end)
      |> Enum.sort_by(fn n -> Map.get(n, "node_id") end)

    edges_canonical =
      all_edges
      |> Enum.sort_by(fn e -> Map.get(e, "edge_id") end)

    fingerprint_input = %{
      "graph_type" => "mathematical_knowledge_graph",
      "phase" => "16.X.2",
      "node_count" => length(all_nodes),
      "edge_count" => length(all_edges),
      "nodes" => nodes_canonical,
      "edges" => edges_canonical
    }

    TiannaraRuntime.Mathematics.MathematicalID.from_canonical_map(fingerprint_input)
  end

  # ---------------------------------------------------------------------------
  # Replay
  # ---------------------------------------------------------------------------

  @doc """
  Reconstruct a deterministic node ID from its type and inputs.

  Uses only: ontology, graph artifacts, deterministic context.
  No runtime cache, no mutable graph.
  """
  @spec replay_node(String.t(), map()) :: String.t()
  def replay_node(node_type, inputs) when is_binary(node_type) and is_map(inputs) do
    enriched = enrich_metadata(node_type, inputs)
    compute_node_id(node_type, enriched)
  end

  @doc """
  Replay the full graph root from a list of node and edge specs.

  Replay reconstructs the graph using only:
    - ontology (node types, edge types)
    - graph artifacts (node specs, edge specs)
    - deterministic context (canonical ordering)

  Returns the graph root fingerprint.
  """
  @spec replay_graph([map()], [map()]) :: String.t()
  def replay_graph(node_specs, edge_specs) do
    reset_tables()

    for spec <- Enum.sort_by(node_specs, fn s -> Map.get(s, "node_type") <> inspect(Map.get(s, "metadata")) end) do
      add_node(Map.get(spec, "node_type"), Map.get(spec, "metadata", %{}))
    end

    for spec <- Enum.sort_by(edge_specs, fn s ->
           Map.get(s, "from", "") <> Map.get(s, "to", "") <> Map.get(s, "edge_type", "")
         end) do
      add_edge(Map.get(spec, "from"), Map.get(spec, "to"), Map.get(spec, "edge_type"))
    end

    graph_root()
  end

  # ---------------------------------------------------------------------------
  # Archaeology
  # ---------------------------------------------------------------------------

  @doc """
  Return the full archaeology provenance for a node.

  Every node answers:
    - Why was it created? (purpose, origin phase)
    - Which theorem produced it? (lineage references)
    - Which conjecture required it? (lineage traces)
    - Which definitions were necessary? (dependencies)
    - Which structures depend upon it? (reverse DEPENDS_ON traversal)
    - Which applications consume it? (APPLIES_TO traversal)
  """
  @spec archaeology(String.t()) :: {:ok, map()} | {:error, String.t()}
  def archaeology(node_id) when is_binary(node_id) do
    with {:ok, node} <- get_node(node_id) do
      {:ok, reverse_deps} = traverse_reverse(node_id, "DEPENDS_ON")

      {:ok, necessary_defs} = dependencies(node_id)
      {:ok, forward_consumers} = traverse(node_id, "APPLIES_TO")

      provenance = %{
        "node_id" => node_id,
        "node_type" => Map.get(node, "node_type"),
        "created_why" => %{
          "origin" => Map.get(node, "origin"),
          "purpose" => Map.get(node, "purpose"),
          "domain" => Map.get(node, "domain")
        },
        "produced_by_theorem" => Map.get(node, "lineage", []),
        "required_by_conjecture" => find_conjecture_lineage(node_id),
        "necessary_definitions" => Enum.map(necessary_defs, fn n -> Map.get(n, "node_id") end),
        "dependent_structures" => Enum.map(reverse_deps, fn n -> Map.get(n, "node_id") end),
        "consumed_by_applications" => Enum.map(forward_consumers, fn n -> Map.get(n, "node_id") end),
        "owner" => Map.get(node, "owner"),
        "version" => Map.get(node, "version"),
        "created_at" => Map.get(node, "created_at")
      }

      {:ok, provenance}
    end
  end

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  @doc "Validate graph integrity: no orphan edges, no unknown node/edge types."
  @spec validate_graph() :: {:ok, map()} | {:error, map()}
  def validate_graph do
    {:ok, all_nodes} = list_all_nodes()
    {:ok, all_edges} = list_all_edges()
    node_ids = MapSet.new(all_nodes, fn n -> Map.get(n, "node_id") end)

    orphan_edges =
      Enum.filter(all_edges, fn e ->
        not MapSet.member?(node_ids, Map.get(e, "from")) or
          not MapSet.member?(node_ids, Map.get(e, "to"))
      end)

    invalid_node_types =
      all_nodes
      |> Enum.map(fn n -> Map.get(n, "node_type") end)
      |> Enum.reject(&(&1 in @valid_node_types))

    invalid_edge_types =
      all_edges
      |> Enum.map(fn e -> Map.get(e, "edge_type") end)
      |> Enum.reject(&(&1 in @valid_edge_types))

    fingerprint = graph_root()

    issues = %{
      "orphan_edges" => length(orphan_edges),
      "invalid_node_types" => invalid_node_types,
      "invalid_edge_types" => invalid_edge_types,
      "total_nodes" => length(all_nodes),
      "total_edges" => length(all_edges),
      "graph_root" => fingerprint
    }

    if length(orphan_edges) == 0 and invalid_node_types == [] and invalid_edge_types == [] do
      {:ok, issues}
    else
      {:error, issues}
    end
  end

  @doc "Detect cycles in the dependency graph. Returns cycle paths if found."
  @spec detect_cycles() :: {:ok, :no_cycles} | {:error, [String.t()]}
  def detect_cycles do
    {:ok, all_nodes} = list_all_nodes()
    node_ids = Enum.map(all_nodes, fn n -> Map.get(n, "node_id") end)

    {:ok, all_edges} = query_edges("DEPENDS_ON")

    adjacency =
      Enum.reduce(all_edges, %{}, fn e, acc ->
        from = Map.get(e, "from")
        to = Map.get(e, "to")
        Map.update(acc, from, [to], fn existing -> [to | existing] end)
      end)

    cycles = find_cycles(node_ids, adjacency)

    if cycles == [] do
      {:ok, :no_cycles}
    else
      {:error, cycles}
    end
  end

  # ---------------------------------------------------------------------------
  # Valid Node/Edge Types
  # ---------------------------------------------------------------------------

  @doc "Returns all 12 valid node types."
  @spec valid_node_types() :: [String.t()]
  def valid_node_types, do: @valid_node_types

  @doc "Returns all 10 valid edge types."
  @spec valid_edge_types() :: [String.t()]
  def valid_edge_types, do: @valid_edge_types

  # ---------------------------------------------------------------------------
  # Internal
  # ---------------------------------------------------------------------------

  defp validate_node_type(type) when type in @valid_node_types, do: :ok

  defp validate_node_type(type),
    do: {:error, "invalid node type: #{type}. Valid: #{inspect(@valid_node_types)}"}

  defp validate_edge_type(type) when type in @valid_edge_types, do: :ok

  defp validate_edge_type(type),
    do: {:error, "invalid edge type: #{type}. Valid: #{inspect(@valid_edge_types)}"}

  defp compute_node_id(node_type, enriched) do
    "node_" <>
      TiannaraRuntime.Mathematics.MathematicalID.from_canonical_map(%{
        "node_type" => node_type,
        "content" => enriched
      })
  end

  defp compute_content_hash(node_type, enriched) do
    TiannaraRuntime.Mathematics.MathematicalID.from_canonical_map(%{
      "node_type" => node_type,
      "content" => enriched
    })
  end

  defp compute_edge_id(from_id, to_id, edge_type) do
    "edge_#{from_id}_#{to_id}_#{edge_type}"
  end

  defp enrich_metadata(node_type, metadata) do
    defaults = %{
      "owner" => "Constitutional Research Council",
      "origin" => "Phase 16.X.2",
      "purpose" => node_type_description(node_type),
      "domain" => "general",
      "dependencies" => [],
      "lineage" => [],
      "version" => "1.0.0"
    }

    Map.merge(defaults, metadata)
  end

  defp node_type_description("AxiomNode"), do: "foundational starting assumption"
  defp node_type_description("DefinitionNode"), do: "concept definition"
  defp node_type_description("StructureNode"), do: "algebraic/geometric/topological structure"
  defp node_type_description("LemmaNode"), do: "helper theorem used in proof"
  defp node_type_description("ConjectureNode"), do: "unproven mathematical statement"
  defp node_type_description("ProofNode"), do: "step-by-step derivation establishing truth"
  defp node_type_description("TheoremNode"), do: "proven mathematical statement"
  defp node_type_description("CorollaryNode"), do: "direct consequence of a theorem"
  defp node_type_description("CounterexampleNode"), do: "witness to a violated property"
  defp node_type_description("AlgorithmNode"), do: "computational procedure proven correct"
  defp node_type_description("ApplicationNode"), do: "real-world/domain-specific application of mathematics"
  defp node_type_description("MathematicalAssertionNode"), do: "verification result artifact"

  defp strip_internal(node) do
    node
    |> Map.drop(["node_id", "hash", "created_at"])
  end

  defp find_conjecture_lineage(node_id) do
    case traverse_reverse(node_id, "PROVES") do
      {:ok, provers} ->
        conjecture_ids =
          provers
          |> Enum.filter(fn n -> Map.get(n, "node_type") == "ConjectureNode" end)
          |> Enum.map(fn n -> Map.get(n, "node_id") end)

        if conjecture_ids == [], do: [], else: conjecture_ids

      {:error, _} ->
        []
    end
  end

  defp transitive_deps(node_id, seen) do
    if MapSet.member?(seen, node_id) do
      []
    else
      seen = MapSet.put(seen, node_id)

      edges =
        @edge_table
        |> :ets.tab2list()
        |> Enum.map(fn {_id, edge} -> edge end)
        |> Enum.filter(fn e ->
          Map.get(e, "from") == node_id and Map.get(e, "edge_type") == "DEPENDS_ON"
        end)

      direct_deps =
        edges
        |> Enum.map(fn e -> Map.get(e, "to") end)
        |> Enum.map(fn dep_id ->
          case :ets.lookup(@node_table, dep_id) do
            [{^dep_id, node}] -> node
            [] -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      indirect =
        Enum.flat_map(direct_deps, fn dep ->
          transitive_deps(Map.get(dep, "node_id"), seen)
        end)

      direct_deps ++ indirect
    end
  end

  defp find_cycles(node_ids, adjacency) do
    visited = MapSet.new()
    rec_stack = MapSet.new()

    {_, _, cycles} =
      Enum.reduce(node_ids, {visited, rec_stack, []}, fn node_id, {vis, rec, cyc} ->
        if MapSet.member?(vis, node_id) do
          {vis, rec, cyc}
        else
          {vis2, rec2, sub} = find_cycles_dfs(node_id, adjacency, vis, rec, [])
          {vis2, rec2, cyc ++ sub}
        end
      end)

    cycles
  end

  defp find_cycles_dfs(node_id, adjacency, visited, rec_stack, path) do
    visited = MapSet.put(visited, node_id)
    rec_stack = MapSet.put(rec_stack, node_id)
    new_path = path ++ [node_id]

    neighbors = Map.get(adjacency, node_id, [])

    {_visited, _rec_stack, cycles} =
      Enum.reduce(neighbors, {visited, rec_stack, []}, fn neighbor, {vis, rec, cyc} ->
        if not MapSet.member?(vis, neighbor) do
          {vis2, rec2, sub_cycles} = find_cycles_dfs(neighbor, adjacency, vis, rec, new_path)
          {vis2, rec2, cyc ++ sub_cycles}
        else
          if MapSet.member?(rec, neighbor) do
            cycle_path = (new_path ++ [neighbor]) |> Enum.join(" -> ")
            {vis, rec, cyc ++ [cycle_path]}
          else
            {vis, rec, cyc}
          end
        end
      end)

    rec_stack = MapSet.delete(rec_stack, node_id)
    {visited, rec_stack, cycles}
  end
end
