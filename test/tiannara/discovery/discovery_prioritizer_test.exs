defmodule Tiannara.Discovery.DiscoveryPrioritizerTest do
  use ExUnit.Case, async: true
  alias Tiannara.Discovery.{DiscoveryPrioritizer, Discovery, DiscoveryScore}
  alias Tiannara.Discovery.Domain.KnowledgeGap

  defp test_discovery(domain, severity, impact) do
    gap = KnowledgeGap.new(%{domain: domain, description: "Test gap in #{domain}",
      severity: severity, estimated_impact: impact, uncertainty: 0.5, source: :epistemic_integrity})
    Discovery.from_gap(gap)
  end

  describe "rank/1" do
    test "sorts by composite score descending" do
      d1 = test_discovery(:epistemic_consistency, :critical, 0.9)
      d2 = test_discovery(:evidence_quality, :low, 0.3)
      d3 = test_discovery(:knowledge_freshness, :high, 0.7)
      ranked = DiscoveryPrioritizer.rank([d2, d1, d3])
      scores = Enum.map(ranked, fn d -> DiscoveryScore.composite(d.score) end)
      assert scores == Enum.sort(scores, :desc)
    end

    test "handles empty list" do
      assert DiscoveryPrioritizer.rank([]) == []
    end
  end

  describe "rank_with_diversity/1" do
    test "limits same-domain discoveries" do
      discoveries = Enum.map(1..5, fn _ -> test_discovery(:epistemic_consistency, :high, 0.8) end)
      ranked = DiscoveryPrioritizer.rank_with_diversity(discoveries)
      assert length(ranked) <= 3
    end
  end

  describe "select_for_execution/3" do
    test "respects max_count" do
      discoveries = Enum.map(1..10, fn i -> test_discovery(:"domain_#{i}", :medium, 0.5) end)
      selected = DiscoveryPrioritizer.select_for_execution(discoveries, 3)
      assert length(selected) <= 3
    end
  end

  describe "systemic_bottleneck/1" do
    test "identifies weakest dimension" do
      bottleneck = DiscoveryPrioritizer.systemic_bottleneck([test_discovery(:epistemic_consistency, :high, 0.8)])
      assert bottleneck != nil
      {dim, avg} = bottleneck
      assert dim in DiscoveryScore.dimensions()
      assert avg >= 0.0 and avg <= 1.0
    end

    test "returns nil for empty list" do
      assert DiscoveryPrioritizer.systemic_bottleneck([]) == nil
    end
  end

  describe "detect_monoculture/1" do
    test "detects domain monoculture" do
      discoveries = Enum.map(1..5, fn _ -> test_discovery(:epistemic_consistency, :high, 0.8) end)
      warnings = DiscoveryPrioritizer.detect_monoculture(discoveries)
      assert Enum.any?(warnings, &(&1.type == :domain_monoculture))
    end

    test "returns empty for diverse discoveries" do
      discoveries = [test_discovery(:epistemic_consistency, :high, 0.8),
        test_discovery(:evidence_quality, :medium, 0.6),
        test_discovery(:knowledge_freshness, :low, 0.4)]
      assert DiscoveryPrioritizer.detect_monoculture(discoveries) == []
    end
  end
end
