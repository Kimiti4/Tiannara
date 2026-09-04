defmodule Tiannara.EOS.EpistemicExecutive.EVI do
  @moduledoc """
  Expected Value of Information for a candidate action.

  EVI(action) = Σ_outcome P(outcome | action) · ΔValue(outcome) − Cost(action)

  where ΔValue is the change in the value function between the current
  epistemic state and the projected post-outcome state, and Cost is
  the action's budget draw (compute, time, human attention).

  Actions with EVI ≤ 0 are never scheduled. This is the structural
  defense against busywork and Goodhart gaming.
  """

  alias Tiannara.EOS.EpistemicExecutive.ValueFunction

  def compute(action, current_state, weights) do
    expected_gain =
      Enum.reduce(action.possible_outcomes, 0.0, fn outcome, acc ->
        acc + outcome.probability *
          (ValueFunction.evaluate(outcome.projected_state, weights)
           - ValueFunction.evaluate(current_state, weights))
      end)

    expected_gain - action.cost
  end
end
