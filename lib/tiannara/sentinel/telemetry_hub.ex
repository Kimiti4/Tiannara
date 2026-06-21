defmodule Tiannara.Sentinel.TelemetryHub do
  @moduledoc """
  Unified telemetry hub for Tiannara Sentinel.
  Collects signals from MSCL, OLEF, GRCC, CIS, and other subsystems.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Broadcasts a telemetry signal to the hub.
  """
  def broadcast(subsystem, signal_type, data) do
    GenServer.cast(__MODULE__, {:broadcast, subsystem, signal_type, data})
  end

  # Callbacks

  @impl true
  def init(_opts) do
    Logger.info("🛡️ [SENTINEL] TelemetryHub initialized.")
    {:ok, %{subscribers: %{}}}
  end

  @impl true
  def handle_cast({:broadcast, subsystem, signal_type, data}, state) do
    # Log the incoming signal
    Logger.debug("[SENTINEL] Signal from #{subsystem}: #{signal_type} -> #{inspect(data)}")

    # Route to relevant monitors/detectors (to be implemented)
    Tiannara.Sentinel.AnomalyDetector.analyze(subsystem, signal_type, data)

    {:noreply, state}
  end
end
