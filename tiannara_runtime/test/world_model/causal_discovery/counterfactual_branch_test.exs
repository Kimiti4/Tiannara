defmodule TiannaraRuntime.CausalDiscovery.CounterfactualBranchTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.CounterfactualBranch
  alias TiannaraRuntime.WorldModel.Ontology.Intervention

  describe "new/1" do
    test "creates valid CounterfactualBranch with auto-generated branch_id" do
      {:ok, iv} = Intervention.new(target_variable: "x", set_value: {:fix, 42})
      {:ok, cb} = CounterfactualBranch.new(base_graph_fingerprint: "fp123", intervention: iv)
      assert cb.base_graph_fingerprint == "fp123"
      assert cb.intervention == iv
      assert String.starts_with?(cb.branch_id, "cb_")
    end

    test "fails on nil base_graph_fingerprint" do
      {:ok, iv} = Intervention.new(target_variable: "x", set_value: {:fix, 42})
      assert {:error, _} = CounterfactualBranch.new(base_graph_fingerprint: nil, intervention: iv)
    end

    test "fails on nil intervention" do
      assert {:error, _} = CounterfactualBranch.new(base_graph_fingerprint: "fp123", intervention: nil)
    end

    test "fails when confidence is out of range" do
      {:ok, iv} = Intervention.new(target_variable: "x", set_value: {:fix, 42})
      assert {:error, _} = CounterfactualBranch.new(base_graph_fingerprint: "fp123", intervention: iv, confidence: 1.5)
    end
  end

  describe "validate/1" do
    test "returns {:ok, struct} for valid CounterfactualBranch" do
      {:ok, iv} = Intervention.new(target_variable: "x", set_value: {:fix, 42})
      cb = %CounterfactualBranch{branch_id: "cb_abc", base_graph_fingerprint: "fp", intervention: iv, evidence_roots: []}
      assert {:ok, _} = CounterfactualBranch.validate(cb)
    end

    test "fails for invalid CounterfactualBranch" do
      cb = %CounterfactualBranch{branch_id: "cb_abc", base_graph_fingerprint: "", intervention: nil}
      assert {:error, _} = CounterfactualBranch.validate(cb)
    end
  end

  describe "compute_id/1" do
    test "returns string starting with cb_" do
      {:ok, iv} = Intervention.new(target_variable: "x", set_value: {:fix, 42})
      {:ok, cb} = CounterfactualBranch.new(base_graph_fingerprint: "fp", intervention: iv)
      id = CounterfactualBranch.compute_id(cb)
      assert String.starts_with?(id, "cb_")
    end
  end
end
