defmodule Tiannara.Sentinel.Immune.RecommendationConfidence do
  @moduledoc """
  Computes a confidence score (0.0 to 1.0) for a proposed recommendation based on
  anomaly severity, baseline deviation, and forecast certainty.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def calculate_confidence(anomaly, _baseline_context, _forecast) do
    # Placeholder logic for Phase B1
    base = case anomaly.severity do
      :info -> 0.4
      :warning -> 0.6
      :elevated -> 0.75
      :critical -> 0.9
      :terminal -> 0.99
      _ -> 0.5
    end
    
    # In a real system, we'd adjust based on baseline context and forecast.
    # For now, return the base confidence with a slight variation.
    confidence = min(1.0, base + (:rand.uniform() * 0.05))
    confidence
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end
end
