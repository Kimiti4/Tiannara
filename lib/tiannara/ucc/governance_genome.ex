defmodule Tiannara.UCC.GovernanceGenome do
  @moduledoc """
  The Canonical GovernanceGenome representation.
  Encodes the conditional logic that dictates when to switch constitutional/managerial modes
  based on the perceived uncertainty landscape.
  """
  
  @derive Jason.Encoder
  defstruct [
    :id,
    :epoch,
    # The classification weights/thresholds
    :uncertainty_estimator,
    # Mapping of {UncertaintyClass -> GovernanceMode}
    :adaptation_policy,
    # Confidence thresholds for classification
    :confidence_model,
    # Fallback policy when confidence is too low (e.g. Exploratory Annealing)
    :exploration_policy
  ]
end
