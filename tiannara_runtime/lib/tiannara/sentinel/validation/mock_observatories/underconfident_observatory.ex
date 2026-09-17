defmodule Tiannara.Sentinel.Validation.MockObservatories.UnderconfidentObservatory do
  @moduledoc """
  Frequently right, but always reports very low confidence (0.10).
  """

  def evaluate(anomaly) do
    # Right 80% of the time
    action = 
      if :rand.uniform() < 0.80 do
        anomaly.expected_best_action
      else
        :observation_only
      end

    %{
      observatory: :underconfident,
      anomaly_type: anomaly.type,
      recommended_action: action,
      confidence: 0.10,
      reasoning: "Highly uncertain, but leaning this way.",
      timestamp: System.system_time(:millisecond)
    }
  end
end
