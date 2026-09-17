defmodule Tiannara.Discovery.Advanced.AdvancedDiscoveryTest do
  use ExUnit.Case, async: true
  alias Tiannara.Discovery.Advanced.{CrossDomainDiscovery, AnalogicalReasoner, NoveltyDetector, HypothesisDiversityEngine, DiscoveryPortfolioOptimizer}
  alias Tiannara.Discovery.{Discovery, DiscoveryScore}
  alias Tiannara.Discovery.Domain.{KnowledgeGap, HypothesisSpec, ExperimentPlan}

  defp test_discovery(domain, opts \\ []) do
    gap = KnowledgeGap.new(%{domain: domain, description: opts[:description] || "test gap", severity: opts[:severity] || :high, estimated_impact: opts[:impact] || 0.7, source: :epistemic_integrity})
    experiments = if opts[:with_experiments] != false, do: [
      %ExperimentPlan{id: "exp1", type: :controlled_simulation, inputs: %{}, outputs: %{}, variables: [], controls: [], estimated_cost: %{compute: 100, time_hours: 10}, success_criteria: [], failure_criteria: [], stopping_criteria: %{}, created_at: DateTime.utc_now()},
      %ExperimentPlan{id: "exp2", type: :observation, inputs: %{}, outputs: %{}, variables: [], controls: [], estimated_cost: %{compute: 50, time_hours: 5}, success_criteria: [], failure_criteria: [], stopping_criteria: %{}, created_at: DateTime.utc_now()}
    ], else: []
    %Discovery{
      id: "disc_#{domain}_#{:erlang.unique_integer([:positive])}",
      gap: gap,
      question: "What explains test gap?",
      hypotheses: Enum.map(1..(opts[:hyp_count] || 2), fn i ->
        HypothesisSpec.new(%{gap_id: gap.id, description: "hyp #{i}", prior: 0.3 + i * 0.1,
          metadata: %{causal_model: opts[:causal_model] || :direct, strategy: opts[:strategy] || :test, novelty: 0.4 + i * 0.1},
          expected_information_gain: 0.5})
      end),
      experiments: experiments,
      evidence: [],
      predictions: [],
      confidence: opts[:confidence] || 0.75,
      uncertainty: opts[:uncertainty] || 0.25,
      score: %DiscoveryScore{novelty: 0.6, importance: 0.7, feasibility: 0.8, expected_information_gain: 0.65, reproducibility: 0.7, safety: 0.9, resource_efficiency: 0.6},
      status: :hypotheses_generated,
      conclusion: nil, lineage: [], workflow_ids: [], metadata: %{},
      created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), completed_at: nil
    }
  end

  describe "CrossDomainDiscovery" do
    test "discover/2 returns connections" do
      gaps = [KnowledgeGap.new(%{domain: :biology, description: "test", severity: :high, estimated_impact: 0.7})]
      knowledge = [%{id: "k1", domain: :physics, type: :pattern, description: "harmonic oscillator", domain_saturation: 0.5, confidence: 0.8},
                   %{id: "k2", domain: :chemistry, type: :principle, description: "rate law", domain_saturation: 0.7, confidence: 0.9}]
      result = CrossDomainDiscovery.discover(gaps, knowledge)
      assert is_list(result)
    end

    test "find_analogs/2 returns potential analogs" do
      gap = KnowledgeGap.new(%{domain: :biology, description: "cell differentiation", severity: :high, estimated_impact: 0.8})
      knowledge = [%{id: "k1", domain: :physics, type: :pattern, description: "phase transitions", domain_saturation: 0.4, confidence: 0.85}]
      result = CrossDomainDiscovery.find_analogs(gap, knowledge)
      assert is_list(result)
    end
  end

  describe "AnalogicalReasoner" do
    test "reason/2 returns analogies" do
      source = %{domain: :biology, type: :model, description: "immune system",
        principles: [%{statement: "Pattern recognition cells identify threats", structure: %{subject: :cell, action: :recognize, object: :threat}}]}
      target = %{domain: :software_engineering, description: "concurrency bug detection",
        principles: [%{statement: "Threads compete for resources", structure: %{subject: :thread, action: :compete, object: :resource}}]}
      result = AnalogicalReasoner.reason(source, target)
      assert is_list(result)
    end

    test "evaluate_mapping/1 returns quality score" do
      mapping = %{quality: 0.8, source_domain: :biology, target_domain: :software_engineering, shared_elements: [:pattern_recognition, :competition], correspondences: [], source_features: [], target_features: []}
      result = AnalogicalReasoner.evaluate_mapping(mapping)
      assert result >= 0.0 and result <= 1.0
    end
  end

  describe "NoveltyDetector" do
    test "score/2 returns novelty scores" do
      disc = test_discovery(:physics)
      existing = [%{id: "k1", domain: :physics, type: :discovery, concepts: [:entropy, :thermodynamics], methods: [:controlled_simulation]}]
      result = NoveltyDetector.score(disc, existing)
      assert Map.has_key?(result, :composite)
      assert result.composite >= 0.0 and result.composite <= 1.0
      assert Map.has_key?(result, :classification)
    end

    test "novel?/2 returns boolean" do
      disc = test_discovery(:novel_domain)
      assert NoveltyDetector.novel?(disc, []) == true
    end

    test "novel?/2 returns false for well-known discoveries" do
      disc = test_discovery(:well_known, %{hyp_count: 1})
      existing = [%{id: "k1", domain: :well_known, type: :discovery, concepts: [:test], methods: [:controlled_simulation]}]
      refute NoveltyDetector.novel?(disc, existing)
    end
  end

  describe "HypothesisDiversityEngine" do
    test "assess/1 returns diversity assessment" do
      hyps = [
        HypothesisSpec.new(%{gap_id: "g1", description: "h1", prior: 0.5, metadata: %{causal_model: :direct, strategy: :deductive, novelty: 0.4}}),
        HypothesisSpec.new(%{gap_id: "g1", description: "h2", prior: 0.3, metadata: %{causal_model: :indirect, strategy: :inductive, novelty: 0.7}}),
        HypothesisSpec.new(%{gap_id: "g1", description: "h3", prior: 0.8, metadata: %{causal_model: :null, strategy: :falsification, novelty: 0.5}})
      ]
      result = HypothesisDiversityEngine.assess(hyps)
      assert Map.has_key?(result, :composite)
      assert result.composite >= 0.0 and result.composite <= 1.0
      assert Map.has_key?(result, :sufficient)
    end

    test "suggest_additions/1 returns suggestions for single hypothesis" do
      hyps = [
        HypothesisSpec.new(%{gap_id: "g1", description: "h1", prior: 0.5, metadata: %{causal_model: :direct, strategy: :deductive, novelty: 0.4}})
      ]
      suggestions = HypothesisDiversityEngine.suggest_additions(hyps)
      assert is_list(suggestions)
      assert length(suggestions) > 0
    end
  end

  describe "DiscoveryPortfolioOptimizer" do
    test "optimize/2 selects discoveries within budget" do
      discoveries = [test_discovery(:physics), test_discovery(:biology), test_discovery(:chemistry)]
      result = DiscoveryPortfolioOptimizer.optimize(discoveries, %{max_active: 2, budget: 1000})
      assert length(result.selected) <= 2
      assert Map.has_key?(result, :allocations)
      assert Map.has_key?(result, :portfolio_diversity)
    end

    test "optimize/2 with empty constraints" do
      disc = test_discovery(:physics)
      result = DiscoveryPortfolioOptimizer.optimize([disc], %{})
      assert length(result.selected) == 1
    end

    test "compute_portfolio_diversity/1 returns 1.0 for single item" do
      diversity = DiscoveryPortfolioOptimizer.compute_portfolio_diversity([%{discovery: test_discovery(:physics)}])
      assert diversity == 1.0
    end
  end
end
