defmodule Tiannara.Discovery.GapAnalyzerPropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.Discovery.GapAnalyzer
  alias Tiannara.Discovery.Domain.KnowledgeGap

  describe "GapAnalyzer invariants" do
    property "analyze never crashes on valid reports" do
      check all contradiction_rate <- float(min: 0.0, max: 1.0),
                evidence_quality <- float(min: 0.0, max: 1.0),
                stale_theory_rate <- float(min: 0.0, max: 1.0),
                provenance_completeness <- float(min: 0.0, max: 1.0) do
        report = %{contradiction_rate: contradiction_rate, evidence_quality: evidence_quality,
          stale_theory_rate: stale_theory_rate, provenance_completeness: provenance_completeness,
          experiment_recommendations: []}
        gaps = GapAnalyzer.analyze(report)
        assert is_list(gaps)
        assert Enum.all?(gaps, &is_struct(&1, KnowledgeGap))
      end
    end

    property "every gap has a valid severity" do
      check all rate <- float(min: 0.0, max: 1.0) do
        report = %{contradiction_rate: rate, evidence_quality: 1.0, stale_theory_rate: 0.0,
          provenance_completeness: 1.0, experiment_recommendations: []}
        gaps = GapAnalyzer.analyze(report)
        Enum.each(gaps, fn gap ->
          assert gap.severity in [:low, :medium, :high, :critical]
        end)
      end
    end

    property "every gap has uncertainty in [0.0, 1.0]" do
      check all rate <- float(min: 0.0, max: 1.0),
                quality <- float(min: 0.0, max: 1.0) do
        report = %{contradiction_rate: rate, evidence_quality: quality, stale_theory_rate: 0.0,
          provenance_completeness: 1.0, experiment_recommendations: []}
        gaps = GapAnalyzer.analyze(report)
        Enum.each(gaps, fn gap ->
          assert gap.uncertainty >= 0.0 and gap.uncertainty <= 1.0
        end)
      end
    end

    property "rank is idempotent" do
      check all rates <- list_of(float(min: 0.0, max: 1.0), max_length: 10) do
        gaps = Enum.map(rates, fn r -> KnowledgeGap.new(%{severity: :medium, estimated_impact: r}) end)
        ranked_once = GapAnalyzer.rank(gaps)
        ranked_twice = GapAnalyzer.rank(ranked_once)
        assert Enum.map(ranked_once, & &1.id) == Enum.map(ranked_twice, & &1.id)
      end
    end

    property "healthy report produces zero gaps" do
      check all cr <- float(min: 0.0, max: 0.04),
                eq <- float(min: 0.71, max: 1.0),
                st <- float(min: 0.0, max: 0.19),
                pc <- float(min: 0.91, max: 1.0) do
        report = %{contradiction_rate: cr, evidence_quality: eq, stale_theory_rate: st,
          provenance_completeness: pc, experiment_recommendations: []}
        assert GapAnalyzer.analyze(report) == []
      end
    end
  end
end
