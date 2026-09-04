defmodule Tiannara.Agency.SentinelHeartbeat do
  @moduledoc """
  Sentinel Heartbeat (Omega.1 completion).
  A supervised continuous process that runs the cognitive cycle:
    Observe -> Interpret -> Classify -> Prioritize -> Emit Agency Event

  This is the pulse of Tiannara\'s agency. Without it, the system is reactive.
  With it, the system is alive.
  """
  use GenServer
  require Logger

  alias Tiannara.Agency.Models.{Observation, AgencyEvent}

  @default_interval_ms 5_000
  @anomaly_threshold 2.0

  def start_link(opts \\ []) do
    interval = Keyword.get(opts, :interval_ms, @default_interval_ms)
    GenServer.start_link(__MODULE__, %{interval_ms: interval}, name: __MODULE__)
  end

  def trigger_cycle, do: GenServer.call(__MODULE__, :trigger_cycle)
  def get_state, do: GenServer.call(__MODULE__, :get_state)
  def set_interval(ms), do: GenServer.call(__MODULE__, {:set_interval, ms})

  @impl true
  def init(%{interval_ms: interval} = state) do
    Logger.info("[SentinelHeartbeat] Starting with interval #{interval}ms")
    schedule_tick(interval)
    {:ok, Map.merge(state, %{
      cycle_count: 0,
      last_cycle_at: nil,
      baseline_cache: %{},
      event_history: []
    })}
  end

  @impl true
  def handle_info(:tick, state) do
    new_state = run_cycle(state)
    schedule_tick(state.interval_ms)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:trigger_cycle, _from, state) do
    new_state = run_cycle(state)
    {:reply, {:ok, new_state.cycle_count}, new_state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:set_interval, ms}, _from, state) when ms > 0 do
    Logger.info("[SentinelHeartbeat] Interval updated to #{ms}ms")
    {:reply, :ok, %{state | interval_ms: ms}}
  end

  defp run_cycle(state) do
    cycle_start = System.monotonic_time(:millisecond)

    observations = collect_observations()
    {interpretations, updated_baselines} = interpret_observations(observations, state.baseline_cache)
    classified = Enum.map(interpretations, &classify/1)
    prioritized = Enum.map(classified, &prioritize/1)
    significant = Enum.filter(prioritized, &(&1.priority_score >= 0.3 or &1.severity == :critical))
    events_to_emit = if significant == [], do: [build_heartbeat_event(state.cycle_count)], else: significant
    Enum.each(events_to_emit, &emit_event/1)

    cycle_end = System.monotonic_time(:millisecond)

    Logger.info("[SentinelHeartbeat] Cycle ##{state.cycle_count + 1}: " <>
                "#{length(observations)} obs -> #{length(events_to_emit)} events " <>
                "(#{cycle_end - cycle_start}ms)")

    %{state |
      cycle_count: state.cycle_count + 1,
      last_cycle_at: DateTime.utc_now(),
      baseline_cache: updated_baselines,
      event_history: Enum.take(events_to_emit ++ state.event_history, 1000)
    }
  end

  defp collect_observations do
    sources = [
      :rea_evolution, :sopl_governance, :memory_system,
      :reality_graph, :runtime_performance, :security_posture,
      :knowledge_growth
    ]
    sources
    |> Enum.flat_map(&collect_from_source/1)
    |> Enum.reject(&is_nil/1)
  end

  defp collect_from_source(source) do
    Tiannara.Agency.TelemetryCollector.collect(source)
  end

  defp interpret_observations(observations, baselines) do
    Enum.reduce(observations, {[], baselines}, fn obs, {acc, baselines} ->
      baseline = Map.get(baselines, obs.metric_name, %{mean: obs.value, std_dev: 0.1})
      z_score = calculate_z_score(obs.value, baseline)

      interpretation = %{
        observation: obs,
        baseline: baseline,
        z_score: z_score,
        is_anomaly: abs(z_score) > @anomaly_threshold,
        trend: :stable
      }

      new_baseline = update_baseline(baseline, obs.value)
      new_baselines = Map.put(baselines, obs.metric_name, new_baseline)

      {[interpretation | acc], new_baselines}
    end)
  end

  defp calculate_z_score(value, %{mean: mean, std_dev: std_dev}) when std_dev > 0 do
    (value - mean) / std_dev
  end
  defp calculate_z_score(_, _), do: 0.0

  defp update_baseline(%{mean: mean, std_dev: std_dev} = _baseline, new_value) do
    alpha = 0.1
    new_mean = alpha * new_value + (1 - alpha) * mean
    new_std = alpha * abs(new_value - new_mean) + (1 - alpha) * std_dev
    %{mean: new_mean, std_dev: max(0.001, new_std)}
  end

  defp classify(%{is_anomaly: true} = interp) do
    category = cond do
      interp.z_score < -2.5 -> :risk
      interp.z_score > 2.5 -> :opportunity
      true -> :anomaly
    end

    severity = if abs(interp.z_score) > 3.5, do: :critical, else: :warning

    Map.merge(interp, %{
      category: category,
      severity: severity,
      interpretation: build_interpretation(category, interp)
    })
  end

  defp classify(interp) do
    category = if interp.observation.value > interp.baseline.mean * 1.5, do: :discovery, else: :info
    Map.merge(interp, %{
      category: category,
      severity: :info,
      interpretation: "Nominal behavior in #{interp.observation.source}"
    })
  end

  defp build_interpretation(category, interp) do
    obs = interp.observation
    case category do
      :risk -> "Performance degradation detected in #{obs.source}: " <>
               "#{obs.metric_name} dropped to #{obs.value} (baseline #{interp.baseline.mean})"
      :opportunity -> "Unexpected improvement in #{obs.source}: " <>
                      "#{obs.metric_name} reached #{obs.value}"
      :anomaly -> "Unexplained deviation in #{obs.source}: " <>
                  "#{obs.metric_name} at #{obs.value} (z=#{Float.round(interp.z_score, 2)})"
      _ -> "Nominal"
    end
  end

  defp prioritize(%{category: cat, severity: sev, z_score: z} = interp) do
    impact = severity_weight(sev) * abs(z) / 5.0
    confidence = min(1.0, abs(z) / 3.0)
    urgency = case sev do
      :critical -> 1.0; :warning -> 0.6; :info -> 0.2
    end
    category_multiplier = case cat do
      :risk -> 1.2; :discovery -> 1.1; :opportunity -> 1.0; :anomaly -> 0.9; :info -> 0.3
    end
    priority_score = impact * confidence * urgency * category_multiplier

    %AgencyEvent{
      id: UUID.uuid4(),
      timestamp: DateTime.utc_now(),
      source: interp.observation.source,
      category: cat,
      severity: sev,
      observation_summary: interp.interpretation,
      interpretation: interp.interpretation,
      causal_hypotheses: generate_causal_hypotheses(interp),
      evidence: [interp.observation],
      impact: impact,
      confidence: confidence,
      urgency: urgency,
      priority_score: min(1.0, priority_score),
      requires_investigation: cat in [:risk, :discovery, :anomaly] and priority_score > 0.4,
      requires_human_notification: sev == :critical or priority_score > 0.8
    }
  end

  defp severity_weight(:critical), do: 1.0
  defp severity_weight(:warning), do: 0.6
  defp severity_weight(:info), do: 0.2

  defp generate_causal_hypotheses(interp) do
    case interp.category do
      :risk -> ["Resource exhaustion", "Algorithmic regression", "External interference"]
      :discovery -> ["Emergent pattern", "Novel optimization", "Phase transition"]
      :anomaly -> ["Measurement noise", "Unmodeled interaction", "State corruption"]
      _ -> []
    end
  end

  defp emit_event(%AgencyEvent{} = event) do
    Tiannara.Agency.Orchestrator.receive_event(event)
  end

  defp build_heartbeat_event(cycle) do
    %AgencyEvent{
      id: "heartbeat_#{cycle}_#{System.monotonic_time(:millisecond)}",
      timestamp: DateTime.utc_now(),
      source: :sentinel_heartbeat,
      category: :info,
      severity: :info,
      observation_summary: "Heartbeat tick ##{cycle}",
      interpretation: "Nominal cycle completed",
      causal_hypotheses: [],
      evidence: [],
      impact: 0.0,
      confidence: 1.0,
      urgency: 0.0,
      priority_score: 0.0,
      requires_investigation: false,
      requires_human_notification: false
    }
  end

  defp schedule_tick(interval), do: Process.send_after(self(), :tick, interval)
end
