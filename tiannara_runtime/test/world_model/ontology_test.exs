defmodule TiannaraRuntime.WorldModel.OntologyTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.WorldModel.Ontology.{
    WorldModel, StateSpace, Variable, Parameter, Equation, EquationSystem,
    CausalGraph, CausalNode, CausalEdge, ObservationModel,
    ProbabilityDistribution, Interval, TimeSeriesPoint, Prediction,
    Intervention, CounterfactualModel, ModelCertificate, CertificationCheck,
    ValidationEvidence
  }

  alias TiannaraRuntime.WorldModel.Validation.Validator

  describe "WorldModel" do
    test "new/1 creates a valid draft model" do
      ss = build_state_space(2, ["x", "y"])
      {:ok, wm} = WorldModel.new(name: "test", domain: :physics, state_space: ss)
      assert wm.name == "test"
      assert wm.domain == :physics
      assert wm.status == :draft
      assert wm.version == 1
      assert String.starts_with?(wm.model_id, "wm_")
    end

    test "new/1 fails without required fields" do
      assert {:error, _} = WorldModel.new(name: nil, domain: :physics, state_space: nil)
    end
  end

  describe "StateSpace" do
    test "dimensions must match variable_order length" do
      assert {:error, _} = StateSpace.new(dimensions: 2, variable_order: ["x"])
    end
  end

  describe "Variable" do
    test "valid variable" do
      {:ok, v} = Variable.new(variable_id: "x", name: "Position", type: :continuous)
      assert v.is_endogenous == true
      assert String.starts_with?(v.variable_id, "var_") == false
    end

    test "auto-generates variable_id" do
      {:ok, v} = Variable.new(name: "Auto", type: :latent)
      assert String.starts_with?(v.variable_id, "var_")
    end

    test "categorical requires domain" do
      assert {:error, _} = Variable.new(variable_id: "c", name: "Color", type: :categorical)
    end

    test "invalid type rejected" do
      assert {:error, _} = Variable.new(variable_id: "x", name: "Bad", type: :unknown)
    end
  end

  describe "Parameter" do
    test "bounds must have lower <= upper" do
      assert {:error, _} = Parameter.new(parameter_id: "p", name: "mass", value: 1.0, bounds: {10, 1})
    end
  end

  describe "Equation" do
    test "valid equation" do
      {:ok, e} = Equation.new(target_variable: "x", expression: %{type: :linear}, type: :differential)
      assert e.derivation == :learned
    end
  end

  describe "CausalEdge" do
    test "self-loop rejected" do
      assert {:error, _} = CausalEdge.new(edge_id: "e", source: "x", target: "x", type: :direct)
    end
  end

  describe "ProbabilityDistribution" do
    test "normal requires mean and std_dev" do
      assert {:error, _} = ProbabilityDistribution.new(type: :normal, parameters: %{})
      {:ok, pd} = ProbabilityDistribution.new(type: :normal, parameters: %{mean: 0, std_dev: 1})
      assert pd.type == :normal
    end

    test "uniform requires lower and upper" do
      assert {:error, _} = ProbabilityDistribution.new(type: :uniform, parameters: %{})
    end
  end

  describe "Interval" do
    test "lower must be <= upper" do
      assert {:error, _} = Interval.new(lower: 5, upper: 1)
    end
  end

  describe "Prediction" do
    test "requires output_variables" do
      assert {:error, _} = Prediction.new(model_id: "m", model_version: 1, input_state: %{}, output_variables: [])
    end
  end

  describe "Intervention" do
    test "valid intervention" do
      {:ok, iv} = Intervention.new(target_variable: "x", set_value: {:fix, 5.0})
      assert iv.do_operator == :atomic
    end
  end

  describe "ModelCertificate" do
    test "valid certificate" do
      {:ok, cert} = ModelCertificate.new(model_id: "wm_x", model_version: 1, certification_type: :operational)
      assert cert.overall_status == :pending
      assert cert.issued_by == :self
    end
  end

  describe "ValidationEvidence" do
    test "passed computed automatically" do
      {:ok, ve} = ValidationEvidence.new(model_id: "m", model_version: 1, metric: :rmse, value: 0.5, threshold: 1.0)
      assert ve.passed == true
    end

    test "failed when value exceeds threshold" do
      {:ok, ve} = ValidationEvidence.new(model_id: "m", model_version: 1, metric: :rmse, value: 2.0, threshold: 1.0)
      assert ve.passed == false
    end
  end

  describe "Validator" do
    test "dispatches to correct validate/1" do
      assert {:ok, _} = Validator.validate(%Variable{variable_id: "v", name: "x", type: :continuous})
      assert {:error, _} = Validator.validate(%Variable{variable_id: "v", name: "", type: :continuous})
    end

    test "rejects unknown structs" do
      assert {:error, msg} = Validator.validate(%{})
      assert String.starts_with?(msg, "unknown struct type")
    end

    test "validate_model checks internal consistency" do
      ss = build_state_space(1, ["x"])
      {:ok, wm} = WorldModel.new(name: "test", domain: :physics, state_space: ss,
        variables: [%Variable{variable_id: "x", name: "X", type: :continuous}],
        equations: %EquationSystem{equations: [%Equation{equation_id: "e1", target_variable: "x", expression: %{}, type: :algebraic}]}
      )
      assert {:ok, _} = Validator.validate_model(wm)
    end

    test "validate_model detects missing variables" do
      ss = build_state_space(1, ["x"])
      {:ok, wm} = WorldModel.new(name: "test", domain: :physics, state_space: ss,
        variables: [%Variable{variable_id: "x", name: "X", type: :continuous}],
        equations: %EquationSystem{equations: [%Equation{equation_id: "e1", target_variable: "y", expression: %{}, type: :algebraic}]}
      )
      assert {:error, msg} = Validator.validate_model(wm)
      assert msg =~ "undefined"
    end
  end

  defp build_state_space(dim, order) do
    {:ok, ss} = StateSpace.new(dimensions: dim, variable_order: order)
    ss
  end
end
