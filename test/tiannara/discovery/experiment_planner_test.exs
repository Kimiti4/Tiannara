defmodule Tiannara.Discovery.ExperimentPlannerTest do
  use ExUnit.Case, async: true
  alias Tiannara.Discovery.ExperimentPlanner
  alias Tiannara.Discovery.Domain.{HypothesisSpec, PredictionSpec, ExperimentPlan}

  defp test_hypothesis(causal_model \\ :hidden_confound) do
    HypothesisSpec.new(%{gap_id: "gap_1", statement: "Test hypothesis", domain: :epistemic_consistency,
      prior: 0.5, expected_information_gain: 0.7, risk: 0.3, metadata: %{causal_model: causal_model, strategy: :test}})
  end

  defp test_prediction(hyp_id \\ "hyp_1") do
    PredictionSpec.new(%{hypothesis_id: hyp_id, statement: "Test prediction",
      falsification_criteria: "Result inconsistent with hypothesis (p < 0.05)", confidence: 0.6, uncertainty: 0.4})
  end

  describe "plan/2" do
    test "produces one experiment per prediction" do
      hyp = test_hypothesis()
      preds = [test_prediction(hyp.id), test_prediction(hyp.id)]
      experiments = ExperimentPlanner.plan(hyp, preds)
      assert length(experiments) == 2
      assert Enum.all?(experiments, &is_struct(&1, ExperimentPlan))
    end

    test "every experiment has a hypothesis_id" do
      hyp = test_hypothesis()
      experiments = ExperimentPlanner.plan(hyp, [test_prediction(hyp.id)])
      assert Enum.all?(experiments, &(&1.hypothesis_id == hyp.id))
    end

    test "every experiment has success and failure criteria" do
      hyp = test_hypothesis()
      experiments = ExperimentPlanner.plan(hyp, [test_prediction(hyp.id)])
      Enum.each(experiments, fn exp ->
        assert exp.success_criteria != nil and exp.success_criteria != []
        assert exp.failure_criteria != nil and exp.failure_criteria != []
      end)
    end

    test "every experiment has stopping criteria" do
      hyp = test_hypothesis()
      experiments = ExperimentPlanner.plan(hyp, [test_prediction(hyp.id)])
      Enum.each(experiments, fn exp ->
        assert exp.stopping_criteria != nil
        assert Map.has_key?(exp.stopping_criteria, :max_iterations)
        assert Map.has_key?(exp.stopping_criteria, :max_duration_hours)
      end)
    end

    test "selects experiment type based on causal model" do
      [exp_sim] = ExperimentPlanner.plan(test_hypothesis(:boundary_condition_divergence), [test_prediction("h1")])
      [exp_obs] = ExperimentPlanner.plan(test_hypothesis(:measurement_divergence), [test_prediction("h2")])
      [exp_replay] = ExperimentPlanner.plan(test_hypothesis(:temporal_evolution), [test_prediction("h3")])
      [exp_mining] = ExperimentPlanner.plan(test_hypothesis(:sample_size_deficit), [test_prediction("h4")])
      assert exp_sim.type == :controlled_simulation
      assert exp_obs.type == :observation
      assert exp_replay.type == :historical_replay
      assert exp_mining.type == :data_mining
    end

    test "returns empty list for empty predictions" do
      assert ExperimentPlanner.plan(test_hypothesis(), []) == []
    end
  end

  describe "validate/1" do
    test "returns :ok for valid experiment" do
      [exp] = ExperimentPlanner.plan(test_hypothesis(), [test_prediction("h1")])
      assert ExperimentPlanner.validate(exp) == :ok
    end

    test "returns error for missing hypothesis_id" do
      exp = ExperimentPlan.new(%{type: :controlled_simulation, success_criteria: ["x"], failure_criteria: ["y"], stopping_criteria: %{}})
      assert {:error, :missing_hypothesis_id} = ExperimentPlanner.validate(exp)
    end

    test "returns error for missing success criteria" do
      exp = ExperimentPlan.new(%{hypothesis_id: "h1", type: :controlled_simulation, failure_criteria: ["y"], stopping_criteria: %{}})
      assert {:error, :missing_success_criteria} = ExperimentPlanner.validate(exp)
    end
  end

  describe "estimate_total_cost/1" do
    test "sums costs across experiments" do
      hyp = test_hypothesis()
      experiments = ExperimentPlanner.plan(hyp, [test_prediction(hyp.id), test_prediction(hyp.id)])
      total = ExperimentPlanner.estimate_total_cost(experiments)
      assert total.compute > 0
      assert total.memory > 0
      assert total.time_hours > 0
      assert total.energy > 0
    end
  end
end
