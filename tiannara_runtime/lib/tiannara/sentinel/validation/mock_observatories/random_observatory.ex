defmodule Tiannara.Sentinel.Validation.MockObservatories.RandomObservatory do
  @moduledoc """
  Returns completely random actions with random confidence.
  """

  def evaluate(anomaly) do
    actions = [
      :constraint_tightening,
      :entropy_rebalancing,
      :ecological_diversification,
      :ontology_reconciliation,
      :quarantine,
      :observation_only
    ]

    action = Enum.random(actions)
    confidence = :rand.uniform()

    %{
      observatory: :random,
      anomaly_type: anomaly.type,
      recommended_action: action,
      confidence: Float.round(confidence, 2),
      reasoning: "Random selection.",
      timestamp: System.system_time(:millisecond)
    }
  end
end
