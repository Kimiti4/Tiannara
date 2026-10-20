defmodule TiannaraRuntime.CausalDiscovery.IndependenceResultTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.IndependenceResult

  describe "new/1" do
    test "creates valid IndependenceResult with all required fields" do
      {:ok, r} = IndependenceResult.new(variable_a: "x", variable_b: "y", test_type: :conditional)
      assert r.variable_a == "x"
      assert r.variable_b == "y"
      assert r.test_type == :conditional
      assert String.starts_with?(r.result_id, "ir_")
    end

    test "fails on empty variable_a" do
      assert {:error, _} = IndependenceResult.new(variable_a: "", variable_b: "y", test_type: :conditional)
    end

    test "fails on empty variable_b" do
      assert {:error, _} = IndependenceResult.new(variable_a: "x", variable_b: "", test_type: :conditional)
    end

    test "fails when variable_a and variable_b are the same" do
      assert {:error, _} = IndependenceResult.new(variable_a: "x", variable_b: "x", test_type: :conditional)
    end

    test "fails on invalid test_type" do
      assert {:error, _} = IndependenceResult.new(variable_a: "x", variable_b: "y", test_type: :invalid)
    end

    test "fails when p_value is out of range" do
      assert {:error, _} = IndependenceResult.new(variable_a: "x", variable_b: "y", test_type: :conditional, p_value: 1.5)
    end

    test "fails when confidence is out of range" do
      assert {:error, _} = IndependenceResult.new(variable_a: "x", variable_b: "y", test_type: :conditional, confidence: -0.1)
    end
  end

  describe "validate/1" do
    test "returns {:ok, struct} for valid IndependenceResult" do
      r = %IndependenceResult{variable_a: "x", variable_b: "y", test_type: :conditional, p_value: 0.05, confidence: 0.95}
      assert {:ok, _} = IndependenceResult.validate(r)
    end

    test "fails for invalid IndependenceResult" do
      r = %IndependenceResult{variable_a: "", variable_b: "y", test_type: :conditional}
      assert {:error, _} = IndependenceResult.validate(r)
    end
  end

  describe "compute_id/1" do
    test "returns string starting with ir_" do
      {:ok, r} = IndependenceResult.new(variable_a: "x", variable_b: "y", test_type: :marginal)
      id = IndependenceResult.compute_id(r)
      assert String.starts_with?(id, "ir_")
    end
  end

  describe "canonicalize/1" do
    test "returns a map" do
      {:ok, r} = IndependenceResult.new(variable_a: "x", variable_b: "y", test_type: :marginal)
      assert is_map(IndependenceResult.canonicalize(r))
    end
  end
end
