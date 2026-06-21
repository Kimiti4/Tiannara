defmodule Tiannara.OrbitTransition do
  @moduledoc """
  Represents an aggregated transition boundary between two orbit classes,
  measuring probabilities, energy, and intervention successes.
  """
  @derive Jason.Encoder
  defstruct [
    :from_orbit,            # atom
    :to_orbit,              # atom
    :count,                 # integer
    :probability,           # float
    :average_duration,      # float (epochs)
    :average_gsi_change,    # float
    :stability_score,       # float
    :transition_cost,       # float
    :attempts,              # integer
    :successes,             # integer
    :interventions          # list of maps: [%{intervention_id: String.t(), success_rate: float(), attempts: integer()}]
  ]
end
