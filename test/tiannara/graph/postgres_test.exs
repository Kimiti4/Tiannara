defmodule Tiannara.Graph.PostgresTest do
  use ExUnit.Case, async: false

  alias Tiannara.Graph.{Postgres, Edge, Audit}
  alias Tiannara.Graph.Postgres.Repo.InMemory

  @moduletag :graph_postgres

  setup do
    graph = Postgres.connect(InMemory, [])
    {:ok, graph: graph}
  end

  test "node insertion and retrieval", %{graph: g} do
    g = Postgres.add_node(g, :a, %{kind: :obs, value: 1})
    assert {:ok, %{kind: :obs, value: 1}} = Postgres.get_node(g, :a)
  end

  test "edge insertion preserves metadata", %{graph: g} do
    g = Postgres.add_node(g, :a, %{})
    g = Postgres.add_node(g, :b, %{})
    {:ok, g} = Postgres.add_edge(g, :e1, :a, :b, :supports, %{confidence: 0.9, source: :x})

    assert {:ok, %Edge{metadata: %{confidence: 0.9, source: :x}}} = Postgres.get_edge(g, :e1)
  end

  test "edge to a missing node is rejected", %{graph: g} do
    g = Postgres.add_node(g, :a, %{})
    assert {:error, :missing_node} = Postgres.add_edge(g, :e1, :a, :nope, :rel, %{})
  end

  test "Audit (lineage, blast radius, cycle) works on the persistent adapter", %{graph: g} do
    g = Postgres.add_node(g, :root, %{})
    g = Postgres.add_node(g, :mid, %{})
    g = Postgres.add_node(g, :leaf, %{})
    {:ok, g} = Postgres.add_edge(g, :e1, :root, :mid, :x, %{})
    {:ok, g} = Postgres.add_edge(g, :e2, :mid, :leaf, :x, %{})

    assert :root in Audit.lineage(g, :leaf)
    assert :leaf in Audit.blast_radius(g, :root)
    refute Audit.has_cycle?(g)
  end

  test "state persists across adapter instances sharing the same handle", %{graph: g} do
    g = Postgres.add_node(g, :a, %{v: 1})
    g2 = %Postgres{repo: g.repo, handle: g.handle}
    assert {:ok, %{v: 1}} = Postgres.get_node(g2, :a)
  end
end