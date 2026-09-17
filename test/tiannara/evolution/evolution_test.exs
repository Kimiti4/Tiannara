defmodule Tiannara.Evolution.EvolutionTest do
  use ExUnit.Case, async: true

  alias Tiannara.Evolution.{StrategyBenchmarker, MetaLearner, ConstitutionalAuditor}

  describe "StrategyBenchmarker" do
    test "benchmarks strategies" do
      strategies = [
        %{id: "s1", name: "Strategy A"},
        %{id: "s2", name: "Strategy B"}
      ]

      history = [
        %{strategy_id: "s1", throughput: 0.8, quality: 0.7, efficiency: 0.6, novelty: 0.5, failure_rate: 0.1, speed: 0.7},
        %{strategy_id: "s1", throughput: 0.9, quality: 0.8, efficiency: 0.7, novelty: 0.6, failure_rate: 0.05, speed: 0.8},
        %{strategy_id: "s2", throughput: 0.5, quality: 0.9, efficiency: 0.8, novelty: 0.7, failure_rate: 0.2, speed: 0.4}
      ]

      results = StrategyBenchmarker.benchmark(strategies, history)

      assert length(results) == 2
      assert Enum.all?(results, fn r -> r.composite >= 0.0 and r.composite <= 1.0 end)
      scores = Enum.map(results, & &1.composite)
      assert scores == Enum.sort(scores, :desc)
    end

    test "compares two strategies" do
      strategy_a = %{id: "a"}
      strategy_b = %{id: "b"}

      history = [
        %{strategy_id: "a", throughput: 0.8, quality: 0.7, efficiency: 0.6, novelty: 0.5, failure_rate: 0.1, speed: 0.7},
        %{strategy_id: "b", throughput: 0.5, quality: 0.9, efficiency: 0.8, novelty: 0.7, failure_rate: 0.2, speed: 0.4}
      ]

      comparison = StrategyBenchmarker.compare(strategy_a, strategy_b, history)

      assert comparison.winner in [:a, :b, :tie]
      assert comparison.wins_a + comparison.wins_b <= 6
    end
  end

  describe "MetaLearner" do
    test "initializes with empty model" do
      model = MetaLearner.init_model()
      assert model.strategies == %{}
      assert model.total_observations == 0
    end

    test "updates model with observations" do
      model = MetaLearner.init_model()

      model = MetaLearner.update(model, "s1", true, %{domain: :physics, severity: :high})
      model = MetaLearner.update(model, "s1", false, %{domain: :physics, severity: :high})
      model = MetaLearner.update(model, "s1", true, %{domain: :biology, severity: :medium})

      assert model.total_observations == 3
      assert model.strategies["s1"].successes == 2
      assert model.strategies["s1"].failures == 1
    end

    test "selects strategy using Thompson Sampling" do
      model = MetaLearner.init_model()
      model = MetaLearner.update(model, "s1", true, %{domain: :physics, severity: :high})
      model = MetaLearner.update(model, "s1", true, %{domain: :physics, severity: :high})
      model = MetaLearner.update(model, "s2", false, %{domain: :physics, severity: :high})

      {strategy_id, score} = MetaLearner.select_strategy(%{domain: :physics, severity: :high}, model)

      assert strategy_id in ["s1", "s2"]
      assert score >= 0.0
    end

    test "computes success rate" do
      model = MetaLearner.init_model()
      model = MetaLearner.update(model, "s1", true, %{domain: :physics, severity: :high})
      model = MetaLearner.update(model, "s1", true, %{domain: :physics, severity: :high})
      model = MetaLearner.update(model, "s1", false, %{domain: :physics, severity: :high})

      rate = MetaLearner.success_rate(model, "s1", %{domain: :physics, severity: :high})
      assert_in_delta rate, 0.667, 0.01
    end
  end

  describe "ConstitutionalAuditor" do
    test "passes for compliant system" do
      state = %{
        capabilities_deployed: 10,
        verifications_completed: 10,
        hidden_uncertainty_count: 0,
        mandatory_reviews_completed: 5,
        mandatory_reviews_required: 5,
        lineage_violations: 0,
        safety_violations: 0,
        objective_alignment_score: 0.9,
        coupling_violations: 0,
        evolutions_deployed: 5,
        evolution_validations: 5
      }

      audit = ConstitutionalAuditor.audit(state)

      assert audit.status == :compliant
      assert audit.compliance_rate == 1.0
      assert audit.critical_violations == []
    end

    test "fails when capability outpaces verification" do
      state = %{
        capabilities_deployed: 10,
        verifications_completed: 3,
        hidden_uncertainty_count: 0,
        mandatory_reviews_completed: 0,
        mandatory_reviews_required: 0,
        lineage_violations: 0,
        safety_violations: 0,
        objective_alignment_score: 0.9,
        coupling_violations: 0,
        evolutions_deployed: 5,
        evolution_validations: 5
      }

      audit = ConstitutionalAuditor.audit(state)

      assert audit.status == :non_compliant
      assert Enum.any?(audit.critical_violations, fn v ->
        String.contains?(v.principle, "verification")
      end)
    end

    test "fails when uncertainty is hidden" do
      state = %{
        capabilities_deployed: 5,
        verifications_completed: 5,
        hidden_uncertainty_count: 3,
        mandatory_reviews_completed: 0,
        mandatory_reviews_required: 0,
        lineage_violations: 0,
        safety_violations: 0,
        objective_alignment_score: 0.9,
        coupling_violations: 0,
        evolutions_deployed: 2,
        evolution_validations: 2
      }

      audit = ConstitutionalAuditor.audit(state)
      assert audit.status == :non_compliant
    end
  end
end
