defmodule TiannaraRuntime.CausalDiscovery.GraphValidatorTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.GraphValidator
  alias TiannaraRuntime.CausalDiscovery.CausalValidationResult
  alias TiannaraRuntime.WorldModel.Ontology.CausalGraph
  alias TiannaraRuntime.WorldModel.Ontology.CausalNode
  alias TiannaraRuntime.WorldModel.Ontology.CausalEdge
  alias TiannaraRuntime.WorldModel.Ontology.Intervention

  describe "validate_acyclic/1" do
    test "returns :ok for acyclic graph" do
      {:ok, n1} = CausalNode.new(node_id: "v1", type: :endogenous)
      {:ok, n2} = CausalNode.new(node_id: "v2", type: :endogenous)
      {:ok, e} = CausalEdge.new(source: "v1", target: "v2", type: :direct)
      {:ok, g} = CausalGraph.new(nodes: [n1, n2], edges: [e])
      assert GraphValidator.validate_acyclic(g) == :ok
    end

    test "returns error for cyclic graph" do
      {:ok, n1} = CausalNode.new(node_id: "v1", type: :endogenous)
      {:ok, n2} = CausalNode.new(node_id: "v2", type: :endogenous)
      {:ok, e1} = CausalEdge.new(source: "v1", target: "v2", type: :direct)
      {:ok, e2} = CausalEdge.new(source: "v2", target: "v1", type: :direct)
      {:ok, g} = CausalGraph.new(nodes: [n1, n2], edges: [e1, e2])
      assert {:error, _} = GraphValidator.validate_acyclic(g)
    end
  end

  describe "validate_reachability/1" do
    test "returns :ok when all nodes reachable" do
      {:ok, n1} = CausalNode.new(node_id: "exog", type: :exogenous)
      {:ok, n2} = CausalNode.new(node_id: "endog", type: :endogenous)
      {:ok, e} = CausalEdge.new(source: "exog", target: "endog", type: :direct)
      {:ok, g} = CausalGraph.new(nodes: [n1, n2], edges: [e])
      assert GraphValidator.validate_reachability(g) == :ok
    end

    test "returns error when nodes unreachable" do
      {:ok, n1} = CausalNode.new(node_id: "orphan", type: :endogenous)
      {:ok, g} = CausalGraph.new(nodes: [n1], edges: [])
      assert {:error, _} = GraphValidator.validate_reachability(g)
    end
  end

  describe "validate_do_calculus/1" do
    test "returns level 1 for simple graph" do
      {:ok, n} = CausalNode.new(node_id: "v", type: :endogenous)
      {:ok, g} = CausalGraph.new(nodes: [n], edges: [])
      assert {:ok, 1} = GraphValidator.validate_do_calculus(g)
    end
  end

  describe "validate_intervention_safety/2" do
    test "returns :ok when target exists" do
      {:ok, n} = CausalNode.new(node_id: "v1", type: :endogenous)
      {:ok, g} = CausalGraph.new(nodes: [n], edges: [])
      {:ok, iv} = Intervention.new(target_variable: "v1", set_value: :remove)
      assert GraphValidator.validate_intervention_safety(g, iv) == :ok
    end

    test "returns error when target does not exist" do
      {:ok, n} = CausalNode.new(node_id: "v1", type: :endogenous)
      {:ok, g} = CausalGraph.new(nodes: [n], edges: [])
      {:ok, iv} = Intervention.new(target_variable: "nonexistent", set_value: :remove)
      assert {:error, _} = GraphValidator.validate_intervention_safety(g, iv)
    end
  end

  describe "validate_all/2" do
    test "returns CausalValidationResult" do
      {:ok, n1} = CausalNode.new(node_id: "exog", type: :exogenous)
      {:ok, n2} = CausalNode.new(node_id: "endog", type: :endogenous)
      {:ok, e} = CausalEdge.new(source: "exog", target: "endog", type: :direct)
      {:ok, g} = CausalGraph.new(nodes: [n1, n2], edges: [e], graph_fingerprint: "fp_test")
      {:ok, result} = GraphValidator.validate_all(g)
      assert %CausalValidationResult{} = result
    end
  end
end
