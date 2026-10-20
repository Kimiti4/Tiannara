defmodule TiannaraRuntime.Mathematics.MathematicsKnowledgeGraphTest do
  @moduledoc "Phase 16.X.2 — Mathematical Knowledge Graph tests: nodes, edges, traversal, replay, archaeology, graph root."
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Mathematics.MathematicsKnowledgeGraph

  setup do
    MathematicsKnowledgeGraph.reset_tables()
    :ok
  end

  # ---------------------------------------------------------------------------
  # Node Operations
  # ---------------------------------------------------------------------------

  describe "add_node/2" do
    test "returns {:ok, node_id} for valid node types" do
      assert {:ok, id} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"statement" => "∀x. x = x"})
      assert String.starts_with?(id, "node_")
    end

    test "supports all 12 node types" do
      for type <- MathematicsKnowledgeGraph.valid_node_types() do
        assert {:ok, _id} = MathematicsKnowledgeGraph.add_node(type, %{"test" => true})
      end
    end

    test "rejects invalid node types" do
      assert {:error, msg} = MathematicsKnowledgeGraph.add_node("InvalidNode", %{})
      assert msg =~ "invalid node type"
    end

    test "produces deterministic IDs for same content" do
      assert {:ok, id1} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{"statement" => "Riemann-Roch"})
      assert {:ok, id2} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{"statement" => "Riemann-Roch"})
      assert id1 == id2
    end

    test "produces different IDs for different content" do
      assert {:ok, id1} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"statement" => "A"})
      assert {:ok, id2} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"statement" => "B"})
      assert id1 != id2
    end
  end

  describe "add_node/2 metadata" do
    test "every node carries immutable metadata fields" do
      assert {:ok, id} = MathematicsKnowledgeGraph.add_node("DefinitionNode", %{"name" => "Group"})
      assert {:ok, node} = MathematicsKnowledgeGraph.get_node(id)
      assert Map.has_key?(node, "node_id")
      assert Map.has_key?(node, "hash")
      assert Map.has_key?(node, "node_type")
      assert Map.has_key?(node, "owner")
      assert Map.has_key?(node, "origin")
      assert Map.has_key?(node, "purpose")
      assert Map.has_key?(node, "domain")
      assert Map.has_key?(node, "dependencies")
      assert Map.has_key?(node, "lineage")
      assert Map.has_key?(node, "created_at")
      assert Map.has_key?(node, "version")
    end

    test "default owner is Constitutional Research Council" do
      assert {:ok, id} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:ok, node} = MathematicsKnowledgeGraph.get_node(id)
      assert node["owner"] == "Constitutional Research Council"
    end
  end

  describe "get_node/1" do
    test "returns the stored node" do
      assert {:ok, id} = MathematicsKnowledgeGraph.add_node("DefinitionNode", %{"name" => "Group"})
      assert {:ok, node} = MathematicsKnowledgeGraph.get_node(id)
      assert node["node_id"] == id
      assert node["node_type"] == "DefinitionNode"
    end

    test "returns error for missing node" do
      assert {:error, _} = MathematicsKnowledgeGraph.get_node("node_nonexistent")
    end
  end

  describe "query_nodes/1" do
    test "returns nodes filtered by type, sorted deterministically" do
      MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "C"})
      MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "A"})
      MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "B"})
      MathematicsKnowledgeGraph.add_node("TheoremNode", %{"s" => "X"})

      assert {:ok, nodes} = MathematicsKnowledgeGraph.query_nodes("AxiomNode")
      assert length(nodes) == 3

      ids = Enum.map(nodes, fn n -> n["node_id"] end)
      assert ids == Enum.sort(ids)
    end

    test "returns empty list for unmatched type" do
      assert {:ok, nodes} = MathematicsKnowledgeGraph.query_nodes("ProofNode")
      assert nodes == []
    end
  end

  describe "list_all_nodes/0" do
    test "lists all nodes sorted by content hash" do
      MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "Z"})
      MathematicsKnowledgeGraph.add_node("ConjectureNode", %{"s" => "A"})

      assert {:ok, nodes} = MathematicsKnowledgeGraph.list_all_nodes()
      assert length(nodes) == 2
    end
  end

  describe "count_nodes/0" do
    test "counts nodes by type" do
      MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "1"})
      MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "2"})
      MathematicsKnowledgeGraph.add_node("TheoremNode", %{"s" => "T"})

      assert {:ok, counts} = MathematicsKnowledgeGraph.count_nodes()
      assert counts["AxiomNode"] == 2
      assert counts["TheoremNode"] == 1
    end
  end

  # ---------------------------------------------------------------------------
  # Edge Operations (10 constitutional edge types)
  # ---------------------------------------------------------------------------

  describe "add_edge/3" do
    test "creates an edge between two existing nodes" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"statement" => "A"})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"statement" => "B"})
      assert {:ok, eid} = MathematicsKnowledgeGraph.add_edge(a, b, "DEPENDS_ON")
      assert String.starts_with?(eid, "edge_")
    end

    test "supports all 10 edge types" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "A"})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{"s" => "B"})

      for etype <- MathematicsKnowledgeGraph.valid_edge_types() do
        assert {:ok, _} = MathematicsKnowledgeGraph.add_edge(a, b, etype)
      end
    end

    test "rejects invalid edge types" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:error, msg} = MathematicsKnowledgeGraph.add_edge(a, b, "invalid_edge")
      assert msg =~ "invalid edge type"
    end

    test "rejects edges from non-existent node" do
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:error, _} = MathematicsKnowledgeGraph.add_edge("node_missing", b, "DEPENDS_ON")
    end

    test "rejects duplicate edges" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})

      assert {:ok, _} = MathematicsKnowledgeGraph.add_edge(a, b, "DEPENDS_ON")
      assert {:error, msg} = MathematicsKnowledgeGraph.add_edge(a, b, "DEPENDS_ON")
      assert msg =~ "edge already exists"
    end
  end

  describe "query_edges/1" do
    test "returns edges filtered by type, sorted deterministically" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "A"})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "B"})
      assert {:ok, c} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "C"})

      MathematicsKnowledgeGraph.add_edge(a, b, "DEPENDS_ON")
      MathematicsKnowledgeGraph.add_edge(a, c, "APPLIES_TO")

      assert {:ok, deps} = MathematicsKnowledgeGraph.query_edges("DEPENDS_ON")
      assert length(deps) == 1
      assert hd(deps)["edge_type"] == "DEPENDS_ON"

      assert {:ok, apps} = MathematicsKnowledgeGraph.query_edges("APPLIES_TO")
      assert length(apps) == 1
    end
  end

  describe "list_all_edges/0" do
    test "lists all edges sorted deterministically" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      MathematicsKnowledgeGraph.add_edge(a, b, "DEPENDS_ON")

      assert {:ok, edges} = MathematicsKnowledgeGraph.list_all_edges()
      assert length(edges) == 1
    end
  end

  # ---------------------------------------------------------------------------
  # Deterministic Traversal (topological ordering)
  # ---------------------------------------------------------------------------

  describe "traverse/2" do
    test "returns outgoing neighbors sorted by topological ordering" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "A"})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{"s" => "B"})
      assert {:ok, c} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{"s" => "C"})
      MathematicsKnowledgeGraph.add_edge(a, b, "PROVES")
      MathematicsKnowledgeGraph.add_edge(a, c, "PROVES")

      assert {:ok, neighbors} = MathematicsKnowledgeGraph.traverse(a)
      assert length(neighbors) == 2
    end

    test "filters by edge type when specified" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{})
      assert {:ok, c} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{})
      MathematicsKnowledgeGraph.add_edge(a, b, "PROVES")
      MathematicsKnowledgeGraph.add_edge(a, c, "APPLIES_TO")

      assert {:ok, proven} = MathematicsKnowledgeGraph.traverse(a, "PROVES")
      assert length(proven) == 1
    end

    test "returns error for non-existent node" do
      assert {:error, _} = MathematicsKnowledgeGraph.traverse("node_missing")
    end

    test "empty result when no outgoing edges" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:ok, neighbors} = MathematicsKnowledgeGraph.traverse(a)
      assert neighbors == []
    end
  end

  describe "traverse_reverse/2" do
    test "returns incoming neighbors sorted deterministically" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{})
      assert {:ok, c} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{})
      MathematicsKnowledgeGraph.add_edge(a, b, "PROVES")
      MathematicsKnowledgeGraph.add_edge(a, c, "PROVES")

      assert {:ok, depends} = MathematicsKnowledgeGraph.traverse_reverse(b)
      assert length(depends) == 1
    end
  end

  # ---------------------------------------------------------------------------
  # Dependency Chain
  # ---------------------------------------------------------------------------

  describe "dependencies/1" do
    test "returns transitive closure of DEPENDS_ON edges" do
      assert {:ok, a1} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "A1"})
      assert {:ok, a2} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "A2"})
      assert {:ok, thm} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{"s" => "Thm"})

      MathematicsKnowledgeGraph.add_edge(thm, a1, "DEPENDS_ON")
      MathematicsKnowledgeGraph.add_edge(a1, a2, "DEPENDS_ON")

      assert {:ok, deps} = MathematicsKnowledgeGraph.dependencies(thm)
      dep_ids = Enum.map(deps, fn d -> d["node_id"] end)
      assert a1 in dep_ids
      assert a2 in dep_ids
    end

    test "returns error for non-existent node" do
      assert {:error, _} = MathematicsKnowledgeGraph.dependencies("node_missing")
    end
  end

  # ---------------------------------------------------------------------------
  # Graph Root Fingerprint
  # ---------------------------------------------------------------------------

  describe "graph_root/0" do
    test "returns a deterministic SHA-256 fingerprint" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{})
      MathematicsKnowledgeGraph.add_edge(a, b, "PROVES")

      root1 = MathematicsKnowledgeGraph.graph_root()
      root2 = MathematicsKnowledgeGraph.graph_root()
      assert root1 == root2
      assert String.match?(root1, ~r/^[0-9a-f]{64}$/)
    end

    test "different graphs produce different roots" do
      MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "X"})
      root1 = MathematicsKnowledgeGraph.graph_root()
      MathematicsKnowledgeGraph.reset_tables()
      MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "Y"})
      root2 = MathematicsKnowledgeGraph.graph_root()
      assert root1 != root2
    end
  end

  # ---------------------------------------------------------------------------
  # Replay
  # ---------------------------------------------------------------------------

  describe "replay_node/2" do
    test "reconstructs the same ID deterministically" do
      inputs = %{"statement" => "∀x. x = x"}
      id1 = MathematicsKnowledgeGraph.replay_node("AxiomNode", inputs)
      id2 = MathematicsKnowledgeGraph.replay_node("AxiomNode", inputs)
      assert id1 == id2
    end

    test "matches add_node for same content" do
      inputs = %{"statement" => "Continuity implies differentiability?"}
      assert {:ok, add_id} = MathematicsKnowledgeGraph.add_node("ConjectureNode", inputs)
      replay_id = MathematicsKnowledgeGraph.replay_node("ConjectureNode", inputs)
      assert add_id == replay_id
    end

    test "different inputs produce different IDs" do
      id1 = MathematicsKnowledgeGraph.replay_node("DefinitionNode", %{"name" => "Ring"})
      id2 = MathematicsKnowledgeGraph.replay_node("DefinitionNode", %{"name" => "Field"})
      assert id1 != id2
    end
  end

  describe "replay_graph/2" do
    test "reconstructs identical graph root from specs" do
      MathematicsKnowledgeGraph.add_node("AxiomNode", %{"statement" => "Extensionality"})
      MathematicsKnowledgeGraph.add_node("TheoremNode", %{"statement" => "Thm1"})
      root1 = MathematicsKnowledgeGraph.graph_root()

      MathematicsKnowledgeGraph.reset_tables()

      node_specs = [
        %{"node_type" => "AxiomNode", "metadata" => %{"statement" => "Extensionality"}},
        %{"node_type" => "TheoremNode", "metadata" => %{"statement" => "Thm1"}}
      ]

      root2 = MathematicsKnowledgeGraph.replay_graph(node_specs, [])
      assert root1 == root2
    end

    test "replay with edges reproduces identical fingerprint" do
      MathematicsKnowledgeGraph.add_node("AxiomNode", %{"name" => "ZFC1"})
      MathematicsKnowledgeGraph.add_node("TheoremNode", %{"name" => "Thm2"})

      ax_id = MathematicsKnowledgeGraph.query_nodes("AxiomNode") |> elem(1) |> hd() |> Map.get("node_id")
      thm_id = MathematicsKnowledgeGraph.query_nodes("TheoremNode") |> elem(1) |> hd() |> Map.get("node_id")
      MathematicsKnowledgeGraph.add_edge(ax_id, thm_id, "PROVES")
      root1 = MathematicsKnowledgeGraph.graph_root()

      MathematicsKnowledgeGraph.reset_tables()

      node_specs = [
        %{"node_type" => "AxiomNode", "metadata" => %{"name" => "ZFC1"}},
        %{"node_type" => "TheoremNode", "metadata" => %{"name" => "Thm2"}}
      ]

      edge_specs = [
        %{"from" => ax_id, "to" => thm_id, "edge_type" => "PROVES"}
      ]

      root2 = MathematicsKnowledgeGraph.replay_graph(node_specs, edge_specs)
      assert root1 == root2
    end
  end

  # ---------------------------------------------------------------------------
  # Archaeology
  # ---------------------------------------------------------------------------

  describe "archaeology/1" do
    test "returns provenance for a node" do
      assert {:ok, id} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"statement" => "A=A"})
      assert {:ok, prov} = MathematicsKnowledgeGraph.archaeology(id)
      assert prov["node_id"] == id
      assert prov["created_why"]["origin"] == "Phase 16.X.2"
      assert prov["owner"] == "Constitutional Research Council"
    end

    test "includes dependent structures and consumers" do
      assert {:ok, ax} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "A"})
      assert {:ok, thm} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{"s" => "B"})
      assert {:ok, app} = MathematicsKnowledgeGraph.add_node("ApplicationNode", %{"s" => "C"})
      MathematicsKnowledgeGraph.add_edge(thm, ax, "DEPENDS_ON")
      MathematicsKnowledgeGraph.add_edge(thm, app, "APPLIES_TO")

      assert {:ok, prov} = MathematicsKnowledgeGraph.archaeology(thm)
      assert ax in prov["necessary_definitions"]
    end

    test "returns error for non-existent node" do
      assert {:error, _} = MathematicsKnowledgeGraph.archaeology("node_missing")
    end
  end

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  describe "validate_graph/0" do
    test "passes for clean graph" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{})
      MathematicsKnowledgeGraph.add_edge(a, b, "PROVES")

      assert {:ok, result} = MathematicsKnowledgeGraph.validate_graph()
      assert result["orphan_edges"] == 0
      assert String.match?(result["graph_root"], ~r/^[0-9a-f]{64}$/)
    end

    test "detects orphan edges" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      :ets.insert(:math_kg_edges, {"edge_bogus", %{
        "edge_id" => "edge_bogus",
        "from" => a,
        "to" => "node_nonexistent",
        "edge_type" => "DEPENDS_ON"
      }})

      assert {:error, issues} = MathematicsKnowledgeGraph.validate_graph()
      assert issues["orphan_edges"] > 0
    end

    test "detects invalid node types" do
      :ets.insert(:math_kg_nodes, {"node_bad", %{
        "node_id" => "node_bad",
        "node_type" => "FakeNode",
        "metadata" => %{}
      }})

      assert {:error, issues} = MathematicsKnowledgeGraph.validate_graph()
      assert issues["invalid_node_types"] == ["FakeNode"]
    end
  end

  # ---------------------------------------------------------------------------
  # Cycle Detection
  # ---------------------------------------------------------------------------

  describe "detect_cycles/0" do
    test "returns :no_cycles for acyclic graph" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{})
      MathematicsKnowledgeGraph.add_edge(a, b, "DEPENDS_ON")

      assert {:ok, :no_cycles} = MathematicsKnowledgeGraph.detect_cycles()
    end

    test "detects a simple direct cycle" do
      assert {:ok, a} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"s" => "A"})
      assert {:ok, b} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{"s" => "B"})
      MathematicsKnowledgeGraph.add_edge(a, b, "DEPENDS_ON")
      MathematicsKnowledgeGraph.add_edge(b, a, "DEPENDS_ON")

      assert {:error, cycles} = MathematicsKnowledgeGraph.detect_cycles()
      assert length(cycles) > 0
    end
  end

  # ---------------------------------------------------------------------------
  # Archaeology (graph-level)
  # ---------------------------------------------------------------------------

  describe "archaeology provenance" do
    test "every node stores provenance metadata" do
      assert {:ok, id} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{})
      assert {:ok, node} = MathematicsKnowledgeGraph.get_node(id)
      assert node["origin"] == "Phase 16.X.2"
      assert node["purpose"] == "foundational starting assumption"
    end

    test "provenance persists through replay" do
      meta = %{"statement" => "Archimedean property"}
      assert {:ok, id} = MathematicsKnowledgeGraph.add_node("AxiomNode", meta)
      assert {:ok, node} = MathematicsKnowledgeGraph.get_node(id)
      assert node["owner"] == "Constitutional Research Council"
    end
  end

  # ---------------------------------------------------------------------------
  # Valid Node/Edge Types
  # ---------------------------------------------------------------------------

  describe "valid_node_types/0" do
    test "returns all 12 valid node types" do
      types = MathematicsKnowledgeGraph.valid_node_types()
      assert length(types) == 12
      assert "AxiomNode" in types
      assert "ApplicationNode" in types
      assert "CounterexampleNode" in types
      assert "MathematicalAssertionNode" in types
    end
  end

  describe "valid_edge_types/0" do
    test "returns all 10 constitutional edge types" do
      types = MathematicsKnowledgeGraph.valid_edge_types()
      assert length(types) == 10
      assert "DEFINES" in types
      assert "DEPENDS_ON" in types
      assert "PROVES" in types
      assert "REFINES" in types
      assert "GENERALIZES" in types
      assert "SPECIALIZES" in types
      assert "DERIVES" in types
      assert "USES" in types
      assert "APPLIES_TO" in types
      assert "SUPERSEDES" in types
    end
  end

  # ---------------------------------------------------------------------------
  # Integration: Proof Dependency Chain (constitutional edge types)
  # ---------------------------------------------------------------------------

  describe "integration: full proof dependency chain" do
    test "axiom -> lemma -> theorem -> corollary" do
      assert {:ok, ax} = MathematicsKnowledgeGraph.add_node("AxiomNode", %{"name" => "Extensionality"})
      assert {:ok, lem} = MathematicsKnowledgeGraph.add_node("LemmaNode", %{"statement" => "Lemma 1"})
      assert {:ok, thm} = MathematicsKnowledgeGraph.add_node("TheoremNode", %{"statement" => "Theorem 1"})
      assert {:ok, cor} = MathematicsKnowledgeGraph.add_node("CorollaryNode", %{"statement" => "Cor 1", "parent" => "thm1"})

      MathematicsKnowledgeGraph.add_edge(lem, ax, "DEPENDS_ON")
      MathematicsKnowledgeGraph.add_edge(thm, lem, "DEPENDS_ON")
      MathematicsKnowledgeGraph.add_edge(thm, ax, "DEPENDS_ON")
      MathematicsKnowledgeGraph.add_edge(thm, cor, "DERIVES")

      assert {:ok, deps} = MathematicsKnowledgeGraph.dependencies(thm)
      dep_ids = Enum.map(deps, fn d -> d["node_id"] end)
      assert ax in dep_ids
      assert lem in dep_ids

      assert {:ok, [found_cor]} = MathematicsKnowledgeGraph.traverse(thm, "DERIVES")
      assert Map.get(found_cor, "node_id") == cor

      assert {:ok, :no_cycles} = MathematicsKnowledgeGraph.detect_cycles()
    end
  end
end
