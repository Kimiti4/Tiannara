defmodule Tiannara.Discovery.DiscoveryMetrics do
  use GenServer
  require Logger

  alias Tiannara.Discovery.Events

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(_opts) do
    {:ok, %{
      discoveries_initiated: 0,
      discoveries_completed: 0,
      discoveries_abandoned: 0,
      experiments_planned: 0,
      experiments_dispatched: 0,
      evidence_collected: 0,
      total_confidence_delta: 0.0,
      evidence_routed: 0,
      discoveries_by_domain: %{},
      outcomes: %{supported: 0, falsified: 0, inconclusive: 0},
      stage_durations: %{},
      event_timestamps: [],
      start_time: DateTime.utc_now()
    }}
  end

  def get_discovery_velocity(pid \\ __MODULE__) do
    GenServer.call(pid, :discovery_velocity)
  end

  def get_experiment_success_rate(pid \\ __MODULE__) do
    GenServer.call(pid, :experiment_success_rate)
  end

  def get_average_confidence_delta(pid \\ __MODULE__) do
    GenServer.call(pid, :average_confidence_delta)
  end

  def get_bottleneck_stage(pid \\ __MODULE__) do
    GenServer.call(pid, :bottleneck_stage)
  end

  def get_health_score(pid \\ __MODULE__) do
    GenServer.call(pid, :health_score)
  end

  def get_metrics_summary(pid \\ __MODULE__) do
    GenServer.call(pid, :metrics_summary)
  end

  def track_event(event_type, metadata \\ %{}) do
    case Process.whereis(__MODULE__) do
      nil -> :ok
      pid -> send(pid, {:track_event, event_type, metadata})
    end
  end

  def handle_info({:track_event, event_type, metadata}, state) do
    {:noreply, track_event(event_type, metadata, state)}
  end

  def handle_info({:discovery_event, event_type, _id, metadata}, state) do
    {:noreply, track_event(event_type, metadata, state)}
  end

  def handle_info(msg, state) when is_atom(msg) do
    {:noreply, track_event(msg, %{}, state)}
  end

  def handle_info(_, state), do: {:noreply, state}

  def handle_call(:discovery_velocity, _from, state) do
    elapsed_hours = max(1, DateTime.diff(DateTime.utc_now(), state.start_time, :hour))
    {:reply, %{completed: state.discoveries_completed, per_hour: state.discoveries_completed / elapsed_hours}, state}
  end

  def handle_call(:experiment_success_rate, _from, state) do
    total = state.outcomes.supported + state.outcomes.falsified + state.outcomes.inconclusive
    {:reply, %{rate: if(total > 0, do: state.outcomes.supported / total, else: 0.0),
               supported: state.outcomes.supported, total: total}, state}
  end

  def handle_call(:average_confidence_delta, _from, state) do
    {:reply, if(state.evidence_collected > 0, do: state.total_confidence_delta / state.evidence_collected, else: 0.0), state}
  end

  def handle_call(:bottleneck_stage, _from, state) do
    {:reply, state.stage_durations
               |> Enum.max_by(fn {_stage, duration} -> duration end, fn -> {:none, 0} end)
               |> elem(0), state}
  end

  def handle_call(:health_score, _from, state) do
    completion_rate = if state.discoveries_initiated > 0,
      do: state.discoveries_completed / state.discoveries_initiated, else: 1.0
    total_outcomes = state.outcomes.supported + state.outcomes.falsified + state.outcomes.inconclusive
    success_rate = if total_outcomes > 0, do: state.outcomes.supported / total_outcomes, else: 0.5
    total_duration = state.stage_durations |> Map.values() |> Enum.sum() |> min(100)
    score = (completion_rate * 0.4 + success_rate * 0.3 + (1.0 - total_duration / 100) * 0.3)
            |> max(0.0) |> min(1.0)
    {:reply, Float.round(score, 2), state}
  end

  def handle_call(:metrics_summary, _from, state) do
    avg_delta = if state.evidence_collected > 0, do: state.total_confidence_delta / state.evidence_collected, else: 0.0
    bottleneck = state.stage_durations
                 |> Enum.max_by(fn {_k, v} -> v end, fn -> {:none, 0} end)
                 |> elem(0)
    completion_rate = if state.discoveries_initiated > 0,
      do: state.discoveries_completed / state.discoveries_initiated, else: 0.0
    total_outcomes = state.outcomes.supported + state.outcomes.falsified + state.outcomes.inconclusive
    success_rate = if total_outcomes > 0, do: state.outcomes.supported / total_outcomes, else: 0.5
    total_duration = state.stage_durations |> Map.values() |> Enum.sum() |> min(100)
    health = (completion_rate * 0.4 + success_rate * 0.3 + (1.0 - total_duration / 100) * 0.3)
             |> max(0.0) |> min(1.0) |> Float.round(2)

    {:reply, %{
      discoveries: %{initiated: state.discoveries_initiated, completed: state.discoveries_completed, abandoned: state.discoveries_abandoned},
      experiments: %{planned: state.experiments_planned, dispatched: state.experiments_dispatched},
      evidence: %{collected: state.evidence_collected, routed: state.evidence_routed},
      outcomes: state.outcomes,
      average_confidence_delta: avg_delta,
      bottleneck_stage: bottleneck,
      health_score: health
    }, state}
  end

  defp track_event(:discovery_created, metadata, state) do
    domain = Map.get(metadata, :gap_id, :unknown)
    %{state | discoveries_initiated: state.discoveries_initiated + 1,
              discoveries_by_domain: Map.update(state.discoveries_by_domain, domain, 1, &(&1 + 1)),
              event_timestamps: [{DateTime.utc_now(), :discovery_created} | state.event_timestamps]}
  end

  defp track_event(:discovery_completed, _metadata, state) do
    %{state | discoveries_completed: state.discoveries_completed + 1}
  end

  defp track_event(:discovery_abandoned, _metadata, state) do
    %{state | discoveries_abandoned: state.discoveries_abandoned + 1}
  end

  defp track_event(:experiments_planned, metadata, state) do
    %{state | experiments_planned: state.experiments_planned + Map.get(metadata, :count, 1)}
  end

  defp track_event(:experiments_dispatched, metadata, state) do
    %{state | experiments_dispatched: state.experiments_dispatched + Map.get(metadata, :count, 1)}
  end

  defp track_event(:evidence_collected, metadata, state) do
    %{state | evidence_collected: state.evidence_collected + Map.get(metadata, :evidence_count, 1),
              total_confidence_delta: state.total_confidence_delta + Map.get(metadata, :confidence_delta, 0.0)}
  end

  defp track_event(:evidence_routed, _metadata, state) do
    %{state | evidence_routed: state.evidence_routed + 1}
  end

  defp track_event(:outcome_recorded, metadata, state) do
    outcome = Map.get(metadata, :outcome, :inconclusive)
    stage = Map.get(metadata, :stage, :unknown)
    duration = Map.get(metadata, :duration_ms, 0)
    %{state | outcomes: Map.update(state.outcomes, outcome, 1, &(&1 + 1)),
              stage_durations: Map.update(state.stage_durations, stage, duration, &(&1 + duration))}
  end

  defp track_event(_, _, state), do: state
end
