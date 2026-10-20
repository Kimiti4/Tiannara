defmodule TiannaraRuntime.CausalDiscovery.StructureLearnerTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.StructureLearner
  alias TiannaraRuntime.CausalDiscovery.IndependenceResult
  alias TiannaraRuntime.WorldModel.Ontology.CausalGraph
  alias TiannaraRuntime.WorldModel.Ontology.CausalNode
  alias TiannaraRuntime.WorldModel.Ontology.CausalEdge

  @evidence %{"x" => [1.0, 2.0, 3.0], "y" => [4.0, 5.0, 6.0], "z" => [7.0, 8.0, 9.0]}

  defp test_results do
    {:ok, r1} =
      IndependenceResult.new(
        variable_a: "x",
        variable_b: "y",
        test_type: :marginal,
        p_value: 0.01,
        statistic: 0.9,
        sample_size: 3,
        dof: 0
      )

    {:ok, r2} =
      IndependenceResult.new(
        variable_a: "y",
        variable_b: "z",
        test_type: :marginal,
        p_value: 0.02,
        statistic: 0.8,
        sample_size: 3,
        dof: 0
      )

    {:ok, r3} =
      IndependenceResult.new(
        variable_a: "x",
        variable_b: "z",
        test_type: :marginal,
        p_value: 0.5,
        statistic: 0.1,
        sample_size: 3,
        dof: 0
      )

    {:ok, r4} =
      IndependenceResult.new(
        variable_a: "y",
        variable_b: "z",
        conditioning_set: ["x"],
        test_type: :conditional,
        p_value: 0.03,
        statistic: 0.7,
        sample_size: 3,
        dof: 0
      )

    {:ok, r5} =
      IndependenceResult.new(
        variable_a: "x",
        variable_b: "y",
        conditioning_set: ["z"],
        test_type: :conditional,
        p_value: 0.04,
        statistic: 0.85,
        sample_size: 3,
        dof: 0
      )

    [r1, r2, r3, r4, r5]
  end

  describe "discover_skeleton/3" do
    test "returns skeleton with sk_ prefix" do
      {:ok, skeleton} = StructureLearner.discover_skeleton(test_results(), ["x", "y", "z"])
      assert String.starts_with?(skeleton.skeleton_id, "sk_")
    end
  end

  describe "orient_edges/3" do
    test "returns causal graph from skeleton" do
      {:ok, skeleton} = StructureLearner.discover_skeleton(test_results(), ["x", "y", "z"])
      {:ok, graph} = StructureLearner.orient_edges(skeleton, test_results())
      assert %CausalGraph{} = graph
    end
  end

  describe "score_refine/3" do
    test "returns candidate with score" do
      {:ok, n1} = CausalNode.new(node_id: "x", type: :endogenous)
      {:ok, n2} = CausalNode.new(node_id: "y", type: :endogenous)
      {:ok, n3} = CausalNode.new(node_id: "z", type: :endogenous)
      {:ok, e1} = CausalEdge.new(source: "x", target: "y", type: :inferred)
      {:ok, e2} = CausalEdge.new(source: "y", target: "z", type: :inferred)
      {:ok, graph} = CausalGraph.new(nodes: [n1, n2, n3], edges: [e1, e2])
      {:ok, candidate} = StructureLearner.score_refine(graph, @evidence)
      assert candidate.score != nil
    end
  end

  describe "hybrid_discover/3" do
    test "returns candidate with score" do
      {:ok, candidate} = StructureLearner.hybrid_discover(test_results(), @evidence)
      assert candidate.score != nil
      assert String.starts_with?(candidate.candidate_id, "sc_")
    end
  end

  describe "generate_candidates/3" do
    test "returns list of candidates" do
      {:ok, n1} = CausalNode.new(node_id: "x", type: :endogenous)
      {:ok, n2} = CausalNode.new(node_id: "y", type: :endogenous)
      {:ok, n3} = CausalNode.new(node_id: "z", type: :endogenous)
      {:ok, e1} = CausalEdge.new(source: "x", target: "y", type: :inferred)
      {:ok, e2} = CausalEdge.new(source: "y", target: "z", type: :inferred)
      {:ok, graph} = CausalGraph.new(nodes: [n1, n2, n3], edges: [e1, e2])
      {:ok, candidates} = StructureLearner.generate_candidates(graph, @evidence)
      assert is_list(candidates) and length(candidates) > 0
    end
  end
end
