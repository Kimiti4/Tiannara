defmodule TiannaraRuntime.Mathematics.DerivationGraphTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.{FormalAST, DerivationGraph, FormulaSynthesizer}

  test "derivation records rule and side conditions" do
    x = FormalAST.variable("x", :real)
    graph = DerivationGraph.new(x)
    root = hd(graph.roots)
    {:ok, graph} = DerivationGraph.add(graph, root, FormalAST.add(x, FormalAST.constant(1, :integer)), :add_one, [:condition_a])
    assert length(graph.edges) == 1
    assert hd(graph.edges).rule == :add_one
  end

  test "missing derivation parent is rejected" do
    x = FormalAST.variable("x", :real)
    assert {:error, :parent_node_not_found} =
             DerivationGraph.add(DerivationGraph.new(x), "missing", x, :fake)
  end

  test "formula synthesis produces candidates, not truths" do
    x = FormalAST.variable("x", :real)
    {:ok, result} = FormulaSynthesizer.generate(x, [], budget: 4)
    assert result.status == :candidate
    assert result.certification_eligible == false
    assert Enum.all?(result.candidates, &(&1.status == :candidate))
  end
end
