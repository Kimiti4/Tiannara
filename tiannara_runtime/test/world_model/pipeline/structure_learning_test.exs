defmodule TiannaraRuntime.WorldModel.Pipeline.StructureLearningTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.WorldModel.Pipeline.StructureLearning
  alias TiannaraRuntime.WorldModel.Ontology.{CausalGraph, CausalNode, CausalEdge, Variable}

  describe "learn_structure/2" do
    test "returns empty graph from empty variables" do
      {:ok, result} = StructureLearning.learn_structure(%{variables: []}, %{})
      assert result.causal_graph.nodes == []
      assert result.causal_graph.edges == []
      assert byte_size(result.structure_root) == 64
    end

    test "creates nodes from variables" do
      {:ok, v1} = Variable.new(variable_id: "v_1", name: "temperature", type: :continuous)
      {:ok, v2} = Variable.new(variable_id: "v_2", name: "pressure", type: :continuous)

      {:ok, result} = StructureLearning.learn_structure(%{variables: [v1, v2]}, %{})
      assert length(result.causal_graph.nodes) == 2

      node_ids = Enum.map(result.causal_graph.nodes, & &1.node_id)
      assert "v_1" in node_ids
      assert "v_2" in node_ids
    end

    test "marks nodes as endogenous by default" do
      {:ok, v} = Variable.new(variable_id: "v_x", name: "x", type: :continuous)

      {:ok, result} = StructureLearning.learn_structure(%{variables: [v]}, %{})
      node = hd(result.causal_graph.nodes)
      assert node.type == :endogenous
    end

    test "marks nodes as exogenous when is_endogenous is false" do
      {:ok, v} = Variable.new(name: "x", type: :continuous, is_endogenous: false)

      {:ok, result} = StructureLearning.learn_structure(%{variables: [v]}, %{})
      node = hd(result.causal_graph.nodes)
      assert node.type == :exogenous
    end

    test "no edges learned in default implementation" do
      {:ok, v1} = Variable.new(name: "a", type: :continuous)
      {:ok, v2} = Variable.new(name: "b", type: :continuous)

      {:ok, result} = StructureLearning.learn_structure(%{variables: [v1, v2]}, %{})
      assert result.causal_graph.edges == []
    end

    test "structure_root is deterministic" do
      {:ok, v} = Variable.new(variable_id: "v_x", name: "x", type: :continuous)

      {:ok, r1} = StructureLearning.learn_structure(%{variables: [v]}, %{})
      {:ok, r2} = StructureLearning.learn_structure(%{variables: [v]}, %{})
      assert r1.structure_root == r2.structure_root
    end
  end

  describe "build_nodes/1" do
    test "converts variables to nodes" do
      {:ok, v} = Variable.new(variable_id: "v_1", name: "x", type: :continuous)

      nodes = StructureLearning.build_nodes([v])
      assert length(nodes) == 1
      assert hd(nodes).node_id == "v_1"
    end
  end

  describe "validate_acyclic/1" do
    test "empty graph is acyclic" do
      {:ok, cg} = CausalGraph.new(nodes: [], edges: [])
      assert StructureLearning.validate_acyclic(cg) == :ok
    end

    test "single node graph is acyclic" do
      {:ok, n} = CausalNode.new(node_id: "v_1", type: :endogenous)
      {:ok, cg} = CausalGraph.new(nodes: [n], edges: [])
      assert StructureLearning.validate_acyclic(cg) == :ok
    end

    test "detects simple cycle" do
      {:ok, n1} = CausalNode.new(node_id: "v_1", type: :endogenous)
      {:ok, n2} = CausalNode.new(node_id: "v_2", type: :endogenous)
      {:ok, e1} = CausalEdge.new(source: "v_1", target: "v_2", type: :direct)
      {:ok, e2} = CausalEdge.new(source: "v_2", target: "v_1", type: :direct)
      {:ok, cg} = CausalGraph.new(nodes: [n1, n2], edges: [e1, e2])
      assert StructureLearning.validate_acyclic(cg) == {:error, "Causal graph contains a cycle"}
    end

    test "DAG without cycles passes" do
      {:ok, n1} = CausalNode.new(node_id: "v_1", type: :endogenous)
      {:ok, n2} = CausalNode.new(node_id: "v_2", type: :endogenous)
      {:ok, n3} = CausalNode.new(node_id: "v_3", type: :endogenous)
      {:ok, e1} = CausalEdge.new(source: "v_1", target: "v_2", type: :direct)
      {:ok, e2} = CausalEdge.new(source: "v_2", target: "v_3", type: :direct)
      {:ok, cg} = CausalGraph.new(nodes: [n1, n2, n3], edges: [e1, e2])
      assert StructureLearning.validate_acyclic(cg) == :ok
    end
  end

  describe "compute_structure_root/1" do
    test "returns deterministic root" do
      {:ok, n} = CausalNode.new(node_id: "v_1", type: :endogenous)
      {:ok, cg} = CausalGraph.new(nodes: [n], edges: [])

      r1 = StructureLearning.compute_structure_root(cg)
      r2 = StructureLearning.compute_structure_root(cg)
      assert r1 == r2
      assert byte_size(r1) == 64
    end

    test "different graphs produce different roots" do
      {:ok, n1} = CausalNode.new(node_id: "v_1", type: :endogenous)
      {:ok, n2} = CausalNode.new(node_id: "v_2", type: :endogenous)
      {:ok, cg1} = CausalGraph.new(nodes: [n1], edges: [])
      {:ok, cg2} = CausalGraph.new(nodes: [n2], edges: [])

      refute StructureLearning.compute_structure_root(cg1) ==
             StructureLearning.compute_structure_root(cg2)
    end
  end
end
