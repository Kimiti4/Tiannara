defmodule Tiannara.Sentinel.Validation.MockObservatories.ContrarianObservatory do
  @moduledoc """
  Always returns the worst possible action.
  """

  def evaluate(anomaly) do
    %{
      observatory: :contrarian,
      anomaly_type: anomaly.type,
      recommended_action: anomaly.worst_possible_action,
      confidence: 0.80,
      reasoning: "Contrarian logic favors the opposite.",
      timestamp: System.system_time(:millisecond)
    }
  end
end
