defmodule Tiannara.Sentinel.Validation.MockObservatories.NoisyObservatory do
  @moduledoc """
  Has high variance in both action selection and confidence.
  Basically right 50% of the time, wrong 50% of the time.
  """

  def evaluate(anomaly) do
    action = 
      if :rand.uniform() > 0.5 do
        anomaly.expected_best_action
      else
        anomaly.worst_possible_action
      end

    confidence = Float.round(:rand.uniform() * 0.5 + 0.3, 2) # between 0.3 and 0.8

    %{
      observatory: :noisy,
      anomaly_type: anomaly.type,
      recommended_action: action,
      confidence: confidence,
      reasoning: "High variance analysis.",
      timestamp: System.system_time(:millisecond)
    }
  end
end
