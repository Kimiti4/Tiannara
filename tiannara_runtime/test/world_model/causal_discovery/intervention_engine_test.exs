defmodule TiannaraRuntime.CausalDiscovery.InterventionEngineTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.InterventionEngine
  alias TiannaraRuntime.WorldModel.Ontology.CausalGraph
  alias TiannaraRuntime.WorldModel.Ontology.CausalNode
  alias TiannaraRuntime.WorldModel.Ontology.CausalEdge
  alias TiannaraRuntime.WorldModel.Ontology.Intervention

  defp test_graph do
    {:ok, n1} = CausalNode.new(node_id: "exog", type: :exogenous)
    {:ok, n2} = CausalNode.new(node_id: "endog1", type: :endogenous)
    {:ok, n3} = CausalNode.new(node_id: "endog2", type: :endogenous)
    {:ok, e1} = CausalEdge.new(source: "exog", target: "endog1", type: :direct)
    {:ok, e2} = CausalEdge.new(source: "endog1", target: "endog2", type: :direct)
    {:ok, g} = CausalGraph.new(nodes: [n1, n2, n3], edges: [e1, e2])
    g
  end

  describe "plan_intervention/4" do
    test "returns plan with ip_ prefix for valid target" do
      {:ok, plan} = InterventionEngine.plan_intervention(test_graph(), "endog1", :remove)
      assert String.starts_with?(plan.plan_id, "ip_")
    end

    test "returns error for invalid target" do
      assert {:error, _} = InterventionEngine.plan_intervention(test_graph(), "nonexistent", :remove)
    end
  end

  describe "identify_controllable/1" do
    test "returns list of exogenous node IDs" do
      assert InterventionEngine.identify_controllable(test_graph()) == ["exog"]
    end
  end

  describe "trace_pathway/3" do
    test "returns path for valid source and target" do
      {:ok, path} = InterventionEngine.trace_pathway(test_graph(), "exog", "endog2")
      assert path == ["exog", "endog1", "endog2"]
    end

    test "returns error when no path exists" do
      assert {:error, :no_path} = InterventionEngine.trace_pathway(test_graph(), "endog2", "exog")
    end
  end

  describe "predict_effect/3" do
    test "returns expected effect and confidence interval" do
      {:ok, iv} = Intervention.new(target_variable: "exog", set_value: :remove)
      {:ok, result} = InterventionEngine.predict_effect(test_graph(), iv, "endog2")
      assert %{expected: _, confidence_interval: _} = result
    end
  end

  describe "verify_identifiability/3" do
    test "returns identifiability atom" do
      {:ok, iv} = Intervention.new(target_variable: "exog", set_value: :remove)
      result = InterventionEngine.verify_identifiability(test_graph(), iv, "endog2")
      assert result in [:identified, :partial, :non_identifiable]
    end
  end
end
