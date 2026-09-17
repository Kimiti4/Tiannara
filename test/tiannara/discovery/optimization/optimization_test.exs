defmodule Tiannara.Discovery.Optimization.OptimizationTest do
  use ExUnit.Case, async: true
  alias Tiannara.Discovery.Optimization.{ActiveLearner, EarlyStoppingEvaluator, AdaptiveRedesigner}
  alias Tiannara.Discovery.ExperimentPlanner
  alias Tiannara.Discovery.Domain.{HypothesisSpec, ExperimentPlan, DiscoveryResult}

  defp test_hypothesis(gap_id, opts \\ []) do
    HypothesisSpec.new(%{gap_id: gap_id, description: opts[:description] || "test hyp", statement: "test statement", domain: :test,
      prior: opts[:prior] || 0.5, expected_information_gain: opts[:eig] || 0.7, risk: opts[:risk] || 0.3,
      metadata: %{causal_model: opts[:causal_model] || :direct, strategy: opts[:strategy] || :test, novelty: opts[:novelty] || 0.6}})
  end

  defp test_experiment(hyp_id, opts \\ []) do
    %ExperimentPlan{id: opts[:id] || "exp_#{:erlang.unique_integer([:positive])}", hypothesis_id: hyp_id,
      type: opts[:type] || :controlled_simulation, prediction_ids: [],
      inputs: %{x: 1}, outputs: %{y: 2}, variables: [:x], controls: [:z],
      stopping_criteria: %{max_iterations: 100, max_duration_hours: 72},
      success_criteria: ["p < 0.05"], failure_criteria: ["effect < 0.1"],
      estimated_cost: %{compute: opts[:compute] || 100, time_hours: opts[:time] || 10},
      expected_information_gain: opts[:eig] || 0.6, created_at: DateTime.utc_now()}
  end

  defp test_result(exp_id, hyp_id, opts \\ []) do
    %DiscoveryResult{id: "res_#{:erlang.unique_integer([:positive])}", experiment_id: exp_id,
      hypothesis_id: hyp_id, outcome: opts[:outcome] || :confirmed,
      evidence: [%{confidence: opts[:confidence] || 0.8, source: :experiment}],
      confidence_delta: opts[:delta] || 0.1, posterior: opts[:posterior] || 0.8,
      completed_at: DateTime.utc_now()}
  end

  describe "ActiveLearner" do
    test "select_next/2 returns experiment" do
      hyp1 = test_hypothesis("gap_1", %{eig: 0.9, novelty: 0.8})
      hyp2 = test_hypothesis("gap_1", %{eig: 0.3, novelty: 0.2, risk: 0.1})
      exp_a = test_experiment(hyp1.id, %{compute: 10})
      exp_b = test_experiment(hyp2.id, %{compute: 100})
      {selected, _score} = ActiveLearner.select_next([exp_a, exp_b], [hyp1, hyp2])
      assert selected.id == exp_a.id
    end

    test "select_next/2 returns nil with empty experiments" do
      assert ActiveLearner.select_next([], [test_hypothesis("gap_1")]) == nil
    end

    test "rank_by_eig/2 returns sorted experiments" do
      hyp = test_hypothesis("gap_1")
      experiments = [test_experiment(hyp.id, %{eig: 0.3}),
                     test_experiment(hyp.id, %{eig: 0.9}),
                     test_experiment(hyp.id, %{eig: 0.5})]
      ranked = ActiveLearner.rank_by_eig(experiments, [hyp])
      {_first, first_eig} = Enum.at(ranked, 0)
      {_last, last_eig} = Enum.at(ranked, 2)
      assert first_eig >= last_eig
    end

    test "compute_eig/2 returns numeric value" do
      hyp = test_hypothesis("gap_1")
      exp = test_experiment(hyp.id, %{eig: 0.7})
      eig = ActiveLearner.compute_eig(exp, [hyp])
      assert eig >= 0.0 and eig <= 1.0
    end

    test "ucb/2 returns upper confidence bound" do
      hyp = test_hypothesis("gap_1")
      exp = test_experiment(hyp.id)
      ucb = ActiveLearner.ucb(exp, [hyp])
      assert ucb >= 0.0
    end

    test "optimal_sequence/2 returns sequence of experiments" do
      hyp = test_hypothesis("gap_1")
      experiments = [test_experiment(hyp.id)]
      sequence = ActiveLearner.optimal_sequence(experiments, [hyp])
      assert is_list(sequence)
    end
  end

  describe "EarlyStoppingEvaluator" do
    test "evaluate/3 returns stop reason" do
      exp = test_experiment("hyp_1", %{id: "exp_1"})
      results = [test_result("exp_1", "hyp_1")]
      reason = EarlyStoppingEvaluator.evaluate(exp, results)
      assert reason in [:continue, :falsified, :success, :diminishing_returns, :budget_exceeded]
    end

    test "optimal_stopping_point/2 returns non-negative integer" do
      results = [test_result("exp_1", "hyp_1"), test_result("exp_1", "hyp_1")]
      point = EarlyStoppingEvaluator.optimal_stopping_point(results, 0.01)
      assert is_integer(point)
      assert point >= 0
    end
  end

  describe "AdaptiveRedesigner" do
    test "redesign/2 returns redesign tuple" do
      exp = test_experiment("hyp_1")
      results = [test_result(exp.id, "hyp_1", %{outcome: :inconclusive, confidence: 0.4})]
      result = AdaptiveRedesigner.redesign(exp, results)
      assert elem(result, 0) in [:redesign, :no_change]
      assert is_struct(elem(result, 1), ExperimentPlan)
    end

    test "adaptation_history/2 returns list of changes" do
      exp = test_experiment("hyp_1")
      results = [test_result(exp.id, "hyp_1", %{outcome: :inconclusive})]
      history = AdaptiveRedesigner.adaptation_history(exp, results)
      assert is_list(history)
    end
  end
end
