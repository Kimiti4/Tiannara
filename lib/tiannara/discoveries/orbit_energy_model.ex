defmodule Tiannara.REA.OrbitEnergyModel do
  @moduledoc """
  Estimates transition energy costs across multi-dimensional civilizational efforts.
  """

  alias Tiannara.REA.OrbitReachabilityNode

  @doc """
  Estimates effort costs for a transition between two orbit nodes.
  Returns a map detailing effort types, total energy cost, and difficulty.
  """
  def estimate_transition_effort(%OrbitReachabilityNode{} = source, %OrbitReachabilityNode{} = target) do
    policy_effort = abs(target.agency - source.agency) * 2.0
    constitutional_effort = abs(target.gsi - source.gsi) * 3.0
    institutional_effort = abs(target.robustness - source.robustness) * 2.5
    optionality_cost = abs(target.generativity - source.generativity) * 1.5
    agency_cost = abs(target.agency - source.agency) * 2.0

    total_cost = Float.round(policy_effort + constitutional_effort + institutional_effort + optionality_cost + agency_cost, 2)

    difficulty =
      cond do
        total_cost < 1.0 -> :low
        total_cost < 2.5 -> :medium
        true -> :high
      end

    %{
      transition: %{
        from: source.orbit_id,
        to: target.orbit_id
      },
      policy_effort: Float.round(policy_effort, 2),
      constitutional_effort: Float.round(constitutional_effort, 2),
      institutional_effort: Float.round(institutional_effort, 2),
      optionality_cost: Float.round(optionality_cost, 2),
      agency_cost: Float.round(agency_cost, 2),
      energy_cost: total_cost,
      difficulty: difficulty
    }
  end
end
