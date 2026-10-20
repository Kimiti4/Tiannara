defmodule TiannaraRuntime.CausalDiscovery.StructureCandidateTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.StructureCandidate

  describe "new/1" do
    test "creates valid StructureCandidate with edges and score" do
      {:ok, c} = StructureCandidate.new(edges: [{"x", "y", :direct, 0.9}], score: 0.95)
      assert c.edges == [{"x", "y", :direct, 0.9}]
      assert c.score == 0.95
      assert String.starts_with?(c.candidate_id, "sc_")
    end

    test "fails on empty edges" do
      assert {:error, _} = StructureCandidate.new(edges: [], score: 0.95)
    end

    test "fails on nil score" do
      assert {:error, _} = StructureCandidate.new(edges: [{"x", "y", :direct, 0.9}], score: nil)
    end

    test "fails on invalid score_type" do
      assert {:error, _} = StructureCandidate.new(edges: [{"x", "y", :direct, 0.9}], score: 0.95, score_type: :invalid)
    end

    test "fails on invalid derivation" do
      assert {:error, _} = StructureCandidate.new(edges: [{"x", "y", :direct, 0.9}], score: 0.95, derivation: :invalid)
    end

    test "fails when confidence is out of range" do
      assert {:error, _} = StructureCandidate.new(edges: [{"x", "y", :direct, 0.9}], score: 0.95, confidence: 1.5)
    end
  end

  describe "validate/1" do
    test "returns {:ok, struct} for valid StructureCandidate" do
      c = %StructureCandidate{edges: [{"x", "y", :direct, 0.9}], score: 0.95, score_type: :bic, derivation: :constraint_based, confidence: 1.0}
      assert {:ok, _} = StructureCandidate.validate(c)
    end

    test "fails for invalid StructureCandidate" do
      c = %StructureCandidate{edges: [], score: 0.95, score_type: :bic, derivation: :constraint_based, confidence: 1.0}
      assert {:error, _} = StructureCandidate.validate(c)
    end
  end

  describe "compute_id/1" do
    test "returns string starting with sc_" do
      {:ok, c} = StructureCandidate.new(edges: [{"a", "b", :direct, 0.8}], score: 0.9)
      id = StructureCandidate.compute_id(c)
      assert String.starts_with?(id, "sc_")
    end
  end
end
