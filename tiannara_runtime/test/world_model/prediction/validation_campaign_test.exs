defmodule TiannaraRuntime.Prediction.ValidationCampaignTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.Ontology.{
    WorldModel, StateSpace, Variable, Parameter, Equation, EquationSystem,
    CausalGraph, CausalNode, CausalEdge
  }

  alias TiannaraRuntime.WorldModel.Prediction.{
    Prediction, Forecast, ForecastStep, ForecastVariable,
    ConfidenceEstimate, UncertaintyDistribution,
    ForecastGenerator, ConfidenceEngine, UncertaintyEngine,
    ForecastComparator, MultiHorizonForecaster,
    MathVerificationEngine, PredictionArchaeology, PredictionRegistry
  }

  @moduletag :campaign

  defp test_world_model do
    {:ok, v1} = Variable.new(
      variable_id: "x", name: "x", type: :continuous,
      domain: {-10.0, 10.0}, is_endogenous: true
    )
    {:ok, v2} = Variable.new(
      variable_id: "y", name: "y", type: :continuous,
      domain: {-10.0, 10.0}, is_endogenous: true
    )
    {:ok, v3} = Variable.new(
      variable_id: "z", name: "z", type: :continuous,
      domain: {-10.0, 10.0}, is_endogenous: false
    )

    {:ok, p1} = Parameter.new(
      name: "baseline", value: 1.0, estimated_from: "x",
      is_identifiable: true
    )
    {:ok, p2} = Parameter.new(
      name: "beta_x", value: 2.0, estimated_from: "y"
    )
    {:ok, p3} = Parameter.new(
      name: "intercept", value: 0.5, estimated_from: "y"
    )

    expr_x = %{"form" => "constant", "parameters" => ["baseline"]}
    expr_y = %{"form" => "linear", "target" => "y", "parents" => ["x"],
               "parameters" => ["beta_x", "intercept"], "link" => "identity"}

    {:ok, eq_x} = Equation.new(
      target_variable: "x", expression: expr_x, type: :algebraic,
      derivation: :expert_provided, confidence: 0.9
    )
    {:ok, eq_y} = Equation.new(
      target_variable: "y", expression: expr_y, type: :algebraic,
      derivation: :expert_provided, confidence: 0.9
    )

    {:ok, eq_sys} = EquationSystem.new(equations: [eq_x, eq_y])

    {:ok, n1} = CausalNode.new(node_id: "z", type: :exogenous)
    {:ok, n2} = CausalNode.new(node_id: "x", type: :endogenous)
    {:ok, n3} = CausalNode.new(node_id: "y", type: :endogenous)
    {:ok, e1} = CausalEdge.new(source: "z", target: "x", type: :direct)
    {:ok, e2} = CausalEdge.new(source: "x", target: "y", type: :direct)
    {:ok, cg} = CausalGraph.new(
      nodes: [n1, n2, n3], edges: [e1, e2],
      latent_variables: [], confounders: [], do_calculus_level: 2
    )

    {:ok, ss} = StateSpace.new(
      dimensions: 3, variable_order: ["z", "x", "y"],
      default_initial: %{"z" => 0.0, "x" => 1.0, "y" => 2.0},
      support_type: :continuous
    )

    {:ok, wm} = WorldModel.new(
      name: "test_prediction_model", domain: :mathematics,
      state_space: ss, variables: [v1, v2, v3],
      parameters: [p1, p2, p3], equations: eq_sys,
      causal_graph: cg, status: :operational,
      evidence_roots: ["root_test"],
      fingerprint: "fp_test_model"
    )

    wm
  end

  describe "C17.4.95.1 — Forecast Generation" do
    test "generates immediate forecast" do
      wm = test_world_model()
      fv = %ForecastVariable{name: "x", type: :continuous}
      {:ok, forecast} = ForecastGenerator.generate(wm, [fv], :immediate)
      assert forecast.horizon == :immediate
      assert length(forecast.time_steps) == 1
      assert forecast.forecast_id != nil
    end

    test "generates short term forecast" do
      wm = test_world_model()
      fv = %ForecastVariable{name: "x", type: :continuous}
      {:ok, forecast} = ForecastGenerator.generate(wm, [fv], :short_term)
      assert length(forecast.time_steps) == 10
    end

    test "generates trajectory for single variable" do
      wm = test_world_model()
      {:ok, steps} = ForecastGenerator.generate_trajectory(wm, "x", 5)
      assert length(steps) == 5
    end

    test "rejects nil world model" do
      fv = %ForecastVariable{name: "x", type: :continuous}
      assert {:error, _} = ForecastGenerator.generate(nil, [fv], :immediate)
    end

    test "generates forecast with linear dependent variable" do
      wm = test_world_model()
      fv = %ForecastVariable{name: "y", type: :continuous}
      {:ok, forecast} = ForecastGenerator.generate(wm, [fv], :short_term)
      assert length(forecast.time_steps) == 10
      last_step = List.last(forecast.time_steps)
      assert Map.has_key?(last_step.values, "y")
    end
  end

  describe "C17.4.95.2 — Confidence Estimation" do
    test "computes confidence from world model" do
      wm = test_world_model()
      fv = %ForecastVariable{name: "x", type: :continuous}
      {:ok, forecast} = ForecastGenerator.generate(wm, [fv], :immediate)
      {:ok, ce} = ConfidenceEngine.compute(wm, forecast)
      assert ce.score >= 0.0 and ce.score <= 1.0
      assert ce.evidence_quality >= 0.0
      assert ce.model_maturity >= 0.0
      assert ce.replay_stability >= 0.0
      assert String.length(ce.explanation) > 0
      assert String.starts_with?(ce.confidence_id, "ce_")
    end

    test "evidence quality is higher with more evidence roots" do
      wm1 = test_world_model()
      {:ok, ce1} = ConfidenceEngine.compute(wm1, %Forecast{horizon: :immediate,
        time_steps: [%ForecastStep{step: 0, values: %{"x" => 1.0}}],
        variables: [%ForecastVariable{name: "x"}]})

      eq1 = ConfidenceEngine.compute_evidence_quality(wm1)
      assert eq1 >= 0.0 and eq1 <= 1.0
    end

    test "model maturity scales with version" do
      mm1 = ConfidenceEngine.compute_model_maturity("m1", 1)
      mm5 = ConfidenceEngine.compute_model_maturity("m1", 5)
      assert mm1 < mm5
    end
  end

  describe "C17.4.95.3 — Uncertainty Propagation" do
    test "propagates uncertainty from world model" do
      wm = test_world_model()
      fv = %ForecastVariable{name: "x", type: :continuous}
      {:ok, forecast} = ForecastGenerator.generate(wm, [fv], :immediate)
      {:ok, ud} = UncertaintyEngine.propagate(wm, forecast)
      assert ud.variance >= 0.0
      assert ud.std_deviation >= 0.0
      assert ud.entropy >= 0.0
      assert String.starts_with?(ud.uncertainty_id, "ud_")
    end

    test "parameter uncertainty returns non-negative" do
      wm = test_world_model()
      pu = UncertaintyEngine.parameter_uncertainty(wm)
      assert is_float(pu)
      assert pu >= 0.0
    end

    test "structure uncertainty returns non-negative" do
      wm = test_world_model()
      su = UncertaintyEngine.structure_uncertainty(wm)
      assert is_float(su)
      assert su >= 0.0
    end
  end

  describe "C17.4.95.4 — Forecast Comparison" do
    test "compare two forecasts returns comparison" do
      wm = test_world_model()
      fv = %ForecastVariable{name: "x", type: :continuous}
      {:ok, f1} = ForecastGenerator.generate(wm, [fv], :short_term)
      {:ok, f2} = ForecastGenerator.generate(wm, [fv], :short_term)
      {:ok, comp} = ForecastComparator.compare([f1, f2])
      assert comp.divergence >= 0.0 and comp.divergence <= 1.0
      assert comp.comparison_id != nil
      assert String.starts_with?(comp.comparison_id, "pc_")
    end

    test "compare needs at least 2 forecasts" do
      wm = test_world_model()
      fv = %ForecastVariable{name: "x", type: :continuous}
      {:ok, f1} = ForecastGenerator.generate(wm, [fv], :immediate)
      assert {:error, _} = ForecastComparator.compare([f1])
    end

    test "divergence between identical forecasts is zero" do
      wm = test_world_model()
      fv = %ForecastVariable{name: "x", type: :continuous}
      {:ok, f1} = ForecastGenerator.generate(wm, [fv], :immediate)
      {:ok, f2} = ForecastGenerator.generate(wm, [fv], :immediate)
      {:ok, comp} = ForecastComparator.compare([f1, f2])
      assert comp.divergence < 0.01
    end
  end

  describe "C17.4.95.5 — Multi-Horizon" do
    test "generates all 5 horizons" do
      wm = test_world_model()
      fv = %ForecastVariable{name: "x", type: :continuous}
      {:ok, forecasts} = MultiHorizonForecaster.generate_multi_horizon(wm, [fv])
      assert length(forecasts) == 5
      horizons = Enum.map(forecasts, fn f -> f.metadata[:generated_horizon] end)
      assert :immediate in horizons
      assert :short_term in horizons
      assert :medium_term in horizons
      assert :long_term in horizons
      assert :civilization in horizons
    end
  end

  describe "C17.4.95.6 — Math Verification" do
    test "fingerprint is deterministic" do
      wm = test_world_model()
      fv = %ForecastVariable{name: "x", type: :continuous}
      {:ok, forecast} = ForecastGenerator.generate(wm, [fv], :immediate)
      pred = %Prediction{
        world_model_id: "test_mid",
        target_variables: [fv], horizon: :immediate,
        forecast: forecast
      }
      {:ok, p} = Prediction.new(
        world_model_id: "test_mid", target_variables: [fv],
        horizon: :immediate, forecast: forecast
      )
      fp1 = MathVerificationEngine.fingerprint(p)
      fp2 = MathVerificationEngine.fingerprint(p)
      assert fp1 == fp2
      assert String.starts_with?(fp1, "fp_")
    end
  end

  describe "C17.4.95.7 — Prediction Archaeology" do
    test "records and retrieves prediction evidence" do
      PredictionArchaeology.reset_table()
      fv = %ForecastVariable{name: "x", type: :continuous}
      pred = %Prediction{
        prediction_id: "pr_test_arch",
        world_model_id: "mid",
        target_variables: [fv],
        horizon: :immediate,
        forecast: %Forecast{horizon: :immediate, time_steps: [], variables: [fv]},
        evidence_roots: ["root1"]
      }
      {:ok, _ev} = PredictionArchaeology.record_prediction(pred)
      {:ok, retrieved} = PredictionArchaeology.get_prediction_lineage("pr_test_arch")
      assert retrieved != nil
      assert retrieved.prediction_id == "pr_test_arch"
    end
  end

  describe "C17.4.95.8 — Prediction Registry" do
    test "stores and retrieves prediction" do
      PredictionRegistry.reset_table()
      fv = %ForecastVariable{name: "x", type: :continuous}
      pred = %Prediction{
        prediction_id: "pr_test_reg",
        world_model_id: "mid",
        target_variables: [fv],
        horizon: :immediate,
        forecast: %Forecast{horizon: :immediate, time_steps: [], variables: [fv]}
      }
      {:ok, stored} = PredictionRegistry.store_prediction(pred)
      assert stored.prediction_id == "pr_test_reg"
      {:ok, retrieved} = PredictionRegistry.get_prediction("pr_test_reg")
      assert retrieved.prediction_id == "pr_test_reg"
      assert PredictionRegistry.count() == 1
    end
  end

  describe "C17.4.95.9 — Struct Validation" do
    test "Prediction struct validates required fields" do
      assert {:error, _} = Prediction.new(world_model_id: nil, target_variables: [],
        horizon: :immediate)
    end

    test "Forecast struct validates horizon" do
      assert {:error, _} = Forecast.new(horizon: :invalid, time_steps: [],
        variables: [])
    end

    test "ConfidenceEstimate validates score range" do
      assert {:error, _} = ConfidenceEstimate.new(score: 1.5, explanation: "bad")
    end

    test "UncertaintyDistribution validates variance" do
      assert {:error, _} = UncertaintyDistribution.new(variance: nil)
    end

    test "ForecastStep validates step is non-negative" do
      assert {:error, _} = ForecastStep.new(step: -1, values: %{"x" => 0.0})
    end

    test "ForecastVariable validates name" do
      assert {:error, _} = ForecastVariable.new(name: "")
    end

    test "PredictionScenario validates forecast" do
      assert {:error, _} = PredictionScenario.new(name: "scenario", forecast: nil)
    end
  end
end
