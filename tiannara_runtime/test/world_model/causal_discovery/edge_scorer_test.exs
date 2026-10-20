defmodule TiannaraRuntime.CausalDiscovery.EdgeScorerTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.EdgeScorer
  alias TiannaraRuntime.CausalDiscovery.EdgeScore
  alias TiannaraRuntime.WorldModel.Ontology.CausalGraph
  alias TiannaraRuntime.WorldModel.Ontology.CausalNode
  alias TiannaraRuntime.WorldModel.Ontology.CausalEdge

  @evidence %{"x" => [1.0, 2.0, 3.0, 4.0], "y" => [2.0, 4.0, 6.0, 8.0]}

  defp test_graph do
    {:ok, n1} = CausalNode.new(node_id: "x", type: :endogenous)
    {:ok, n2} = CausalNode.new(node_id: "y", type: :endogenous)
    {:ok, e} = CausalEdge.new(source: "x", target: "y", type: :direct)
    {:ok, g} = CausalGraph.new(nodes: [n1, n2], edges: [e])
    g
  end

  describe "score_edge/5" do
    test "returns edge_score with es_ prefix" do
      {:ok, score} = EdgeScorer.score_edge("x", "y", [], @evidence)
      assert String.starts_with?(score.edge_id, "es_")
    end
  end

  describe "score_graph/4" do
    test "returns list of scores for all graph edges" do
      {:ok, scores} = EdgeScorer.score_graph(test_graph(), [], @evidence)
      assert length(scores) == 1
    end
  end

  describe "rank_by_metric/2" do
    test "sorts descending by given metric" do
      {:ok, s1} = EdgeScore.new(source: "a", target: "b", overall: 0.8)
      {:ok, s2} = EdgeScore.new(source: "c", target: "d", overall: 0.5)
      ranked = EdgeScorer.rank_by_metric([s2, s1], :overall)
      assert Enum.map(ranked, & &1.overall) == [0.8, 0.5]
    end
  end

  describe "edge_fingerprint/1" do
    test "returns the edge_id" do
      {:ok, score} = EdgeScorer.score_edge("x", "y", [], @evidence)
      assert EdgeScorer.edge_fingerprint(score) == score.edge_id
    end
  end
end
