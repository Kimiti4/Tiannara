defmodule Tiannara.Interface.DiscoveryPresenterTest do
  use ExUnit.Case, async: false

  alias Tiannara.Interface.DiscoveryPresenter

  describe "present / type-specific formatting" do
    test "formats anomaly discoveries" do
      result = DiscoveryPresenter.present(%{
        type: :anomaly, domain: :cpu, signal: "spike",
        severity: :critical, confidence: 0.95,
        rationale: "CPU usage exceeded threshold",
        evidence: [%{rationalie: "95th percentile breach"}]
      })
      assert result.title =~ "Anomaly Detected"
      assert result.body =~ "CPU"
      assert result.body =~ "95.0%"
    end

    test "formats knowledge contradiction discoveries" do
      result = DiscoveryPresenter.present(%{
        type: :knowledge_contradiction,
        confidence: 0.8,
        rationale: "Two facts contradict",
        item_a: "fact1", item_b: "fact2"
      })
      assert result.title =~ "Knowledge Contradiction"
      assert result.body =~ "fact1"
      assert result.body =~ "fact2"
    end

    test "formats experiment convergence discoveries" do
      result = DiscoveryPresenter.present(%{
        type: :experiment_convergence,
        count: 3, confidence: 0.92,
        rationale: "Experiments converged",
        experiment_ids: ["exp1", "exp2", "exp3"],
        implication: "Ready for integration"
      })
      assert result.title =~ "Experimental Convergence"
      assert result.body =~ "Ready for integration"
    end

    test "formats degradation discoveries" do
      result = DiscoveryPresenter.present(%{
        type: :degradation, signal: "throughput drop",
        severity: :warning, confidence: 0.88,
        rationale: "Throughput decreased",
        value: 100, threshold: 500
      })
      assert result.title =~ "Runtime Degradation"
      assert result.body =~ "throughput drop"
    end

    test "formats generic discoveries with fallback" do
      result = DiscoveryPresenter.present(%{type: :other, title: "Generic finding", source: :research, confidence: 0.5})
      assert result.title == "Generic finding"
      assert result.body =~ "research"
    end
  end

  describe "status" do
    test "tracks presentation count" do
      status = DiscoveryPresenter.status()
      assert is_integer(status.total_presented)
    end
  end
end
