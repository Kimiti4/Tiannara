defmodule Tiannara.Discovery.DiscoveryScoreTest do
  use ExUnit.Case, async: true
  alias Tiannara.Discovery.DiscoveryScore

  describe "new/1" do
    test "creates with default values" do
      score = DiscoveryScore.new()
      assert score.novelty == 0.5
      assert score.safety == 1.0
    end

    test "accepts overrides" do
      score = DiscoveryScore.new(novelty: 0.9, importance: 0.8)
      assert score.novelty == 0.9
      assert score.importance == 0.8
      assert score.feasibility == 0.5
    end
  end

  describe "composite/1" do
    test "geometric mean of all dimensions" do
      score = DiscoveryScore.new(novelty: 1.0, importance: 1.0, feasibility: 1.0,
        expected_information_gain: 1.0, reproducibility: 1.0, safety: 1.0, resource_efficiency: 1.0)
      assert DiscoveryScore.composite(score) == 1.0
    end

    test "returns 0 if any dimension is 0" do
      score = DiscoveryScore.new(novelty: 0.0)
      assert DiscoveryScore.composite(score) == 0.0
    end
  end

  describe "weighted_linear/1" do
    test "computes weighted average" do
      score = DiscoveryScore.new(novelty: 1.0, importance: 1.0, feasibility: 1.0,
        expected_information_gain: 1.0, reproducibility: 1.0, safety: 1.0, resource_efficiency: 1.0)
      assert DiscoveryScore.weighted_linear(score) == 1.0
    end
  end

  describe "weakest_dimension/1" do
    test "finds the weakest dimension" do
      score = DiscoveryScore.new(novelty: 0.1, importance: 0.9)
      {dim, val} = DiscoveryScore.weakest_dimension(score)
      assert dim == :novelty
      assert val == 0.1
    end
  end
end
