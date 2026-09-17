defmodule Tiannara.L1Physics.HSV do
  @moduledoc """
  L1 - Holographic State Vectors (HSV)
  
  Provides geometric encoding for the L1 substrate.
  Translates L0 state into coordinate spaces without semantics.
  """

  @doc """
  Encodes raw infrastructural state into a multi-dimensional state vector.
  """
  def encode_state(raw_metrics) do
    # Simple projection mapping infrastructural metrics to a 3D vector.
    # Dimensions: [throughput, latency, error_rate] mapped geometrically.
    x = Map.get(raw_metrics, :throughput, 0.0) / 1000.0
    y = 1.0 / max(Map.get(raw_metrics, :latency_ms, 1.0), 0.1)
    z = 1.0 - Map.get(raw_metrics, :error_rate, 0.0)

    [x, y, z]
  end

  @doc """
  Calculates the harmonic resonance (distance) between two vectors.
  """
  def calculate_distance(vec_a, vec_b) do
    Enum.zip(vec_a, vec_b)
    |> Enum.reduce(0.0, fn {a, b}, acc ->
      acc + :math.pow(a - b, 2)
    end)
    |> :math.sqrt()
  end
end
