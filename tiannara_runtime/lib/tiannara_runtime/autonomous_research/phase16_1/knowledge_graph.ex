defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.KnowledgeGraph do
  @moduledoc """
  Phase 16.1 Module 7 — Knowledge Graph Runtime (Pure Implementation)

  Implements frozen behavior from RESEARCH_RUNTIME_FREEZE.md.

  Nodes:
  - ObservationNode, HypothesisNode, ExperimentNode, TheoryNode, EvidenceNode

  Relationships (frozen):
  - OBSERVED, GENERATED, TESTED, SUPPORTED, REFUTED, SUPERSEDES, DEPENDS_ON, CONTRADICTS

  Everything replayable from immutable artifacts.
  """

  @node_table :kg_nodes
  @edge_table :kg_edges

  def init_tables do
    if :ets.info(@node_table) == :undefined do
      :ets.new(@node_table, [:set, :public, :named_table])
    end

    if :ets.info(@edge_table) == :undefined do
      :ets.new(@edge_table, [:set, :public, :named_table])
    end

    :ok
  end

  @doc "Add a node to the knowledge graph"
  @spec add_node(String.t(), String.t()) :: :ok
  def add_node(node_id, node_type) do
    init_tables()
    node = %{
      "node_id" => node_id,
      "node_type" => node_type
    }

    :ets.insert(@node_table, {node_id, node})
    :ok
  end

  @doc "Add an edge between nodes"
  @spec add_edge(String.t(), String.t(), String.t()) :: :ok
  def add_edge(from_id, to_id, edge_type) do
    edge = %{
      "from" => from_id,
      "to" => to_id,
      "edge_type" => edge_type
    }

    edge_id = "edge_" <> from_id <> "_" <> to_id
    :ets.insert(@edge_table, {edge_id, edge})
    :ok
  end

  @doc "Query nodes by type"
  @spec query_nodes(String.t()) :: [map()]
  def query_nodes(node_type) do
    :ets.tab2list(@node_table)
    |> Enum.map(fn {_id, node} -> node end)
    |> Enum.filter(fn node -> node["node_type"] == node_type end)
  end

  @doc "Replay a node from immutable inputs"
  @spec replay_node(String.t(), map()) :: map()
  def replay_node(node_id, inputs) do
    canonical = canonicalize_map(inputs)
    computed_id = "node_" <> (Jason.encode!(canonical) |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower))

    %{
      "node_id" => computed_id,
      "inputs" => inputs,
      "replayed" => computed_id == node_id
    }
  end

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term
end
