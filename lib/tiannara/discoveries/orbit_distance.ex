defmodule Tiannara.REA.OrbitDistance do
  @moduledoc """
  Calculates distance metrics between orbit classes.
  """

  alias Tiannara.REA.OrbitReachabilityNode
  alias Tiannara.REA.OrbitReachabilityEdge

  @doc """
  Computes Energy Distance.
  Formula: energy_cost + hysteresis_penalty
  """
  def energy_distance(%OrbitReachabilityEdge{} = edge) do
    edge.energy_cost + edge.hysteresis_penalty
  end

  @doc """
  Computes Intervention Distance.
  Formula: -ln(success_probability + 0.0001)
  """
  def intervention_distance(%OrbitReachabilityEdge{} = edge) do
    -:math.log(edge.success_probability + 0.0001)
  end

  @doc """
  Computes Temporal Distance.
  Formula: expected_epochs
  """
  def temporal_distance(%OrbitReachabilityEdge{} = edge) do
    edge.expected_epochs
  end

  @doc """
  Computes Structural Distance (Euclidean distance between coordinate centroids).
  Formula: sqrt(sum((x_i - x_j)^2))
  """
  def structural_distance(%OrbitReachabilityNode{} = node_a, %OrbitReachabilityNode{} = node_b) do
    vec_a = node_a.orbit_vector || [node_a.gsi, node_a.agency, node_a.robustness, node_a.generativity]
    vec_b = node_b.orbit_vector || [node_b.gsi, node_b.agency, node_b.robustness, node_b.generativity]

    sum_sq =
      Enum.zip(vec_a, vec_b)
      |> Enum.map(fn {val_a, val_b} -> :math.pow(val_a - val_b, 2) end)
      |> Enum.sum()

    :math.sqrt(sum_sq)
  end
end
