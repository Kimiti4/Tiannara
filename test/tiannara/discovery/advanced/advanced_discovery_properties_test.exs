defmodule Tiannara.Discovery.Advanced.AdvancedDiscoveryPropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.Discovery.Advanced.{NoveltyDetector, HypothesisDiversityEngine, DiscoveryPortfolioOptimizer}
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Domain.{KnowledgeGap, HypothesisSpec, ExperimentPlan}
  alias Tiannara.Discovery.DiscoveryScore

  describe "NoveltyDetector invariants" do
    property "novelty composite is always in [0.0, 1.0]" do
      check all domain <- member_of([:physics, :biology, :chemistry, :novel]),
                hyp_count <- integer(1..4) do
        gap = KnowledgeGap.new(%{domain: domain, description: "property test gap", severity: :medium, estimated_impact: 0.5})
        disc = %Discovery{id: "disc_prop", gap: gap,
          hypotheses: Enum.map(1..hyp_count, fn _ ->
            HypothesisSpec.new(%{gap_id: gap.id, description: "prop hyp", prior: 0.5, metadata: %{causal_model: :direct, novelty: 0.5}})
          end),
          experiments: [], evidence: [], predictions: [],
          confidence: 0.5, uncertainty: 0.5, status: :hypotheses_generated,
          score: %DiscoveryScore{novelty: 0.5, importance: 0.5, feasibility: 0.5, expected_information_gain: 0.5, reproducibility: 0.5, safety: 1.0, resource_efficiency: 0.5},
          lineage: [], workflow_ids: [], metadata: %{},
          created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), completed_at: nil}
        result = NoveltyDetector.score(disc, [])
        assert result.composite >= 0.0 and result.composite <= 1.0
        assert result.classification in [:groundbreaking, :significant, :incremental, :minor, :negligible]
      end
    end
  end

  describe "HypothesisDiversityEngine invariants" do
    property "composite diversity is always in [0.0, 1.0]" do
      check all hyp_count <- integer(1..5) do
        hyps = Enum.map(1..hyp_count, fn i ->
          HypothesisSpec.new(%{gap_id: "g_prop", description: "h#{i}", prior: :rand.uniform(),
            metadata: %{causal_model: Enum.random([:direct, :indirect, :null]), strategy: Enum.random([:deductive, :inductive, :falsification]), novelty: :rand.uniform()}})
        end)
        result = HypothesisDiversityEngine.assess(hyps)
        assert result.composite >= 0.0 and result.composite <= 1.0
      end
    end

    property "diversity is higher with more diverse hypotheses" do
      check all _u <- constant(nil) do
        low_diversity = [HypothesisSpec.new(%{gap_id: "g", description: "h1", prior: 0.5, metadata: %{causal_model: :direct, strategy: :deductive, novelty: 0.4}}),
                         HypothesisSpec.new(%{gap_id: "g", description: "h2", prior: 0.45, metadata: %{causal_model: :direct, strategy: :deductive, novelty: 0.45}})]
        high_diversity = [HypothesisSpec.new(%{gap_id: "g", description: "h1", prior: 0.1, metadata: %{causal_model: :direct, strategy: :deductive, novelty: 0.1}}),
                          HypothesisSpec.new(%{gap_id: "g", description: "h2", prior: 0.9, metadata: %{causal_model: :null, strategy: :falsification, novelty: 0.9}})]
        low_result = HypothesisDiversityEngine.assess(low_diversity)
        high_result = HypothesisDiversityEngine.assess(high_diversity)
        assert high_result.composite > low_result.composite
      end
    end
  end

  describe "DiscoveryPortfolioOptimizer invariants" do
    property "selected count never exceeds max_active" do
      check all disc_count <- integer(1..5),
                max_active <- integer(1..5) do
        discoveries = Enum.map(1..disc_count, fn i ->
          gap = KnowledgeGap.new(%{domain: :"domain_#{i}", description: "prop disc", severity: :medium, estimated_impact: 0.5})
          %Discovery{id: "disc_#{i}", gap: gap, question: nil,
            hypotheses: [HypothesisSpec.new(%{gap_id: gap.id, description: "prop hyp", prior: 0.5, metadata: %{}})], predictions: [],
            experiments: [%ExperimentPlan{id: "exp_#{i}", hypothesis_id: "hyp_#{i}", estimated_cost: %{compute: 50, time_hours: 5}}],
            evidence: [], conclusion: nil, confidence: 0.5, uncertainty: 0.5, status: :hypotheses_generated,
            score: %DiscoveryScore{novelty: 0.5, importance: 0.5, feasibility: 0.5, expected_information_gain: 0.5, reproducibility: 0.5, safety: 1.0, resource_efficiency: 0.5},
            lineage: [], workflow_ids: [], metadata: %{},
            created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), completed_at: nil}
        end)
        result = DiscoveryPortfolioOptimizer.optimize(discoveries, %{max_active: max_active, budget: 10000})
        assert length(result.selected) <= max_active
      end
    end
  end
end
