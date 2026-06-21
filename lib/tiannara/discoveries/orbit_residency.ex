defmodule Tiannara.REA.OrbitResidency do
  @moduledoc """
  Calculates Orbit Residency Ratio (ORR), persistence, retention, and capture probabilities.
  """

  alias Tiannara.OrbitTransitions

  @doc """
  Calculates Orbit Residency Ratio (ORR) for a given orbit:
  ORR = epochs_in_target_orbit / total_epochs
  """
  def calculate_orr(orbit_id) do
    states = load_orbit_states()
    total_count = length(states)

    if total_count > 0 do
      target_count = Enum.count(states, &(&1.orbit_id == to_string(orbit_id)))
      Float.round(target_count / total_count, 4)
    else
      0.0
    end
  end

  @doc """
  Calculates Orbit Capture Probability:
  P(enter orbit | non-target state)
  Formula: inflow_transitions_to_orbit / total_transitions_from_other_orbits
  """
  def calculate_capture_probability(orbit_id) do
    transitions = OrbitTransitions.all()

    inflow = Enum.filter(transitions, &(&1.to_orbit == orbit_id and &1.from_orbit != orbit_id))
    outflow_others = Enum.filter(transitions, &(&1.from_orbit != orbit_id))

    total_inflow_count = Enum.sum(Enum.map(inflow, & &1.count))
    total_outflow_others_count = Enum.sum(Enum.map(outflow_others, & &1.count))

    if total_outflow_others_count > 0 do
      Float.round(total_inflow_count / total_outflow_others_count, 4)
    else
      0.0
    end
  end

  # --- PRIVATE HELPERS ---

  defp load_orbit_states do
    path = "data/orbit_states.ndjson"
    if File.exists?(path) do
      path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(fn line -> Jason.decode!(line, keys: :atoms) end)
      |> Enum.to_list()
    else
      []
    end
  end
end
