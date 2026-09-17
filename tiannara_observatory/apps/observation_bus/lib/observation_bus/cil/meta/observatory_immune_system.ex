defmodule ObservationBus.CIL.Meta.ObservatoryImmuneSystem do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def get_status, do: GenServer.call(__MODULE__, :status)
  def get_alerts, do: GenServer.call(__MODULE__, :alerts)

  @impl true
  def init(_opts) do
    alerts = [
      %{id: "alert_1", severity: :low, type: :metric_anomaly, source: :pattern_engine, description: "Pattern detection rate deviated by 12% from baseline", detected_at: DateTime.add(DateTime.utc_now(), -600, :second), status: :monitoring},
      %{id: "alert_2", severity: :medium, type: :latency, source: :event_store, description: "Write latency exceeded 200ms threshold", detected_at: DateTime.add(DateTime.utc_now(), -1800, :second), status: :investigating},
      %{id: "alert_3", severity: :high, type: :data_integrity, source: :replay_store, description: "Checksum mismatch in snapshot batch", detected_at: DateTime.add(DateTime.utc_now(), -3600, :second), status: :isolated},
    ]
    {:ok, %{alerts: alerts, immune_health: :operational, auto_isolation_enabled: true}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, Map.take(state, [:immune_health, :auto_isolation_enabled, :alerts]), state}
  end
  def handle_call(:alerts, _from, state), do: {:reply, state.alerts, state}
end
