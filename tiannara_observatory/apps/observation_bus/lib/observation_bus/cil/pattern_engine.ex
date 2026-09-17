defmodule ObservationBus.CIL.PatternEngine do
  @moduledoc """
  Continuously searches for recurring constitutional patterns in event streams.

  Maintains a sliding window of recent events and analyzes them for known
  pattern types: discovery bursts, knowledge stagnation, experiment
  bottlenecks, engineering acceleration, certification regressions, and
  resource starvation.

  Found patterns are registered in `ObservationBus.CIL.PatternRegistry`.
  """
  use GenServer

  alias ObservationBus.CIL.PatternRegistry

  @window_size 100
  @analysis_interval_ms 5_000

  defstruct [:window, :last_analysis, :total_analyzed, :patterns_found]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_analysis()
    {:ok, %__MODULE__{
      window: :queue.new(),
      last_analysis: DateTime.utc_now(),
      total_analyzed: 0,
      patterns_found: 0
    }}
  end

  @doc "Feed an event into the pattern engine for analysis."
  @spec ingest_event(map()) :: :ok
  def ingest_event(event) do
    GenServer.cast(__MODULE__, {:ingest, event})
  end

  @doc "Return current engine state summary."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_cast({:ingest, event}, state) do
    window = :queue.in(event, state.window)
    window = if :queue.len(window) > @window_size do
      {:value, _dropped} = :queue.out(window)
      window
    else
      window
    end
    {:noreply, %{state | window: window, total_analyzed: state.total_analyzed + 1}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      window_size: :queue.len(state.window),
      total_analyzed: state.total_analyzed,
      patterns_found: state.patterns_found,
      last_analysis: state.last_analysis
    }, state}
  end

  @impl true
  def handle_info(:analyze, state) do
    schedule_analysis()
    window_list = :queue.to_list(state.window)

    found = analyze_window(window_list)
    patterns_found = state.patterns_found + length(found)

    {:noreply, %{state |
      patterns_found: patterns_found,
      last_analysis: DateTime.utc_now()
    }}
  end

  defp schedule_analysis do
    Process.send_after(self(), :analyze, @analysis_interval_ms)
  end

  defp analyze_window(events) do
    [
      detect_discovery_bursts(events),
      detect_knowledge_stagnation(events),
      detect_experiment_bottlenecks(events),
      detect_engineering_acceleration(events),
      detect_certification_regression(events),
      detect_resource_starvation(events)
    ]
    |> List.flatten()
    |> Enum.each(fn {type, domain, signature, meta} ->
      PatternRegistry.register_pattern(type, domain, signature, meta)
    end)
  end

  defp detect_discovery_bursts(events) do
    discoveries = Enum.filter(events, &(&1[:domain] == "discovery"))
    recent = Enum.filter(discoveries, fn e ->
      Map.get(e, :timestamp, DateTime.utc_now()) |> in_last_minutes?(5)
    end)
    if length(recent) >= 3 do
      [{:discovery_burst, "discovery",
        "burst_#{length(recent)}_#{System.system_time(:second)}",
        %{count: length(recent), window_minutes: 5}}]
    else
      []
    end
  end

  defp detect_knowledge_stagnation(events) do
    knowledge = Enum.filter(events, &(&1[:domain] == "knowledge"))
    if length(knowledge) < 2 and total_events_in_last?(events, 60, 10) do
      [knowledge_stagnation_entry(events)]
    else
      []
    end
  end

  defp knowledge_stagnation_entry(events) do
    {:knowledge_stagnation, "knowledge",
     "stagnation_#{System.system_time(:second)}",
     %{knowledge_events: length(Enum.filter(events, &(&1[:domain] == "knowledge"))),
       total_recent: length(events)}}
  end

  defp detect_experiment_bottlenecks(events) do
    experiments = Enum.filter(events, fn e ->
      e[:domain] == "experiment" and Map.get(e, :payload, %{})[:action] == "started"
    end)
    completions = Enum.filter(events, fn e ->
      e[:domain] == "experiment" and Map.get(e, :payload, %{})[:action] == "completed"
    end)

    if length(experiments) > length(completions) + 3 do
      [{:experiment_bottleneck, "experiment",
        "bottleneck_#{System.system_time(:second)}",
        %{pending: length(experiments) - length(completions),
          started: length(experiments), completed: length(completions)}}]
    else
      []
    end
  end

  defp detect_engineering_acceleration(events) do
    engineering = Enum.filter(events, &(&1[:domain] == "engineering"))
    recent_eng = Enum.filter(engineering, fn e ->
      Map.get(e, :timestamp, DateTime.utc_now()) |> in_last_minutes?(10)
    end)
    if length(recent_eng) >= 5 do
      [{:engineering_acceleration, "engineering",
        "accel_#{length(recent_eng)}_#{System.system_time(:second)}",
        %{count: length(recent_eng), window_minutes: 10}}]
    else
      []
    end
  end

  defp detect_certification_regression(events) do
    failures = Enum.filter(events, fn e ->
      e[:domain] == "certification" and
        Map.get(e, :payload, %{})[:action] == "failed"
    end)
    if length(failures) >= 2 do
      [{:certification_regression, "certification",
        "regression_#{length(failures)}_#{System.system_time(:second)}",
        %{failure_count: length(failures)}}]
    else
      []
    end
  end

  defp detect_resource_starvation(events) do
    resource_events = Enum.filter(events, fn e ->
      e[:domain] == "runtime" and
        Map.get(e, :payload, %{})[:action] in ["backpressure", "queue_full", "oom"]
    end)
    if length(resource_events) >= 1 do
      [{:resource_starvation, "runtime",
        "starvation_#{System.system_time(:second)}",
        %{events: length(resource_events),
          types: Enum.map(resource_events, &(Map.get(&1, :payload, %{})[:action]))}}]
    else
      []
    end
  end

  defp in_last_minutes?(timestamp, minutes) do
    case DateTime.diff(DateTime.utc_now(), timestamp, :second) do
      diff when diff <= minutes * 60 -> true
      _ -> false
    end
  end

  defp total_events_in_last?(events, seconds, threshold) do
    recent = Enum.filter(events, fn e ->
      Map.get(e, :timestamp, DateTime.utc_now()) |> in_last_seconds?(seconds)
    end)
    length(recent) >= threshold
  end

  defp in_last_seconds?(timestamp, seconds) do
    case DateTime.diff(DateTime.utc_now(), timestamp, :second) do
      diff when diff <= seconds -> true
      _ -> false
    end
  end
end
