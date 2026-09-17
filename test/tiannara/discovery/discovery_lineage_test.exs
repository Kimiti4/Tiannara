defmodule Tiannara.Discovery.DiscoveryLineageTest do
  use ExUnit.Case, async: true
  alias Tiannara.Discovery.{DiscoveryLineage, Discovery, DiscoveryScore}
  alias Tiannara.Discovery.Domain.KnowledgeGap

  defp test_discovery(opts \\ []) do
    gap = KnowledgeGap.new(%{domain: Keyword.get(opts, :domain, :epistemic_consistency),
      description: "Test gap", severity: :medium, estimated_impact: 0.5, source: :epistemic_integrity})
    Discovery.from_gap(gap)
  end

  describe "trace/1" do
    test "returns the full lineage" do
      disc = test_discovery()
      lineage = DiscoveryLineage.trace(disc)
      assert is_list(lineage)
      assert length(lineage) == 1
      assert hd(lineage).event == :discovery_created
    end
  end

  describe "ancestry/1" do
    test "returns creation and promotion events" do
      disc = test_discovery()
      ancestry = DiscoveryLineage.ancestry(disc)
      assert length(ancestry) == 1
      assert hd(ancestry).event == :discovery_created
    end
  end

  describe "hypothesis_evolution/1" do
    test "returns hypothesis and evidence events" do
      disc = test_discovery()
      assert DiscoveryLineage.hypothesis_evolution(disc) == []
    end

    test "includes evidence_added after adding evidence" do
      disc = test_discovery() |> Discovery.add_evidence([%{type: :test}])
      evo = DiscoveryLineage.hypothesis_evolution(disc)
      assert Enum.any?(evo, &(&1.event == :evidence_added))
    end
  end

  describe "discovery_path/1" do
    test "returns unique events in order" do
      disc = test_discovery()
      path = DiscoveryLineage.discovery_path(disc)
      assert :discovery_created in path
    end
  end

  describe "provenance_tree/1" do
    test "builds tree with root and leaf" do
      disc = test_discovery()
      tree = DiscoveryLineage.provenance_tree(disc)
      assert tree.discovery_id == disc.id
      assert tree.root.event == :discovery_created
      assert tree.leaf.status == :question_formulated
      assert tree.leaf.event == :in_progress
      assert is_binary(tree.integrity_hash)
      assert tree.integrity == :ok
    end
  end

  describe "verify_integrity/1" do
    test "returns :ok for valid discovery" do
      disc = test_discovery()
      assert DiscoveryLineage.verify_integrity(disc) == :ok
    end

    test "detects empty lineage" do
      disc = %{test_discovery() | lineage: []}
      assert {:error, violations} = DiscoveryLineage.verify_integrity(disc)
      assert Enum.any?(violations, &String.contains?(&1, "empty"))
    end

    test "detects terminal status without terminal event" do
      disc = %{test_discovery() | status: :completed, lineage: [%{event: :discovery_created, at: DateTime.utc_now()}]}
      assert {:error, violations} = DiscoveryLineage.verify_integrity(disc)
      assert Enum.any?(violations, &String.contains?(&1, "terminal"))
    end

    test "detects out of order timestamps" do
      later = DateTime.utc_now()
      earlier = DateTime.add(later, -10, :second)
      disc = %{test_discovery() | lineage: [
        %{event: :a, at: later},
        %{event: :b, at: earlier}
      ]}
      assert {:error, violations} = DiscoveryLineage.verify_integrity(disc)
      assert Enum.any?(violations, &String.contains?(&1, "out of order"))
    end
  end

  describe "summarize/1" do
    test "returns summary with integrity info" do
      disc = test_discovery()
      summary = DiscoveryLineage.summarize(disc)
      assert summary.id == disc.id
      assert summary.status == :question_formulated
      assert summary.steps == 1
      assert summary.integrity == :valid
      assert summary.terminal == false
    end
  end
end
