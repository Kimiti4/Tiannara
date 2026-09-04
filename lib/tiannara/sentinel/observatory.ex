defmodule Tiannara.Sentinel.Observatory do
  @moduledoc """
  Universal Observation System — continuous telemetry subscription across all
  Tiannara subsystems with real-time health/event/metric observation loop.

  Maintains ETS-backed observation history, manages subscriptions, aggregates
  observations into rolling windows, and tracks evidence confidence over time.
  """
  use GenServer
  require Logger

  alias Tiannara.Sentinel.Observation

  # ── Configuration ──

  @health_poll_interval_ms 15_000
  @metric_aggregation_window 60_000
  @max_history_per_stream 10_000
  @confidence_decay_halflife_ms 300_000

  # ── Public API ──

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a subsystem for continuous observation.
  Config controls polling rate, which metrics to collect, etc.
  """
  def register_subsystem(subsystem, config \\ %{}) do
    GenServer.call(__MODULE__, {:register_subsystem, subsystem, config}, :infinity)
  end

  @doc """
  Unregisters a subsystem from observation and cleans up its streams.
  """
  def unregister_subsystem(subsystem) do
    GenServer.call(__MODULE__, {:unregister_subsystem, subsystem})
  end

  @doc """
  Ingests an observation into the system. Called by TelemetryHub or any
  observed subsystem.
  """
  def observe(type, subsystem, data, opts \\ []) do
    obs = Observation.new(type, subsystem, data, opts)
    GenServer.cast(__MODULE__, {:observe, obs})
    obs
  end

  @doc """
  Returns the current observation history for a given stream.
  Stream format: "health:subsystem", "event:subsystem", "metric:subsystem"
  """
  def get_stream(stream, limit \\ 100) do
    GenServer.call(__MODULE__, {:get_stream, stream, limit})
  end

  @doc """
  Returns all registered subsystems with their observation configs.
  """
  def list_subsystems do
    GenServer.call(__MODULE__, :list_subsystems)
  end

  @doc """
  Returns observation statistics per stream: count, latest, confidence trend.
  """
  def get_stream_stats do
    GenServer.call(__MODULE__, :get_stream_stats)
  end

  @doc """
  Registers a callback to be invoked for every observation on a given stream.
  Returns a subscription reference for cancellation.
  """
  def subscribe(stream, callback) when is_function(callback, 1) do
    GenServer.call(__MODULE__, {:subscribe, stream, callback})
  end

  @doc """
  Cancels a subscription by its reference.
  """
  def unsubscribe(ref) do
    GenServer.call(__MODULE__, {:unsubscribe, ref})
  end

  @doc """
  Returns aggregated metrics for a subsystem over the aggregation window.
  """
  def aggregated_metrics(subsystem, window_ms \\ @metric_aggregation_window) do
    GenServer.call(__MODULE__, {:aggregated_metrics, subsystem, window_ms})
  end

  @doc """
  Returns the latest health observation for a subsystem.
  """
  def latest_health(subsystem) do
    stream = Observation.observation_stream(:health, subsystem)
    case get_stream(stream, 1) do
      [obs | _] -> {:ok, obs}
      [] -> {:error, :no_health_data}
    end
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    :ets.new(:observatory_history, [:ordered_set, :public, :named_table])
    :ets.new(:observatory_subsystems, [:set, :public, :named_table])
    :ets.new(:observatory_subscriptions, [:set, :public, :named_table])

    schedule_health_poll()

    Logger.info("🔭 [OBSERVATORY] Universal Observation System initialized.")
    {:ok, %{
      history_table: :observatory_history,
      subsystems_table: :observatory_subsystems,
      subscriptions_table: :observatory_subscriptions,
      next_sub_ref: 1,
      poll_interval: @health_poll_interval_ms
    }}
  end

  @impl true
  def handle_call({:register_subsystem, subsystem, config}, _from, state) do
    :ets.insert(state.subsystems_table, {subsystem, config, DateTime.utc_now()})
    Logger.info("🔭 [OBSERVATORY] Subsystem registered: #{inspect(subsystem)}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:unregister_subsystem, subsystem}, _from, state) do
    :ets.delete(state.subsystems_table, subsystem)
    # Remove all history entries for this subsystem's streams
    [:health, :event, :metric]
    |> Enum.each(fn type ->
      stream = Observation.observation_stream(type, subsystem)
      delete_stream_entries(state.history_table, stream)
    end)
    Logger.info("🔭 [OBSERVATORY] Subsystem unregistered: #{inspect(subsystem)}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get_stream, stream, limit}, _from, state) do
    result = read_stream(state.history_table, stream, limit)
    {:reply, result, state}
  end

  @impl true
  def handle_call(:list_subsystems, _from, state) do
    subsystems = :ets.tab2list(state.subsystems_table)
    |> Enum.map(fn {sub, config, registered_at} ->
      %{subsystem: sub, config: config, registered_at: registered_at}
    end)
    {:reply, subsystems, state}
  end

  @impl true
  def handle_call(:get_stream_stats, _from, state) do
    stats = compute_stream_stats(state.history_table)
    {:reply, stats, state}
  end

  @impl true
  def handle_call({:subscribe, stream, callback}, {pid, _}, state) do
    ref = state.next_sub_ref
    :ets.insert(state.subscriptions_table, {ref, stream, callback, pid})
    {:reply, ref, %{state | next_sub_ref: ref + 1}}
  end

  @impl true
  def handle_call({:unsubscribe, ref}, _from, state) do
    :ets.delete(state.subscriptions_table, ref)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:aggregated_metrics, subsystem, window_ms}, _from, state) do
    stream = Observation.observation_stream(:metric, subsystem)
    now = System.system_time(:millisecond)
    cutoff = now - window_ms

    entries = read_stream_raw(state.history_table, stream)
    |> Enum.filter(fn {ts, _obs} -> ts >= cutoff end)

    result = cond do
      entries == [] -> %{subsystem: subsystem, count: 0, avg: nil, min: nil, max: nil, window_ms: window_ms}
      true ->
        values = entries |> Enum.map(fn {_ts, obs} -> extract_metric_value(obs) end) |> Enum.reject(&is_nil/1)
        %{
          subsystem: subsystem,
          count: length(values),
          sum: Enum.sum(values),
          avg: if(values != [], do: Enum.sum(values) / length(values), else: nil),
          min: if(values != [], do: Enum.min(values), else: nil),
          max: if(values != [], do: Enum.max(values), else: nil),
          window_ms: window_ms
        }
    end
    {:reply, result, state}
  end

  @impl true
  def handle_cast({:observe, %Observation{} = obs}, state) do
    stream = obs.stream
    now = System.system_time(:millisecond)

    # Store in history with timestamp key for ordered retrieval
    entry = {{stream, now}, obs}
    :ets.insert(state.history_table, entry)

    # Enforce history size limit
    maybe_prune_stream(state.history_table, stream)

    # Notify subscribers
    notify_subscribers(state.subscriptions_table, stream, obs)

    # Route to downstream Sentinel subsystems
    route_observation(obs)

    {:noreply, state}
  end

  @impl true
  def handle_info(:health_poll, state) do
    # Perform health check on all registered subsystems
    subsystems = :ets.tab2list(state.subsystems_table)
    |> Enum.map(fn {sub, _config, _registered_at} -> sub end)

    Enum.each(subsystems, fn subsystem ->
      health_data = probe_health(subsystem)
      obs = Observation.new(:health, subsystem, health_data,
        stream: "health:#{subsystem}",
        tags: ["health_check", "auto"],
        confidence: health_data[:confidence] || 0.8
      )

      entry = {{obs.stream, System.system_time(:millisecond)}, obs}
      :ets.insert(state.history_table, entry)
      maybe_prune_stream(state.history_table, obs.stream)
      notify_subscribers(state.subscriptions_table, obs.stream, obs)
      route_observation(obs)
    end)

    schedule_health_poll()
    {:noreply, state}
  end

  # ── Private Helpers ──

  defp schedule_health_poll do
    Process.send_after(self(), :health_poll, @health_poll_interval_ms)
  end

  defp read_stream(table, stream, limit) do
    ms = [{{{stream, :_}, :_}, [], [:"$_"]}]
    case :ets.select(table, ms, limit) do
      {entries, _continuation} ->
        entries
        |> Enum.map(fn {{_s, ts}, obs} -> %{obs | metadata: Map.put(obs.metadata, :ets_timestamp, ts)} end)
        |> Enum.reverse()
      :"$end_of_table" ->
        []
    end
  end

  defp read_stream_raw(table, stream) do
    ms = [{{{stream, :_}, :_}, [], [:"$_"]}]
    :ets.select(table, ms)
    |> Enum.map(fn {{_s, ts}, obs} -> {ts, obs} end)
  end

  defp delete_stream_entries(table, stream) do
    :ets.select_delete(table, [{{{stream, :_}, :_}, [], [true]}])
  end

  defp maybe_prune_stream(table, stream) do
    ms = [{{{stream, :_}, :_}, [], [true]}]
    count = :ets.select_count(table, ms)
    if count > @max_history_per_stream do
      :ets.select_delete(table, ms)
    end
  end

  defp compute_stream_stats(table) do
    all = :ets.tab2list(table)
    grouped = Enum.group_by(all, fn {{stream, _ts}, _obs} -> stream end)

    Map.new(grouped, fn {stream, entries} ->
      sorted = Enum.sort_by(entries, fn {{_s, ts}, _obs} -> ts end, :desc)
      latest = case sorted do
        [{_key, obs} | _] -> obs
        [] -> nil
      end
      count = length(entries)

      {stream, %{
        count: count,
        latest: latest,
        oldest_timestamp: entries |> Enum.map(fn {{_s, ts}, _obs} -> ts end) |> Enum.min()
      }}
    end)
  end

  defp notify_subscribers(sub_table, stream, obs) do
    ms = [{{:"$1", stream, :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}]
    subscribers = :ets.select(sub_table, ms)

    Enum.each(subscribers, fn {ref, callback, pid} ->
      if Process.alive?(pid) do
        spawn(fn -> callback.(obs) end)
      else
        :ets.delete(sub_table, ref)
      end
    end)
  end

  defp route_observation(%Observation{type: :health} = obs) do
    # Health observations: forward to AnomalyDetector for deviation analysis
    Tiannara.Sentinel.AnomalyDetector.analyze(obs.subsystem, :health, obs.data)
  end

  defp route_observation(%Observation{type: :metric} = obs) do
    # Metrics: forward for anomaly detection and operational tracking
    Tiannara.Sentinel.AnomalyDetector.analyze(obs.subsystem, :metric, obs.data)
  end

  defp route_observation(%Observation{type: :event} = obs) do
    # Events: log and forward to relevant subsystems
    Logger.debug("[OBSERVATORY] Event from #{obs.subsystem}: #{inspect(obs.data)}")
    Tiannara.Sentinel.AnomalyDetector.analyze(obs.subsystem, :event, obs.data)
  end

  defp route_observation(_obs), do: :ok

  defp probe_health(subsystem) do
    # Attempt to check if the subsystem's module is loaded and responsive
    module_name = subsystem_name_to_module(subsystem)

    responsiveness =
      if Code.ensure_loaded?(module_name) and function_exported?(module_name, :start_link, 1) do
        0.95
      else
        0.5
      end

    %{
      subsystem: subsystem,
      status: if(responsiveness > 0.7, do: :healthy, else: :degraded),
      responsiveness: responsiveness,
      confidence: 0.8,
      checked_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      version: 1
    }
  end

  defp subsystem_name_to_module(subsystem) do
    subsystem
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> then(fn parts -> Module.concat([Tiannara | parts]) end)
  end

  defp extract_metric_value(%Observation{data: %{value: v}}) when is_number(v), do: v
  defp extract_metric_value(%Observation{data: %{value: v}}) when is_float(v), do: v
  defp extract_metric_value(%Observation{data: data}) do
    # Try common metric fields
    cond do
      is_map(data) and Map.has_key?(data, :score) -> data[:score]
      is_map(data) and Map.has_key?(data, :entropy) -> data[:entropy]
      is_map(data) and Map.has_key?(data, :accuracy) -> data[:accuracy]
      is_map(data) and Map.has_key?(data, :deviation) -> data[:deviation]
      true -> nil
    end
  end
end
