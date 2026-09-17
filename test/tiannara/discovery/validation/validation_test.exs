defmodule Tiannara.Discovery.Validation.ValidationTest do
  use ExUnit.Case, async: true
  alias Tiannara.Discovery.Validation.{StatisticalValidator, ReplicationPlanner, EvidenceAuditor, DiscoveryCertifier}
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Domain.{KnowledgeGap, HypothesisSpec, ExperimentPlan, DiscoveryResult, PredictionSpec}
  alias Tiannara.Discovery.DiscoveryScore

  defp test_discovery(opts \\ []) do
    gap = KnowledgeGap.new(%{domain: opts[:domain] || :test, description: opts[:description] || "test gap", severity: opts[:severity] || :high, estimated_impact: opts[:impact] || 0.7})
    %Discovery{
      id: "disc_test_1",
      gap: gap,
      question: "What explains test gap?",
      confidence: opts[:confidence] || 0.75,
      uncertainty: 1.0 - (opts[:confidence] || 0.75),
      evidence: opts[:evidence] || [
        %DiscoveryResult{id: "ev1", experiment_id: "exp1", hypothesis_id: "hyp1", outcome: :confirmed, evidence: [%{confidence: 0.8, source: :experiment}], confidence_delta: 0.1, posterior: 0.8, completed_at: DateTime.utc_now()},
        %DiscoveryResult{id: "ev2", experiment_id: "exp2", hypothesis_id: "hyp1", outcome: :confirmed, evidence: [%{confidence: 0.7, source: :experiment}], confidence_delta: 0.05, posterior: 0.75, completed_at: DateTime.utc_now()},
        %DiscoveryResult{id: "ev3", experiment_id: "exp3", hypothesis_id: "hyp1", outcome: :confirmed, evidence: [%{confidence: 0.9, source: :experiment}], confidence_delta: 0.05, posterior: 0.9, completed_at: DateTime.utc_now()}
      ],
      experiments: [
        %ExperimentPlan{id: "exp1", type: :controlled_simulation, inputs: %{x: 1}, outputs: %{y: 2}, variables: [:x], controls: [:z], stopping_criteria: %{max_iterations: 100}, success_criteria: ["p < 0.05"], failure_criteria: ["effect < 0.1"], estimated_cost: %{compute: 100, time_hours: 10}, expected_information_gain: 0.6, created_at: DateTime.utc_now()},
        %ExperimentPlan{id: "exp2", type: :observation, inputs: %{a: 1}, outputs: %{b: 2}, variables: [:a], controls: [:c], stopping_criteria: %{max_iterations: 50}, success_criteria: ["p < 0.05"], failure_criteria: ["no effect"], estimated_cost: %{compute: 50, time_hours: 5}, expected_information_gain: 0.5, created_at: DateTime.utc_now()}
      ],
      hypotheses: [
        HypothesisSpec.new(%{gap_id: gap.id, description: "hypothesis 1", statement: "direct causal link", prior: 0.5, metadata: %{causal_model: :direct, strategy: :test}, novelty: 0.6}),
        HypothesisSpec.new(%{gap_id: gap.id, description: "hypothesis 2", statement: "indirect mediation", prior: 0.3, metadata: %{causal_model: :indirect, strategy: :alternative}, novelty: 0.7})
      ],
      status: :completed,
      score: %DiscoveryScore{novelty: 0.6, importance: 0.7, feasibility: 0.8, expected_information_gain: 0.65, reproducibility: 0.7, safety: 0.9, resource_efficiency: 0.6},
      lineage: [], workflow_ids: [], metadata: %{}, predictions: [], conclusion: nil,
      created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), completed_at: DateTime.utc_now()
    }
  end

  describe "StatisticalValidator" do
    test "validate/1 returns validation result" do
      disc = test_discovery()
      result = StatisticalValidator.validate(disc)
      assert result.significant in [true, false]
      assert result.p_value > 0.0 and result.p_value <= 1.0
    end

    test "statistically_supported?/1 returns boolean" do
      disc = test_discovery()
      assert StatisticalValidator.statistically_supported?(disc) in [true, false]
    end
  end

  describe "ReplicationPlanner" do
    test "plan/1 produces replication plan" do
      disc = test_discovery()
      replication = ReplicationPlanner.plan(disc)
      assert replication.discovery_id == disc.id
      assert length(replication.replication_experiments) >= 1
    end

    test "sufficiently_replicated?/1 returns boolean" do
      disc = test_discovery()
      assert ReplicationPlanner.sufficiently_replicated?(disc) in [true, false]
    end
  end

  describe "EvidenceAuditor" do
    test "audit/1 returns score and findings" do
      disc = test_discovery()
      {score, findings} = EvidenceAuditor.audit(disc)
      assert score >= 0.0 and score <= 1.0
      assert is_list(findings)
    end

    test "audit/1 with minimal evidence returns lower score" do
      disc = test_discovery(%{evidence: []})
      {score, _findings} = EvidenceAuditor.audit(disc)
      assert score < 0.5
    end
  end

  describe "DiscoveryCertifier" do
    test "validate/1 returns validation report" do
      disc = test_discovery()
      report = DiscoveryCertifier.validate(disc)
      assert report.overall_score >= 0.0 and report.overall_score <= 1.0
      assert report.certification.level in [:certified, :provisional, :uncertified, :rejected]
    end

    test "certified?/1 returns boolean" do
      disc = test_discovery()
      assert DiscoveryCertifier.certified?(disc) in [true, false]
    end

    test "certified?/1 returns false for low quality discovery" do
      disc = test_discovery(%{evidence: [], experiments: [], confidence: 0.2})
      refute DiscoveryCertifier.certified?(disc)
    end

    test "summarize/1 returns string" do
      disc = test_discovery()
      report = DiscoveryCertifier.validate(disc)
      summary = DiscoveryCertifier.summarize(report)
      assert is_binary(summary)
      assert String.contains?(summary, disc.id)
    end
  end
end
