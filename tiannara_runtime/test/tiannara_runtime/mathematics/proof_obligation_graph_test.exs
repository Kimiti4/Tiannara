defmodule TiannaraRuntime.Mathematics.ProofObligationGraphTest do
  use ExUnit.Case, async: true
  alias TiannaraRuntime.Mathematics.ProofObligationGraph

  test "new obligations are unresolved" do
    graph = ProofObligationGraph.new(:theorem)
    assert ProofObligationGraph.status(graph, graph.root) == :unresolved
  end

  test "proof requires independent verifier evidence" do
    graph = ProofObligationGraph.new(:theorem)
    assert {:error, :independent_verification_required} =
      ProofObligationGraph.prove(graph, graph.root, %{verified: false})
  end

  test "proof requires dependencies first" do
    graph = ProofObligationGraph.new(:root)
    {:ok, graph} = ProofObligationGraph.add(graph, :lemma)
    root = graph.root
    assert {:error, :dependencies_not_proved} =
      ProofObligationGraph.prove(graph, root, %{verified: true, verifier_id: "v1"})
  end
end
