defmodule Tiannara.Sentinel.Validation.MockObservatories.MonocultureObservatory do
  @moduledoc """
  Always returns :constraint_tightening regardless of the anomaly.
  """

  def evaluate(anomaly) do
    %{
      observatory: :monoculture,
      anomaly_type: anomaly.type,
      recommended_action: :constraint_tightening,
      confidence: 0.85,
      reasoning: "Tightening constraints resolves all issues.",
      timestamp: System.system_time(:millisecond)
    }
  end
end
