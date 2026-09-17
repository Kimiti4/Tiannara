defmodule Tiannara.Discovery.ExperimentPrioritizerPropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.Discovery.{ExperimentPlanner, DiscoveryPrioritizer, Discovery, DiscoveryScore}
  alias Tiannara.Discovery.Domain.{HypothesisSpec, PredictionSpec, KnowledgeGap}

  describe "ExperimentPlanner invariants" do
    property "every experiment has valid type" do
      check all causal_model <- member_of([
                    :boundary_condition_divergence, :measurement_divergence,
                    :hidden_confound, :temporal_evolution, :sample_size_deficit,
                    :collection_bias, :knowledge_supersession, :validation_deficit,
                    :unknown
                  ]) do
        hyp = HypothesisSpec.new(%{gap_id: "gap_prop", statement: "prop test", domain: :knowledge,
          prior: 0.5, metadata: %{causal_model: causal_model, strategy: :test}})
        pred = PredictionSpec.new(%{hypothesis_id: hyp.id, statement: "pred",
          falsification_criteria: "falsified", confidence: 0.5})
        experiments = ExperimentPlanner.plan(hyp, [pred])
        Enum.each(experiments, fn exp ->
          assert exp.type in [:controlled_simulation, :observation, :historical_replay, :data_mining]
        end)
      end
    end

    property "every experiment passes validation" do
      check all causal_model <- member_of([
                    :boundary_condition_divergence, :hidden_confound,
                    :temporal_evolution, :sample_size_deficit, :unknown
                  ]) do
        hyp = HypothesisSpec.new(%{gap_id: "gap_prop", statement: "prop test", domain: :knowledge,
          prior: 0.5, metadata: %{causal_model: causal_model, strategy: :test}})
        pred = PredictionSpec.new(%{hypothesis_id: hyp.id, statement: "pred",
          falsification_criteria: "falsified", confidence: 0.5})
        experiments = ExperimentPlanner.plan(hyp, [pred])
        Enum.each(experiments, fn exp ->
          assert ExperimentPlanner.validate(exp) == :ok
        end)
      end
    end

    property "estimated cost is always positive" do
      check all risk <- float(min: 0.0, max: 1.0) do
        hyp = HypothesisSpec.new(%{gap_id: "gap_prop", statement: "cost test", domain: :knowledge,
          prior: 0.5, risk: risk, metadata: %{causal_model: :hidden_confound, strategy: :test}})
        pred = PredictionSpec.new(%{hypothesis_id: hyp.id, statement: "pred",
          falsification_criteria: "falsified", confidence: 0.5})
        [exp] = ExperimentPlanner.plan(hyp, [pred])
        total = ExperimentPlanner.estimate_total_cost([exp])
        assert total.compute > 0
        assert total.memory > 0
        assert total.time_hours > 0
        assert total.energy > 0
      end
    end
  end

  describe "DiscoveryPrioritizer invariants" do
    property "rank is idempotent" do
      check all count <- integer(1..10) do
        discoveries = Enum.map(1..count, fn i ->
          gap = KnowledgeGap.new(%{domain: :"domain_#{i}", description: "gap #{i}",
            severity: :medium, estimated_impact: 0.5, source: :epistemic_integrity})
          Discovery.from_gap(gap)
        end)
        ranked_once = DiscoveryPrioritizer.rank(discoveries)
        ranked_twice = DiscoveryPrioritizer.rank(ranked_once)
        assert Enum.map(ranked_once, & &1.id) == Enum.map(ranked_twice, & &1.id)
      end
    end

    property "rank_with_diversity never returns more than max_same_domain per domain" do
      check all count <- integer(1..15) do
        discoveries = Enum.map(1..count, fn _ ->
          gap = KnowledgeGap.new(%{domain: :same_domain, description: "same",
            severity: :high, estimated_impact: 0.8, source: :epistemic_integrity})
          Discovery.from_gap(gap)
        end)
        ranked = DiscoveryPrioritizer.rank_with_diversity(discoveries)
        domain_count = Enum.count(ranked, fn d -> d.gap.domain == :same_domain end)
        assert domain_count <= 3
      end
    end

    property "systemic_bottleneck returns a valid dimension" do
      check all count <- integer(1..5) do
        discoveries = Enum.map(1..count, fn i ->
          gap = KnowledgeGap.new(%{domain: :"domain_#{i}", description: "gap",
            severity: :medium, estimated_impact: 0.5, source: :epistemic_integrity})
          Discovery.from_gap(gap)
        end)
        bottleneck = DiscoveryPrioritizer.systemic_bottleneck(discoveries)
        if bottleneck != nil do
          {dim, avg} = bottleneck
          assert dim in DiscoveryScore.dimensions()
          assert avg >= 0.0 and avg <= 1.0
        end
      end
    end
  end
end
