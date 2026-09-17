defmodule Tiannara.Sentinel.Validation.MockObservatories.OverconfidentObservatory do
  @moduledoc """
  Produces very high confidence (0.99) but is frequently wrong (picks random actions).
  """

  def evaluate(anomaly) do
    actions = [
      :constraint_tightening,
      :entropy_rebalancing,
      :ecological_diversification,
      :ontology_reconciliation,
      :quarantine,
      anomaly.expected_best_action
    ]

    # Pick a random action
    action = Enum.random(actions)

    %{
      observatory: :overconfident,
      anomaly_type: anomaly.type,
      recommended_action: action,
      confidence: 0.99,
      reasoning: "Absolute certainty in this trajectory.",
      timestamp: System.system_time(:millisecond)
    }
  end
end
