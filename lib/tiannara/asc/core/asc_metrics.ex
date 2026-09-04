defmodule Tiannara.ASC.Core.Metrics do
  use GenServer

  @collect_interval :timer.minutes(5)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record(phase, metric_name, value, metadata \\ %{}) do
    GenServer.cast(__MODULE__, {:record, phase, metric_name, value, metadata})
  end

  def phase_metrics(phase), do: GenServer.call(__MODULE__, {:phase_metrics, phase})

  def global_health, do: GenServer.call(__MODULE__, :global_health)

  def snapshot, do: GenServer.call(__MODULE__, :snapshot)

  @impl true
  def init(_opts) do
    schedule_collection()

    {:ok, %{
      metrics: %{},
      history: [],
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_cast({:record, phase, metric_name, value, metadata}, state) do
    key = {phase, metric_name}
    entry = %{value: value, metadata: metadata, at: DateTime.utc_now()}

    metrics = Map.update(state.metrics, key, [entry], fn existing ->
      [entry | existing] |> Enum.take(1000)
    end)

    {:noreply, %{state | metrics: metrics}}
  end

  @impl true
  def handle_call({:phase_metrics, phase}, _from, state) do
    phase_metrics =
      state.metrics
      |> Enum.filter(fn {{p, _name}, _entries} -> p == phase end)
      |> Map.new(fn {{_p, name}, entries} ->
        latest = List.first(entries)
        {name, latest}
      end)

    {:reply, phase_metrics, state}
  end

  @impl true
  def handle_call(:global_health, _from, state) do
    phases = [:research, :meta_science, :engineering, :reality, :civilization]

    phase_health =
      Enum.map(phases, fn phase ->
        case Map.get(state.metrics, {phase, :health}) do
          [latest | _] -> latest.value
          _ -> 0.5
        end
      end)

    global = if phase_health != [], do: Enum.sum(phase_health) / length(phase_health), else: 0.5

    {:reply, global, state}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, %{
      metrics_count: map_size(state.metrics),
      history_depth: length(state.history),
      started_at: state.started_at
    }, state}
  end

  @impl true
  def handle_info(:collect, state) do
    :telemetry.execute([:tiannara, :asc, :metrics], %{
      metrics_count: map_size(state.metrics)
    }, %{})

    schedule_collection()
    {:noreply, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp schedule_collection do
    Process.send_after(self(), :collect, @collect_interval)
  end
end
