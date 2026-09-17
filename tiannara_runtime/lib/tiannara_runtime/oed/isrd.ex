defmodule Tiannara.Runtime.OED.ISRD do
  @moduledoc """
  Phase 5F.8 — Inter-Sandbox Resonance Detector (ISRD)

  Detects correlated entropy harmonics and thermodynamic resonance between isolated
  Procedural Decoy Ontologies (sandboxes).
  """

  use GenServer
  require Logger

  @resonance_threshold 0.92

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Detects resonance between two isolated observers' entropy time-series.
  """
  def detect_resonance(observer_a, observer_b, series_a, series_b) do
    correlation = cosine_similarity(series_a, series_b)

    if correlation > @resonance_threshold do
      Logger.warning("""
      🚨 INTER-SANDBOX RESONANCE DETECTED
      #{observer_a} <-> #{observer_b}
      Correlation: #{correlation}
      """)

      {:escape_risk, correlation}
    else
      :stable_isolation
    end
  end

  defp cosine_similarity(a, b) do
    dot =
      Enum.zip(a, b)
      |> Enum.map(fn {x, y} -> x * y end)
      |> Enum.sum()

    mag_a = :math.sqrt(Enum.sum(Enum.map(a, &(&1 * &1))))
    mag_b = :math.sqrt(Enum.sum(Enum.map(b, &(&1 * &1))))

    dot / ((mag_a * mag_b) + 0.0001)
  end
end
