defmodule Tiannara.ASC.Reality.IncidentResponseEngine do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def initialize(deployment_id, target) do
    GenServer.call(__MODULE__, {:initialize, deployment_id, target})
  end

  def report_anomaly(deployment_id, anomaly_type, details) do
    GenServer.cast(__MODULE__, {:anomaly, deployment_id, anomaly_type, details})
  end

  def get_alerts(deployment_id) do
    GenServer.call(__MODULE__, {:alerts, deployment_id})
  end

  def get_active_monitors do
    GenServer.call(__MODULE__, :active_monitors)
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @impl true
  def init(:ok) do
    {:ok, %{monitors: %{}, alerts: [], incidents: []}}
  end

  @impl true
  def handle_call({:initialize, deployment_id, target}, _from, state) do
    monitor = %{
      deployment_id: deployment_id,
      target: target,
      status: :active,
      started_at: DateTime.utc_now(),
      health_score: 1.0,
      alert_thresholds: %{
        error_rate: 0.05,
        latency_p99_ms: 5000,
        cpu_percent: 90,
        memory_percent: 85
      },
      metrics: %{
        errors_reported: 0,
        total_requests: 0,
        avg_latency_ms: 0,
        cpu_usage: 0,
        memory_usage: 0
      }
    }

    {:reply, {:ok, monitor},
     %{state | monitors: Map.put(state.monitors, deployment_id, monitor)}}
  end

  def handle_call({:alerts, deployment_id}, _from, state) do
    deployment_alerts = Enum.filter(state.alerts, fn a -> a.deployment_id == deployment_id end)
    {:reply, deployment_alerts, state}
  end

  def handle_call(:active_monitors, _from, state) do
    active = state.monitors |> Enum.filter(fn {_id, m} -> m.status == :active end) |> Enum.map(fn {_id, m} -> m end)
    {:reply, active, state}
  end

  def handle_call(:reset, _from, state) do
    {:reply, :ok, %{state | monitors: %{}, alerts: [], incidents: []}}
  end

  @impl true
  def handle_cast({:anomaly, deployment_id, anomaly_type, details}, state) do
    alert = %{
      id: "alert-#{:erlang.system_time(:millisecond)}",
      deployment_id: deployment_id,
      type: anomaly_type,
      details: details,
      severity: classify_anomaly(anomaly_type),
      timestamp: DateTime.utc_now(),
      acknowledged: false
    }

    monitor = Map.get(state.monitors, deployment_id)
    updated_monitor = if monitor do
      updated_metrics = %{monitor.metrics |
        errors_reported: monitor.metrics.errors_reported + 1
      }
      %{monitor | health_score: max(0.0, monitor.health_score - 0.1), metrics: updated_metrics}
    end

    new_monitors = if updated_monitor, do: Map.put(state.monitors, deployment_id, updated_monitor), else: state.monitors

    auto_response = if alert.severity == :critical do
      Tiannara.ASC.Reality.RollbackEngine.rollback(deployment_id)
      :rollback_triggered
    else
      :alert_logged
    end

    new_alerts = [alert | state.alerts]
    incident = %{
      alert: alert,
      auto_response: auto_response,
      deployment_id: deployment_id
    }

    {:noreply, %{state | monitors: new_monitors, alerts: new_alerts, incidents: [incident | state.incidents]}}
  end

  defp classify_anomaly(type) do
    case type do
      :system_crash -> :critical
      :data_corruption -> :critical
      :security_breach -> :critical
      :performance_degradation -> :high
      :error_rate_spike -> :high
      :resource_exhaustion -> :high
      :latency_increase -> :medium
      :unexpected_behaviour -> :medium
      :minor_deviation -> :low
      _ -> :medium
    end
  end
end
