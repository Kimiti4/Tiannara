defmodule Tiannara.Discovery.GapAnalyzerTest do
  use ExUnit.Case, async: true
  alias Tiannara.Discovery.GapAnalyzer
  alias Tiannara.Discovery.Domain.KnowledgeGap

  describe "analyze/1" do
    test "detects high contradiction rate" do
      report = %{contradiction_rate: 0.25, evidence_quality: 1.0, stale_theory_rate: 0.0, provenance_completeness: 1.0, experiment_recommendations: []}
      gaps = GapAnalyzer.analyze(report)
      assert length(gaps) >= 1
      gap = Enum.find(gaps, &(&1.domain == :epistemic_consistency))
      assert gap != nil
      assert gap.severity == :high
      assert gap.source == :epistemic_integrity
    end

    test "detects low evidence quality" do
      report = %{contradiction_rate: 0.0, evidence_quality: 0.4, stale_theory_rate: 0.0, provenance_completeness: 1.0, experiment_recommendations: []}
      gaps = GapAnalyzer.analyze(report)
      gap = Enum.find(gaps, &(&1.domain == :evidence_quality))
      assert gap != nil
      assert gap.severity == :high
    end

    test "detects stale theories" do
      report = %{contradiction_rate: 0.0, evidence_quality: 1.0, stale_theory_rate: 0.35, provenance_completeness: 1.0, experiment_recommendations: []}
      gaps = GapAnalyzer.analyze(report)
      gap = Enum.find(gaps, &(&1.domain == :knowledge_freshness))
      assert gap != nil
    end

    test "detects low provenance completeness" do
      report = %{contradiction_rate: 0.0, evidence_quality: 1.0, stale_theory_rate: 0.0, provenance_completeness: 0.6, experiment_recommendations: []}
      gaps = GapAnalyzer.analyze(report)
      gap = Enum.find(gaps, &(&1.domain == :provenance))
      assert gap != nil
    end

    test "converts experiment recommendations to gaps" do
      report = %{contradiction_rate: 0.0, evidence_quality: 1.0, stale_theory_rate: 0.0,
        provenance_completeness: 1.0,
        experiment_recommendations: [%{type: :resolve_contradictions, reason: "High contradiction rate", severity: :high}]}
      gaps = GapAnalyzer.analyze(report)
      assert length(gaps) >= 1
      assert Enum.any?(gaps, &(&1.source == :epistemic_integrity))
    end

    test "returns empty list for healthy report" do
      report = %{contradiction_rate: 0.01, evidence_quality: 0.95, stale_theory_rate: 0.05, provenance_completeness: 0.99, experiment_recommendations: []}
      gaps = GapAnalyzer.analyze(report)
      assert gaps == []
    end

    test "handles empty report" do
      assert GapAnalyzer.analyze(%{}) == []
    end
  end

  describe "rank/1" do
    test "sorts by severity x impact descending" do
      gaps = [KnowledgeGap.new(%{severity: :low, estimated_impact: 0.9}),
        KnowledgeGap.new(%{severity: :critical, estimated_impact: 0.5}),
        KnowledgeGap.new(%{severity: :medium, estimated_impact: 0.8})]
      ranked = GapAnalyzer.rank(gaps)
      assert hd(ranked).severity == :critical
      assert List.last(ranked).severity == :low
    end
  end
end
