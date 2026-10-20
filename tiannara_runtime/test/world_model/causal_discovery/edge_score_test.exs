defmodule TiannaraRuntime.CausalDiscovery.EdgeScoreTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.EdgeScore

  describe "new/1" do
    test "creates valid EdgeScore with source and target" do
      {:ok, e} = EdgeScore.new(source: "x", target: "y")
      assert e.source == "x"
      assert e.target == "y"
      assert String.starts_with?(e.edge_id, "es_")
    end

    test "fails on empty source" do
      assert {:error, _} = EdgeScore.new(source: "", target: "y")
    end

    test "fails on empty target" do
      assert {:error, _} = EdgeScore.new(source: "x", target: "")
    end

    test "fails when source and target are the same" do
      assert {:error, _} = EdgeScore.new(source: "x", target: "x")
    end

    test "fails on invalid weight_vector length" do
      assert {:error, _} = EdgeScore.new(source: "x", target: "y", weight_vector: [0.1, 0.2])
    end

    test "fails when score is out of range" do
      assert {:error, _} = EdgeScore.new(source: "x", target: "y", overall: 1.5)
    end
  end

  describe "validate/1" do
    test "returns {:ok, struct} for valid EdgeScore" do
      e = %EdgeScore{source: "x", target: "y", weight_vector: [0.2, 0.2, 0.2, 0.2, 0.2], evidence_support: 0.5, statistical_strength: 0.5, stability: 0.5, replay_confidence: 0.5, intervention_compat: 0.5, overall: 0.5}
      assert {:ok, _} = EdgeScore.validate(e)
    end

    test "fails for invalid EdgeScore" do
      e = %EdgeScore{source: "", target: "y"}
      assert {:error, _} = EdgeScore.validate(e)
    end
  end

  describe "compute_id/1" do
    test "returns string starting with es_" do
      {:ok, e} = EdgeScore.new(source: "a", target: "b")
      id = EdgeScore.compute_id(e)
      assert String.starts_with?(id, "es_")
    end
  end
end
