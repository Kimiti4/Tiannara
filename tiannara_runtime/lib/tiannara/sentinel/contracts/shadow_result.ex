defmodule Tiannara.Sentinel.Contracts.ShadowResult do
  @moduledoc """
  The canonical output of a Phase C.1A+/++ Epistemic Simulation.
  Supports comparative reasoning across multiple candidate actions.
  """
  @enforce_keys [:preferred_action, :ranked_actions, :recommendation_class]

  defstruct [
    :preferred_action,
    :ranked_actions, # [%{action: atom(), probability_of_success: float(), constitutional_fitness: float()}]
    :recommendation_class, # :strong, :recommended, :weak, :high_risk, :observation_only
    :outcome_distribution # Extended trajectory data
  ]
end
