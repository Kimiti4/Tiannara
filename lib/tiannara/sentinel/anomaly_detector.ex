defmodule Tiannara.Sentinel.AnomalyDetector do
  @moduledoc """
  Detects anomalies in telemetry signals across all Tiannara subsystems.
  Categorizes anomalies into Type A-G as defined in the Sentinel architecture.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Analyzes a telemetry signal for anomalies.
  """
  def analyze(subsystem, signal_type, data) do
    GenServer.cast(__MODULE__, {:analyze, subsystem, signal_type, data})
  end

  # Callbacks

  @impl true
  def init(_opts) do
    Logger.info("🛡️ [SENTINEL] AnomalyDetector initialized.")
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:analyze, subsystem, signal_type, data}, state) do
    case detect_anomaly(subsystem, signal_type, data) do
      {:ok, anomaly} ->
        Logger.warn("🚨 [SENTINEL] Anomaly Detected: #{anomaly.type} in #{subsystem}!")
        Tiannara.Sentinel.ImmuneCoordinator.triage(anomaly)
      :none ->
        :ok
    end

    {:noreply, state}
  end

  # Private Helpers

  defp detect_anomaly(:mscl, :pressure, %{value: value}) when value > 0.95 do
    {:ok, %{type: :type_a, subsystem: :mscl, severity: :high, details: "Pressure threshold exceeded: #{value}"}}
  end

  defp detect_anomaly(:grcc, :diversity, %{entropy: entropy}) when entropy < 0.2 do
    {:ok, %{type: :type_b, subsystem: :grcc, severity: :critical, details: "Ecological monoculture detected: entropy=#{entropy}"}}
  end

  defp detect_anomaly(:ctl, :consistency, %{divergence: divergence}) when divergence > 0.5 do
    {:ok, %{type: :type_c, subsystem: :ctl, severity: :high, details: "Causal divergence detected: #{divergence}"}}
  end

  defp detect_anomaly(_subsystem, _signal_type, _data), do: :none
end
