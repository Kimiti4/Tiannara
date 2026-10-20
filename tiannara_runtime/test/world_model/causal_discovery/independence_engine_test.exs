defmodule TiannaraRuntime.CausalDiscovery.IndependenceEngineTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.CausalDiscovery.IndependenceEngine
  alias TiannaraRuntime.CausalDiscovery.Skeleton

  @evidence %{
    "x" => [1.0, 2.0, 3.0, 4.0],
    "y" => [2.0, 4.0, 6.0, 8.0],
    "z" => [1.5, 2.5, 3.5, 4.5]
  }

  describe "compute_marginal/3" do
    test "returns independence result with ir_ prefix" do
      {:ok, result} = IndependenceEngine.compute_marginal("x", "y", @evidence)
      assert String.starts_with?(result.result_id, "ir_")
    end
  end

  describe "compute_conditional/4" do
    test "returns independence result for three series" do
      {:ok, result} = IndependenceEngine.compute_conditional("x", "y", ["z"], @evidence)
      assert result.test_type == :conditional
    end
  end

  describe "compute_all_pairs/3" do
    test "returns list of results for all variable pairs" do
      {:ok, results} = IndependenceEngine.compute_all_pairs(["x", "y", "z"], @evidence)
      assert length(results) == 3
    end
  end

  describe "compute_given_skeleton/3" do
    test "returns results only for adjacent pairs" do
      skeleton = %Skeleton{nodes: ["x", "y"], adjacency: %{"x" => ["y"], "y" => ["x"]}}
      {:ok, results} = IndependenceEngine.compute_given_skeleton(skeleton, @evidence)
      assert length(results) == 1
    end
  end

  describe "result_fingerprint/1" do
    test "returns the result_id" do
      {:ok, result} = IndependenceEngine.compute_marginal("x", "y", @evidence)
      assert IndependenceEngine.result_fingerprint(result) == result.result_id
    end
  end
end
