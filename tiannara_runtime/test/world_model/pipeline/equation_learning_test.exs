defmodule TiannaraRuntime.WorldModel.Pipeline.EquationLearningTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.WorldModel.Pipeline.EquationLearning
  alias TiannaraRuntime.WorldModel.Ontology.{CausalGraph, CausalNode, CausalEdge, Equation, EquationSystem}

  describe "learn_equations/2" do
    test "returns empty equations from graph with no nodes" do
      {:ok, cg} = CausalGraph.new(nodes: [], edges: [])
      {:ok, result} = EquationLearning.learn_equations(cg, %{})
      assert result.equation_system.equations == []
      assert byte_size(result.equation_root) == 64
    end

    test "creates equation for endogenous node" do
      {:ok, n} = CausalNode.new(node_id: "v_temp", type: :endogenous)
      {:ok, cg} = CausalGraph.new(nodes: [n], edges: [])

      {:ok, result} = EquationLearning.learn_equations(cg, %{})
      assert length(result.equation_system.equations) == 1

      eq = hd(result.equation_system.equations)
      assert eq.target_variable == "v_temp"
      assert eq.derivation == :learned
    end

    test "skips exogenous nodes" do
      {:ok, n1} = CausalNode.new(node_id: "v_endog", type: :endogenous)
      {:ok, n2} = CausalNode.new(node_id: "v_exog", type: :exogenous)
      {:ok, cg} = CausalGraph.new(nodes: [n1, n2], edges: [])

      {:ok, result} = EquationLearning.learn_equations(cg, %{})
      assert length(result.equation_system.equations) == 1
      assert hd(result.equation_system.equations).target_variable == "v_endog"
    end

    test "includes parents in expression" do
      {:ok, n1} = CausalNode.new(node_id: "v_cause", type: :endogenous)
      {:ok, n2} = CausalNode.new(node_id: "v_effect", type: :endogenous)
      {:ok, e} = CausalEdge.new(source: "v_cause", target: "v_effect", type: :direct)
      {:ok, cg} = CausalGraph.new(nodes: [n1, n2], edges: [e])

      {:ok, result} = EquationLearning.learn_equations(cg, %{})
      effect_eq = Enum.find(result.equation_system.equations, fn eq -> eq.target_variable == "v_effect" end)
      assert effect_eq.expression["form"] == "linear"
      assert "v_cause" in effect_eq.expression["parents"]
    end

    test "orphan node gets constant equation" do
      {:ok, n} = CausalNode.new(node_id: "v_orphan", type: :endogenous)
      {:ok, cg} = CausalGraph.new(nodes: [n], edges: [])

      {:ok, result} = EquationLearning.learn_equations(cg, %{})
      eq = hd(result.equation_system.equations)
      assert eq.expression["form"] == "constant"
    end

    test "equation_root is deterministic" do
      {:ok, n} = CausalNode.new(node_id: "v_x", type: :endogenous)
      {:ok, cg} = CausalGraph.new(nodes: [n], edges: [])

      {:ok, r1} = EquationLearning.learn_equations(cg, %{})
      {:ok, r2} = EquationLearning.learn_equations(cg, %{})
      assert r1.equation_root == r2.equation_root
    end

    test "equation_root changes when graph changes" do
      {:ok, nx} = CausalNode.new(node_id: "v_x", type: :endogenous)
      {:ok, ny} = CausalNode.new(node_id: "v_y", type: :endogenous)
      {:ok, cg1} = CausalGraph.new(nodes: [nx], edges: [])
      {:ok, cg2} = CausalGraph.new(nodes: [ny], edges: [])

      {:ok, r1} = EquationLearning.learn_equations(cg1, %{})
      {:ok, r2} = EquationLearning.learn_equations(cg2, %{})
      refute r1.equation_root == r2.equation_root
    end
  end

  describe "build_expression/2" do
    test "empty parents gives constant form" do
      expr = EquationLearning.build_expression("v_x", [])
      assert expr["form"] == "constant"
    end

    test "with parents gives linear form" do
      expr = EquationLearning.build_expression("v_y", ["v_x"])
      assert expr["form"] == "linear"
      assert expr["target"] == "v_y"
      assert expr["parents"] == ["v_x"]
    end
  end

  describe "build_incoming_map/1" do
    test "builds incoming edge map" do
      {:ok, e1} = CausalEdge.new(source: "v_a", target: "v_c", type: :direct)
      {:ok, e2} = CausalEdge.new(source: "v_b", target: "v_c", type: :direct)

      result = EquationLearning.build_incoming_map([e1, e2])
      assert result["v_c"] == ["v_b", "v_a"]
    end

    test "empty edges gives empty map" do
      assert EquationLearning.build_incoming_map([]) == %{}
    end
  end

  describe "compute_equation_root/1" do
    test "returns deterministic root" do
      {:ok, eq} = Equation.new(target_variable: "v_x", expression: %{"form" => "constant"}, type: :algebraic)
      {:ok, es} = EquationSystem.new(equations: [eq])

      r1 = EquationLearning.compute_equation_root(es)
      r2 = EquationLearning.compute_equation_root(es)
      assert r1 == r2
      assert byte_size(r1) == 64
    end
  end
end
