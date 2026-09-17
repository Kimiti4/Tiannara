defmodule Tiannara.Sentinel.AnomalyDetector do
  @moduledoc """
  Detects and registers classified anomalies based on telemetry.
  Issues Alerts if an anomaly is detected.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def evaluate(event) do
    GenServer.cast(__MODULE__, {:evaluate, event})
  end

  @impl true
  def init(_opts) do
    {:ok, %{active_anomalies: []}}
  end

  @impl true
  def handle_cast({:evaluate, _event}, state) do
    # Evaluate thresholds. If anomalous, we create a Contracts.Anomaly and route it.
    {:noreply, state}
  end
end
