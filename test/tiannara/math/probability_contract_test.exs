defmodule Tiannara.Math.ProbabilityContractTest do
  use ExUnit.Case, async: true

  alias Tiannara.Math.Probability

  describe "bayes_update/3" do
    test "computes the scalar posterior" do
      assert {:ok, post} = Probability.bayes_update(0.3, 0.9, 0.6)
      assert_in_delta post, 0.45, 1.0e-9
    end

    test "zero evidence probability is surfaced, never hidden" do
      assert {:error, :evidence_probability_zero} = Probability.bayes_update(0.3, 0.9, 0.0)
    end
  end

  describe "shannon_entropy/1" do
    test "uniform distribution maximizes entropy" do
      assert {:ok, h} = Probability.shannon_entropy([0.25, 0.25, 0.25, 0.25])
      assert_in_delta h, 2.0, 1.0e-9
    end

    test "certainty has zero entropy" do
      assert {:ok, h} = Probability.shannon_entropy([1.0, 0.0])
      assert_in_delta h, 0.0, 1.0e-9
    end
  end
end