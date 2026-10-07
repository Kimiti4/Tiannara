defmodule Tiannara.Forecasting.EvidenceFusionTest do
  use ExUnit.Case, async: true
  alias Tiannara.Forecasting.EvidenceFusion

  test "contrary weak evidence is retained beside a strong base rate" do
    observations = [
      %{direction: :supporting, weight: 0.01},
      %{direction: :contrary, weight: 0.02, source: :anomaly}
    ]

    assert {:ok, result} = EvidenceFusion.analyze(0.95, observations)
    assert length(result.contrary_evidence) == 1
    assert result.contradiction_detected == false
    assert result.status == :requires_joint_evaluation
  end

  test "strong enough contrary evidence is surfaced rather than discarded" do
    observations = [
      %{direction: :contrary, weight: 0.06, source: :silent_signal}
    ]

    assert {:ok, result} = EvidenceFusion.analyze(0.95, observations)
    assert result.contradiction_detected == true
  end

  test "base-rate and anomaly-sensitive models remain separate" do
    assert {:ok, comparison} =
      EvidenceFusion.compare_models(%{probability: 0.95}, %{probability: 0.61})

    assert comparison.status == :not_decided
  end

  test "invalid observations fail closed" do
    assert {:error, :invalid_evidence_observation} =
      EvidenceFusion.analyze(0.9, [%{direction: :unknown, weight: 1.0}])
  end

end

