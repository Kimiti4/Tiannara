defmodule Tiannara.Sentinel.EventClassifier do
  @moduledoc """
  Classifies incoming raw telemetry events into potential anomaly categories,
  or passes them through as normal telemetry.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def classify(event) do
    GenServer.cast(__MODULE__, {:classify, event})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:classify, event}, state) do
    # Basic classification logic. In a real system, this would evaluate thresholds.
    # We forward potentially anomalous events to the AnomalyDetector.
    Tiannara.Sentinel.AnomalyDetector.evaluate(event)
    {:noreply, state}
  end
end
