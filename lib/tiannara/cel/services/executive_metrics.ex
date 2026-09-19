defmodule Tiannara.CEL.Services.ExecutiveMetrics do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.CEL.Kernel.ConstitutionalScore
  alias Tiannara.CEL.Services.{ExecutiveMemory, EventBus}

  @collection_interval_ms 60_000
  @max_history 50

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_kpis do
    GenServer.call(__MODULE__, :get_kpis)
  end

  def get_history do
    GenServer.call(__MODULE__, :get_history)
  end

  def get_alerts do
    GenServer.call(__MODULE__, :get_alerts)
  end

  def ingest_mission_outcome(mission_id, assessment) do
    GenServer.cast(__MODULE__, {:mission_outcome, mission_id, assessment})
  end

  @impl true
  def id, do: :executive_metrics

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities do
    [:organizational_kpis, :performance_tracking, :kpi_alerting,
     :trend_analysis, :constitutional_metrics]
  end

  @impl true
  def dependencies, do: [:executive_service_bus]

  @impl true
  def health do
    if Process.whereis(__MODULE__), do: :healthy, else: :unhealthy
  end

  @impl true
  def constitutional_score do
    kpis =
      if Process.whereis(__MODULE__),
        do: GenServer.call(__MODULE__, :get_kpis),
        else: %{}

    success = Map.get(kpis, :success_rate, 1.0)
    recovery = Map.get(kpis, :recovery_rate, 1.0)
    calibration = Map.get(kpis, :calibration_score, 0.5)

    %ConstitutionalScore{
      service_id: id(),
      health: 1.0,
      constitutional_alignment: min(1.0, success * 0.4 + recovery * 0.3 + calibration * 0.3),
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: Map.get(kpis, :evidence_quality, 0.5),
      human_oversight: 0.8,
      computed_at: DateTime.utc_now()
    }
  end

  @impl true
  def init(_opts) do
    send(self(), :collect)
    {:ok, %{
      kpis: %{},
      history: [],
      alerts: [],
      collected_at: nil
    }}
  end

  @impl true
  def handle_call(:get_kpis, _from, state), do: {:reply, state.kpis, state}

  @impl true
  def handle_call(:get_history, _from, state), do: {:reply, Enum.reverse(state.history), state}

  @impl true
  def handle_call(:get_alerts, _from, state), do: {:reply, Enum.reverse(state.alerts), state}

  @impl true
  def handle_cast({:mission_outcome, mission_id, assessment}, state) do
    mission_kpis = %{
      research_acceleration: Map.get(assessment, :research_acceleration_delta, 0.0),
      engineering_productivity: Map.get(assessment, :engineering_productivity_delta, 0.0),
      knowledge_retained: Map.get(assessment, :knowledge_retained, 0.0),
      novel_discoveries: Map.get(assessment, :novel_discoveries_count, 0),
      human_collaboration: Map.get(assessment, :human_collaboration_value, 0.0)
    }

    try do
      ExecutiveMemory.record_event(:executive_metrics, :mission_completed, %{
        mission_id: mission_id, kpis: mission_kpis
      })
    rescue
      _ -> :ok
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:collect, state) do
    kpis = collect_kpis()
    alerts = detect_anomalies(kpis, state.kpis)
    history = [kpis | state.history] |> Enum.take(@max_history)

    Enum.each(alerts, fn alert ->
      Logger.warning("ExecutiveMetrics KPI Alert: #{alert.label} = #{alert.value} (#{alert.reason})")
      try do
        ExecutiveMemory.record_event(:executive_metrics, :kpi_alert, Map.from_struct(alert))
      rescue
        _ -> :ok
      end
    end)

    try do
      ExecutiveMemory.record_event(:executive_metrics, :kpi_snapshot, kpis)
    rescue
      _ -> :ok
    end

    emit_constitutional_event(:metrics_collected, %{kpi_count: map_size(kpis), alerts: length(alerts)})
    safe_publish("metrics.collected", kpis)

    Process.send_after(self(), :collect, @collection_interval_ms)

    {:noreply, %{state |
      kpis: kpis,
      history: history,
      alerts: alerts ++ state.alerts |> Enum.take(@max_history),
      collected_at: DateTime.utc_now()
    }}
  end

  defp collect_kpis do
    wf_stats = get_workflow_stats()
    sched_state = get_scheduler_state()
    pe_report = get_priority_report()
    state_report = get_executive_state()

    throughput = calc_throughput(wf_stats)
    success_rate = calc_rate(wf_stats[:total_completed], wf_stats[:total_failed])
    avg_duration = div(wf_stats[:total_duration] || 0, max(1, wf_stats[:total_completed] || 1))
    evidence_quality = ratio(wf_stats[:completed_with_evidence], wf_stats[:total_completed])
    resource_eff = resource_efficiency(state_report)
    conf_align = pe_report_confidence(pe_report)
    bottleneck_n = length(wf_stats[:bottleneck_steps] || [])
    recovery_rate = calc_rate(wf_stats[:successful_compensations], wf_stats[:total_failed])
    starvation = (sched_state[:starvation_warnings] || 0) + (sched_state[:starvation_count] || 0)
    calibration = pe_calibration(pe_report)

    %{
      throughput: throughput,
      success_rate: success_rate,
      avg_duration_ms: avg_duration,
      evidence_quality: evidence_quality,
      resource_efficiency: resource_eff,
      confidence_alignment: conf_align,
      bottleneck_count: bottleneck_n,
      recovery_rate: recovery_rate,
      scheduler_starvation: starvation,
      calibration_score: calibration
    }
  end

  defp get_workflow_stats do
    case Process.whereis(Tiannara.CEL.Services.WorkflowEngine) do
      nil -> %{}
      pid ->
        try do
          GenServer.call(pid, :stats, 2_000)
        rescue
          _ -> %{}
        end
    end
  end

  defp get_scheduler_state do
    case Process.whereis(Tiannara.CEL.Services.ExecutiveScheduler) do
      nil -> %{}
      pid ->
        try do
          GenServer.call(pid, :state, 2_000)
        rescue
          _ -> %{}
        end
    end
  end

  defp get_priority_report do
    case Process.whereis(Tiannara.CEL.Services.PriorityEngine) do
      nil -> nil
      pid ->
        try do
          GenServer.call(pid, :get_report, 2_000)
        rescue
          _ -> nil
        end
    end
  end

  defp get_executive_state do
    case Process.whereis(Tiannara.CEL.Services.ExecutiveStateManager) do
      nil -> %{}
      pid ->
        try do
          GenServer.call(pid, :state, 2_000)
        rescue
          _ -> %{}
        end
    end
  end

  defp calc_throughput(%{total_completed: c, total_started: s})
       when is_integer(c) and is_integer(s) and s > 0 and c >= 0,
       do: ratio(c, max(s, 1))
  defp calc_throughput(_), do: 0.0

  defp calc_rate(nil, _), do: 0.0
  defp calc_rate(_, nil), do: 0.0
  defp calc_rate(_success, total) when total == 0, do: 0.0
  defp calc_rate(success, total), do: success / max(success + abs(total), 1)

  defp ratio(_numerator, denominator) when not is_number(denominator), do: 0.0
  defp ratio(_numerator, 0), do: 0.0
  defp ratio(numerator, denominator) when is_number(numerator) and is_number(denominator) and denominator != 0 and denominator != 0.0 do
    numerator / denominator
  end
  defp ratio(_, _), do: 0.0

  defp resource_efficiency(%{resource_allocation: ra}) when is_map(ra) do
    vs = Map.values(ra)
    if vs == [] do
      1.0
    else
      avg =
        Enum.map(vs, fn
          %{capacity: c, allocated: a} when c > 0 -> 1.0 - a / c
          _ -> 0.5
        end)
        |> Enum.sum()
        |> Kernel./(length(vs))
      max(0.0, min(1.0, avg))
    end
  end
  defp resource_efficiency(_), do: 0.0

  defp pe_report_confidence(nil), do: 0.5
  defp pe_report_confidence(r), do: max(0.0, min(1.0, Map.get(r, :prio, 0.5)))

  defp pe_calibration(nil), do: 0.5
  defp pe_calibration(r), do: max(0.0, min(1.0, Map.get(r, :calibration, 0.5)))

  defp safe_publish(topic, payload) do
    case Process.whereis(EventBus) do
      nil ->
        Logger.debug("ExecutiveMetrics: EventBus unavailable, skipping publish to #{topic}")
        :ok
      _pid ->
        try do
          EventBus.publish(topic, payload, [])
        rescue
          e -> Logger.debug("ExecutiveMetrics: publish failed (#{inspect(e)}), skipping")
            :ok
        end
    end
  end

  defp detect_anomalies(kpis, prev_kpis) do
    alerts = []
    alerts = if kpis[:success_rate] < 0.5 do
      [%{label: "success_rate", value: kpis[:success_rate], severity: :critical,
        reason: "Workflow success rate below 50%", timestamp: DateTime.utc_now()} | alerts]
    else alerts end
    alerts = if kpis[:calibration_score] < 0.4 do
      [%{label: "calibration_score", value: kpis[:calibration_score], severity: :high,
        reason: "PriorityEngine calibration degraded", timestamp: DateTime.utc_now()} | alerts]
    else alerts end
    alerts = if kpis[:bottleneck_count] > 3 do
      [%{label: "bottleneck_count", value: kpis[:bottleneck_count], severity: :medium,
        reason: "#{kpis[:bottleneck_count]} workflow bottlenecks detected", timestamp: DateTime.utc_now()} | alerts]
    else alerts end
    alerts = if kpis[:scheduler_starvation] > (prev_kpis[:scheduler_starvation] || 0) + 5 do
      [%{label: "scheduler_starvation", value: kpis[:scheduler_starvation], severity: :high,
        reason: "Scheduling starvation spike", timestamp: DateTime.utc_now()} | alerts]
    else alerts end
    alerts = if kpis[:recovery_rate] < 0.3 do
      [%{label: "recovery_rate", value: kpis[:recovery_rate], severity: :critical,
        reason: "Saga recovery rate below 30%", timestamp: DateTime.utc_now()} | alerts]
    else alerts end
    alerts
  end
end
