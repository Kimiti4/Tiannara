defmodule Tiannara.Sentinel.AlertRouter do
  @moduledoc """
  Routes confirmed anomalies to interested parties (e.g., forecasting, logging).
  In Phase B, this will also trigger the ImmuneCoordinator.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def route_anomaly(%Tiannara.Sentinel.Contracts.Anomaly{} = anomaly) do
    GenServer.cast(__MODULE__, {:route, anomaly})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:route, anomaly}, state) do
    Logger.warning("Sentinel Alert: #{anomaly.type} detected from #{anomaly.source}")
    # Forward anomaly to the Immune subsystem for recommendation
    Tiannara.Sentinel.Immune.RecommendationEngine.evaluate_anomaly(anomaly)
    {:noreply, state}
  end
end
