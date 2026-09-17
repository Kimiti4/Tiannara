defmodule Tiannara.Sentinel.Validation.MockObservatories.PerfectObservatory do
  @moduledoc """
  Always returns the known optimal action with high confidence.
  """

  def evaluate(anomaly) do
    %{
      observatory: :perfect,
      anomaly_type: anomaly.type,
      recommended_action: anomaly.expected_best_action,
      confidence: 0.95,
      reasoning: "Perfect alignment with optimal trajectory.",
      timestamp: System.system_time(:millisecond)
    }
  end
end
