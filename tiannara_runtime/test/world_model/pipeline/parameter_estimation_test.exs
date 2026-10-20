defmodule TiannaraRuntime.WorldModel.Pipeline.ParameterEstimationTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.WorldModel.Pipeline.ParameterEstimation
  alias TiannaraRuntime.WorldModel.Ontology.{Equation, EquationSystem, Parameter}

  describe "estimate_parameters/2" do
    test "returns empty parameters from empty equation system" do
      {:ok, es} = EquationSystem.new(equations: [])
      {:ok, result} = ParameterEstimation.estimate_parameters(es, %{})
      assert result.parameters == []
      assert byte_size(result.parameter_root) == 64
    end

    test "extracts parameters from equation expressions" do
      {:ok, eq} = Equation.new(
        target_variable: "v_x",
        expression: %{"form" => "linear", "parameters" => ["beta_v_a", "intercept"]},
        type: :algebraic
      )
      {:ok, es} = EquationSystem.new(equations: [eq])

      {:ok, result} = ParameterEstimation.estimate_parameters(es, %{})
      assert length(result.parameters) == 2

      names = Enum.map(result.parameters, & &1.name)
      assert "beta_v_a" in names
      assert "intercept" in names
    end

    test "creates deterministic parameter_ids" do
      {:ok, eq} = Equation.new(
        target_variable: "v_x",
        expression: %{"parameters" => ["alpha"]},
        type: :algebraic
      )
      {:ok, es} = EquationSystem.new(equations: [eq])

      {:ok, r1} = ParameterEstimation.estimate_parameters(es, %{})
      {:ok, r2} = ParameterEstimation.estimate_parameters(es, %{})
      assert hd(r1.parameters).parameter_id == hd(r2.parameters).parameter_id
    end

    test "parameter_root is deterministic" do
      {:ok, eq} = Equation.new(
        target_variable: "v_x",
        expression: %{"parameters" => ["alpha"]},
        type: :algebraic
      )
      {:ok, es} = EquationSystem.new(equations: [eq])

      {:ok, r1} = ParameterEstimation.estimate_parameters(es, %{})
      {:ok, r2} = ParameterEstimation.estimate_parameters(es, %{})
      assert r1.parameter_root == r2.parameter_root
    end

    test "parameter_root changes when parameters change" do
      {:ok, eq1} = Equation.new(
        target_variable: "v_x",
        expression: %{"parameters" => ["alpha"]},
        type: :algebraic
      )
      {:ok, eq2} = Equation.new(
        target_variable: "v_y",
        expression: %{"parameters" => ["beta"]},
        type: :algebraic
      )
      {:ok, es1} = EquationSystem.new(equations: [eq1])
      {:ok, es2} = EquationSystem.new(equations: [eq2])

      {:ok, r1} = ParameterEstimation.estimate_parameters(es1, %{})
      {:ok, r2} = ParameterEstimation.estimate_parameters(es2, %{})
      refute r1.parameter_root == r2.parameter_root
    end

    test "sets bounds to wide defaults" do
      {:ok, eq} = Equation.new(
        target_variable: "v_x",
        expression: %{"parameters" => ["alpha"]},
        type: :algebraic
      )
      {:ok, es} = EquationSystem.new(equations: [eq])

      {:ok, result} = ParameterEstimation.estimate_parameters(es, %{})
      param = hd(result.parameters)
      assert param.bounds == {-1.0e6, 1.0e6}
    end

    test "sets is_identifiable to false by default" do
      {:ok, eq} = Equation.new(
        target_variable: "v_x",
        expression: %{"parameters" => ["alpha"]},
        type: :algebraic
      )
      {:ok, es} = EquationSystem.new(equations: [eq])

      {:ok, result} = ParameterEstimation.estimate_parameters(es, %{})
      refute hd(result.parameters).is_identifiable
    end
  end

  describe "extract_parameter_names/1" do
    test "extracts from expression map" do
      {:ok, eq} = Equation.new(
        target_variable: "v_x",
        expression: %{"parameters" => ["a", "b"]},
        type: :algebraic
      )

      assert ParameterEstimation.extract_parameter_names(eq) == ["a", "b"]
    end

    test "returns empty for missing parameters" do
      {:ok, eq} = Equation.new(
        target_variable: "v_x",
        expression: %{"form" => "constant"},
        type: :algebraic
      )

      assert ParameterEstimation.extract_parameter_names(eq) == []
    end
  end

  describe "compute_parameter_root/1" do
    test "returns deterministic root" do
      {:ok, p} = Parameter.new(name: "alpha", value: 0.5)
      r1 = ParameterEstimation.compute_parameter_root([p])
      r2 = ParameterEstimation.compute_parameter_root([p])
      assert r1 == r2
      assert byte_size(r1) == 64
    end
  end
end
