defmodule Tiannara.Autonomy.SimulationManagerTest do
  use ExUnit.Case, async: false

  alias Tiannara.Autonomy.SimulationManager

  defp sample_proposal(opts \\ []) do
    %{
      id: "prop_#{System.unique_integer([:positive])}",
      title: "Test improvement",
      target: opts[:target] || :scheduler,
      category: :performance,
      expected_impact: opts[:impact] || 0.5,
      confidence: 0.8
    }
  end

  describe "simulate" do
    test "returns simulation result with required fields" do
      result = SimulationManager.simulate(sample_proposal())
      assert result.id != nil
      assert result.proposal_id != nil
      assert result.verdict in [:pass, :fail, :inconclusive]
      assert is_number(result.improvement_ratio) or result.improvement_ratio == nil
      assert is_number(result.duration_ms)
      assert result.rationale != nil
    end

    test "passes for improvements with ratio > 1.05" do
      result = SimulationManager.simulate(sample_proposal(impact: 0.9))
      assert result.verdict == :pass
      assert result.statistically_significant == true
      assert result.improvement_ratio > 1.05
    end

    test "fails for degrading changes" do
      result = SimulationManager.simulate(%{id: "bad", title: "Bad", target: :scheduler,
        category: :performance, expected_impact: -0.5, confidence: 0.1})
      assert result.verdict == :fail
    end

    test "inconclusive for minimal change" do
      result = SimulationManager.simulate(sample_proposal(impact: 0.01))
      assert result.verdict in [:inconclusive, :fail]
    end
  end

  describe "running_count" do
    test "reports count" do
      assert is_integer(SimulationManager.running_count())
    end
  end

  describe "status" do
    test "returns metrics" do
      status = SimulationManager.status()
      assert is_integer(status.total_simulated)
      assert is_integer(status.total_passed)
      assert is_integer(status.total_failed)
      assert is_float(status.pass_rate)
    end

    test "updates after simulation" do
      before = SimulationManager.status().total_simulated
      SimulationManager.simulate(sample_proposal())
      status = SimulationManager.status()
      assert status.total_simulated == before + 1
    end
  end
end
