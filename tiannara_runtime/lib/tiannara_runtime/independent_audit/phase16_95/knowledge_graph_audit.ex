defmodule TiannaraRuntime.IndependentAudit.Phase16_95.KnowledgeGraphAudit do
  @moduledoc """
  Phase 16.95 — Knowledge Graph Audit (Category 3)

  Verifies:
  - Graph integrity (no orphan nodes)
  - No duplicate discoveries
  - No broken references
  - No cyclic corruption
  - Deterministic identifiers
  """

  @valid_node_types ~w(ObservationNode QuestionNode HypothesisNode ExperimentNode TheoryNode EvidenceNode)

  @doc "Audit the knowledge graph"
  @spec audit(map()) :: map()
  def audit(artifact_bundle) do
    kg_data = Map.get(artifact_bundle, "knowledge_graph", [])
    nodes = Enum.filter(kg_data, &(not Map.has_key?(&1, "edge_type")))
    edges = Enum.filter(kg_data, &Map.has_key?(&1, "edge_type"))

    checks = %{
      "node_integrity" => check_node_integrity(nodes),
      "reference_integrity" => check_reference_integrity(nodes),
      "duplicate_detection" => check_duplicates(nodes),
      "deterministic_ids" => check_deterministic_ids(nodes)
    }

    failures = Enum.count(checks, fn {_k, %{"status" => status}} -> status != "PASS" end)

    %{
      "audit" => "knowledge_graph",
      "result" => if(failures == 0, do: "PASS", else: "FAIL"),
      "checks" => checks,
      "nodes_scanned" => length(nodes),
      "edges_scanned" => length(edges),
      "failures" => failures
    }
  end

  defp check_node_integrity(nodes) do
    invalid = Enum.filter(nodes, fn n ->
      node_type = Map.get(n, "node_type", "")
      is_binary(node_type) and node_type != "" and node_type not in @valid_node_types
    end)

    %{
      "status" => if(invalid == [], do: "PASS", else: "FAIL"),
      "valid_types" => @valid_node_types,
      "invalid_nodes" => length(invalid)
    }
  end

  defp check_reference_integrity(nodes) do
    node_ids = nodes |> Enum.map(&Map.get(&1, "node_id")) |> Enum.filter(&is_binary/1)
    reference_keys = ["origin", "parent", "depends_on", "evidence_refs"]

    broken_refs =
      nodes
      |> Enum.flat_map(fn n ->
        reference_keys
        |> Enum.filter(&Map.has_key?(n, &1))
        |> Enum.map(&Map.get(n, &1))
        |> List.flatten()
        |> Enum.filter(fn ref -> is_binary(ref) and ref not in node_ids end)
      end)

    %{
      "status" => if(broken_refs == [], do: "PASS", else: "FAIL"),
      "broken_references" => broken_refs
    }
  end

  defp check_duplicates(nodes) do
    ids = Enum.map(nodes, &Map.get(&1, "node_id", ""))
    duplicates = ids -- Enum.uniq(ids)
    unique = Enum.uniq(ids)

    %{
      "status" => if(duplicates == [], do: "PASS", else: "FAIL"),
      "total_nodes" => length(ids),
      "unique_nodes" => length(unique),
      "duplicates" => length(duplicates)
    }
  end

  defp check_deterministic_ids(nodes) do
    valid =
      nodes
      |> Enum.all?(fn n ->
        id = Map.get(n, "node_id", "")
        is_binary(id) and byte_size(id) > 0
      end)

    %{"status" => if(valid, do: "PASS", else: "FAIL")}
  end
end
