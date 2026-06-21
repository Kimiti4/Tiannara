defmodule Tiannara.REA.OrbitResilience do
  @moduledoc """
  Perturbs orbits and classifies them into fragile, stable, regenerative, reproductive, or metastable.
  """

  alias Tiannara.OrbitTransitions
  alias Tiannara.REA.OrbitResidency

  @doc """
  Calculates resilience metrics for a given orbit:
  - return_probability
  - recovery_speed
  - perturbation_tolerance
  - reproduction_rate
  """
  def calculate_metrics(orbit_id) do
    transitions = OrbitTransitions.all()

    # Self-loop probability represents base stability
    self_loop = Enum.find(transitions, &(&1.from_orbit == orbit_id and &1.to_orbit == orbit_id))
    self_loop_prob = if self_loop, do: self_loop.probability, else: 0.1

    # Return probability: average of incoming transition probabilities from adjacent states
    incoming = Enum.filter(transitions, &(&1.to_orbit == orbit_id and &1.from_orbit != orbit_id))
    return_prob =
      if length(incoming) > 0 do
        Enum.sum(Enum.map(incoming, & &1.probability)) / length(incoming)
      else
        0.0
      end

    # Recovery speed: 1.0 / average duration of incoming paths
    avg_duration =
      if length(incoming) > 0 do
        Enum.sum(Enum.map(incoming, & &1.average_duration)) / length(incoming)
      else
        10.0
      end
    recovery_speed = Float.round(1.0 / max(1.0, avg_duration), 4)

    # Perturbation tolerance: average GSI change before decay (lower energy edge means higher tolerance)
    # We can model tolerance as 1.0 - mean transition cost of outgoing edges
    outgoing = Enum.filter(transitions, &(&1.from_orbit == orbit_id and &1.to_orbit != orbit_id))
    mean_out_cost =
      if length(outgoing) > 0 do
        Enum.sum(Enum.map(outgoing, & &1.transition_cost)) / length(outgoing)
      else
        1.0
      end
    perturbation_tolerance = Float.round(max(0.0, 1.0 - mean_out_cost), 4)

    # Reproduction rate: capture probability * residency score
    capture_prob = OrbitResidency.calculate_capture_probability(orbit_id)
    residency_score = OrbitResidency.calculate_orr(orbit_id)
    reproduction_rate = Float.round(capture_prob * residency_score, 4)

    %{
      self_loop_probability: Float.round(self_loop_prob, 4),
      return_probability: Float.round(return_prob, 4),
      recovery_speed: recovery_speed,
      perturbation_tolerance: perturbation_tolerance,
      reproduction_rate: reproduction_rate
    }
  end

  @doc """
  Classifies the resilience of a given orbit based on its computed metrics:
  - :fragile
  - :stable
  - :regenerative
  - :reproductive
  - :metastable
  """
  def classify_orbit(orbit_id) do
    metrics = calculate_metrics(orbit_id)
    p_self = metrics.self_loop_probability
    p_return = metrics.return_probability

    cond do
      p_self > 0.70 and p_return > 0.05 and metrics.reproduction_rate > 0.05 ->
        # Highly stable, high return, and spreads/reproduces itself
        :reproductive

      p_self > 0.70 and p_return > 0.05 ->
        # Highly stable and recovers from perturbations
        :regenerative

      p_self > 0.60 and p_return <= 0.05 ->
        # Stable for long periods (self loop high) but fails to recover once perturbed
        :metastable

      p_self > 0.30 ->
        :stable

      true ->
        :fragile
    end
  end
end
