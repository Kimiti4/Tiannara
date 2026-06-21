defmodule Tiannara.REA.OrbitObserver do
  @moduledoc """
  Observes the current physical state coordinates of the civilization.
  """

  @doc """
  Constructs a coordinate vector [gsi, agency, robustness, generativity] from telemetry and recoverability.
  """
  def observe(telemetry, recoverability) do
    gsi = recoverability
    agency = (Map.get(telemetry, :redundancy_delta) || Map.get(telemetry, "redundancy_delta") || 0.0) + 0.5
    robustness = Map.get(telemetry, :dcr_retention) || Map.get(telemetry, "dcr_retention") || 0.5
    generativity = Map.get(telemetry, :novelty_rate) || Map.get(telemetry, "novelty_rate") || 0.0

    [
      Float.round(gsi, 4),
      Float.round(agency, 4),
      Float.round(robustness, 4),
      Float.round(generativity, 4)
    ]
  end
end

defmodule Tiannara.REA.OrbitEstimator do
  @moduledoc """
  Estimates the current orbit classification and membership confidence.
  """

  alias Tiannara.REA.OrbitReachabilityGraph

  @doc """
  Estimates the closest orbit class and calculates membership confidence based on Euclidean distance.
  """
  def estimate(vector) do
    {nodes, _} = OrbitReachabilityGraph.load()

    # Find the closest node based on centroid Euclidean distance
    {closest_node, min_dist} =
      Enum.map(nodes, fn node ->
        centroid = node.orbit_vector || [node.gsi, node.agency, node.robustness, node.generativity]
        dist = euclidean_distance(vector, centroid)
        {node, dist}
      end)
      |> Enum.min_by(&elem(&1, 1))

    # Proximity confidence formula: 1 / (1 + distance)
    confidence = Float.round(1.0 / (1.0 + min_dist), 4)

    %{
      orbit_id: closest_node.orbit_id,
      orbit_type: closest_node.orbit_type,
      confidence: confidence,
      distance: Float.round(min_dist, 4),
      vector: vector
    }
  end

  defp euclidean_distance(v1, v2) do
    Enum.zip(v1, v2)
    |> Enum.map(fn {a, b} -> :math.pow(a - b, 2) end)
    |> Enum.sum()
    |> :math.sqrt()
  end
end

defmodule Tiannara.REA.OrbitController do
  @moduledoc """
  Executes coordinate steering and manages the closed-loop replanning cycle.
  """

  alias Tiannara.REA.OrbitEstimator
  alias Tiannara.REA.MultiObjectivePlanner

  # Maps parameter interventions to coordinate deltas [dGSI, dAgency, dRobustness, dGenerativity]
  @deltas %{
    "explore" => [-0.05, 0.0, 0.0, 0.10],
    "repair" => [0.0, 0.10, 0.15, 0.0],
    "preserve" => [0.10, 0.0, 0.0, -0.05],
    "triage" => [0.0, -0.15, 0.0, 0.05]
  }

  @doc """
  Simulates parameter trajectory adjustments along a sequence of interventions.
  """
  def simulate_trajectory(start_vector, interventions) do
    Enum.reduce(interventions, [start_vector], fn intervention, path_acc ->
      current = hd(path_acc)
      delta = Map.get(@deltas, to_string(intervention), [0.0, 0.0, 0.0, 0.0])

      next =
        Enum.zip(current, delta)
        |> Enum.map(fn {val, d} -> Float.round(min(1.0, max(0.0, val + d)), 4) end)

      [next | path_acc]
    end)
    |> Enum.reverse()
  end

  @doc """
  Closed-loop step navigation check.
  Estimates the current state. If the state is off-track (e.g. not on the planned path,
  or has a drift distance > threshold), triggers replanning to the desired orbit.
  """
  def navigate_step(telemetry, recoverability, planned_path, desired_orbit, objective) do
    current_vector = Tiannara.REA.OrbitObserver.observe(telemetry, recoverability)
    estimation = OrbitEstimator.estimate(current_vector)

    drift_threshold = 0.45

    cond do
      # Arrived at destination
      estimation.orbit_id == desired_orbit ->
        {:arrived, estimation}

      # Off-path drift check: either current estimated orbit is not in the planned path list,
      # or distance is too high.
      estimation.orbit_id not in planned_path or estimation.distance > drift_threshold ->
        # Trigger dynamic replanning
        case MultiObjectivePlanner.plan(estimation.orbit_id, desired_orbit, objective) do
          {:ok, new_plan} ->
            {:replanned, new_plan, estimation}
          {:error, reason} ->
            {:error, reason, estimation}
        end

      true ->
        {:continue, estimation}
    end
  end
end
