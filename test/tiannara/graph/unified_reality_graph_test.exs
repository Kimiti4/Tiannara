defmodule Tiannara.Graph.UnifiedRealityGraphTest do
  use ExUnit.Case, async: false

  alias Tiannara.Graph.UnifiedRealityGraph, as: URG

  setup do
    if is_nil(Process.whereis(URG)) do
      start_supervised!({URG, []})
    end

    :ok
  end

  test "add_node stores stage and enriched payload" do
    assert {:ok, "n1"} = URG.add_node("n1", :information, %{content: "raw data"})
    assert {:ok, %{payload: payload}} = URG.get_node_with_context("n1")
    assert payload.stage == :information
    assert payload.content == "raw data"
    assert payload.version == "1.0.0"
  end

  test "add_edge stores relationship type and metadata" do
    {:ok, "a"} = URG.add_node("a", :information, %{content: "A"})
    {:ok, "b"} = URG.add_node("b", :knowledge, %{content: "B"})
    {:ok, _edge} = URG.add_edge("a", "b", :derived_from, %{weight: 0.9})

    assert {:ok, %{successors: [succ]}} = URG.get_node_with_context("a")
    assert succ.node_id == "b"
    assert succ.relationship == :derived_from
    assert succ.metadata == %{weight: 0.9}
  end

  test "trace_lineage walks ancestors through allowed relationships" do
    {:ok, "root"} = URG.add_node("root", :principle, %{content: "R"})
    {:ok, "mid"} = URG.add_node("mid", :model, %{content: "M"})
    {:ok, "leaf"} = URG.add_node("leaf", :knowledge, %{content: "L"})
    {:ok, _} = URG.add_edge("mid", "leaf", :derived_from)
    {:ok, _} = URG.add_edge("root", "mid", :derived_from)

    assert {:ok, %{lineage: lineage}} = URG.trace_lineage("leaf")
    assert Enum.sort(lineage) == ["leaf", "mid", "root"]
  end

  test "blast_radius finds dependents downstream" do
    {:ok, "p1"} = URG.add_node("p1", :principle, %{content: "R"})
    {:ok, "p2"} = URG.add_node("p2", :model, %{content: "M"})
    {:ok, "p3"} = URG.add_node("p3", :knowledge, %{content: "L"})
    {:ok, _} = URG.add_edge("p1", "p2", :depends_on)
    {:ok, _} = URG.add_edge("p2", "p3", :depends_on)

    assert {:ok, %{affected_nodes: affected}} = URG.blast_radius("p1")
    assert Enum.sort(affected) == ["p1", "p2", "p3"]
  end

  test "ingest_node is backward compatible and edges carry weights" do
    assert {:ok, "h1"} = URG.ingest_node("h1", :hypothesis, %{stage: :information, content: "H"})
    assert {:ok, "h2"} = URG.ingest_node("h2", :hypothesis, %{content: "H2"})
    assert {:ok, _edge} = URG.add_edge("h1", "h2", :supports, %{weight: 0.9})

    assert {:ok, %{successors: [%{metadata: %{weight: 0.9}}]}} = URG.get_node_with_context("h1")
  end

  test "missing node and stale queries are handled" do
    assert {:error, :not_found} = URG.get_node_with_context("ghost")
    assert {:ok, %{lineage: ["real"]}} = URG.trace_lineage("real")
  end
end
