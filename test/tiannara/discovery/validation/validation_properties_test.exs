defmodule Tiannara.Discovery.Validation.ValidationPropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.Discovery.Validation.{StatisticalValidator, DiscoveryCertifier}
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Domain.{KnowledgeGap, DiscoveryResult, ExperimentPlan}
  alias Tiannara.Discovery.DiscoveryScore

  describe "StatisticalValidator invariants" do
    property "significance p-value is always in (0.0, 1.0]" do
      check all ev_count <- integer(1..5) do
        evidence = Enum.map(1..ev_count, fn i ->
          %DiscoveryResult{id: "ev_#{i}", experiment_id: "exp_#{i}", hypothesis_id: "hyp_1",
            outcome: :confirmed, evidence: [%{confidence: :rand.uniform(), source: :experiment}],
            confidence_delta: :rand.uniform() * 0.3 - 0.15, posterior: 0.5 + :rand.uniform() * 0.3,
            completed_at: DateTime.utc_now()}
        end)
        experiments = Enum.map(1..ev_count, fn i ->
          %ExperimentPlan{id: "exp_#{i}", hypothesis_id: "hyp_1", type: :controlled_simulation,
            inputs: %{x: 1}, outputs: %{y: 2}, variables: [:x], controls: [:z],
            stopping_criteria: %{max_iterations: 100}, success_criteria: ["p < 0.05"],
            failure_criteria: ["effect < 0.1"], estimated_cost: %{compute: 100, time_hours: 10},
            expected_information_gain: 0.5, created_at: DateTime.utc_now()}
        end)
        disc = %Discovery{id: "disc_prop", evidence: evidence, experiments: experiments,
          hypotheses: [%{id: "hyp_1", metadata: %{}}],
          confidence: 0.5, uncertainty: 0.5, status: :completed, lineage: [],
          score: %DiscoveryScore{novelty: 0.5, importance: 0.5, feasibility: 0.5, expected_information_gain: 0.5, reproducibility: 0.5, safety: 1.0, resource_efficiency: 0.5},
          created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), completed_at: DateTime.utc_now()}
        result = StatisticalValidator.validate(disc)
        assert result.p_value > 0.0 and result.p_value <= 1.0
        assert result.significant in [true, false]
      end
    end
  end

  describe "DiscoveryCertifier invariants" do
    property "overall_score is always in [0.0, 1.0]" do
      check all conf <- float(min: 0.0, max: 1.0) do
        disc = %Discovery{id: "disc_prop", confidence: conf, uncertainty: 1.0 - conf,
          evidence: [], experiments: [], hypotheses: [], predictions: [],
          status: :completed, lineage: [], workflow_ids: [], metadata: %{},
          conclusion: nil, question: nil, gap: nil, score: %DiscoveryScore{novelty: 0.5, importance: 0.5, feasibility: 0.5, expected_information_gain: 0.5, reproducibility: 0.5, safety: 1.0, resource_efficiency: 0.5},
          created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), completed_at: nil}
        report = DiscoveryCertifier.validate(disc)
        assert report.overall_score >= 0.0 and report.overall_score <= 1.0
        assert report.certification.level in [:certified, :provisional, :uncertified, :rejected]
      end
    end
  end
end
