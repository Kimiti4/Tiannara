defmodule Tiannara.Operations.CampaignTelemetry do
  use GenServer

  @max_cycles 50

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def snapshot, do: GenServer.call(__MODULE__, :snapshot)

  @impl true
  def init(_opts) do
    :telemetry.attach_many(
      "campaign-telemetry",
      [
        [:tiannara, :campaign, :cycle_stop],
        [:tiannara, :campaign, :phase_run],
        [:tiannara, :campaign, :route],
        [:tiannara, :campaign, :feedback_closed]
      ],
      &__MODULE__.handle_event/4,
      nil
    )

    {:ok, %{
      cycles: [],
      phases: %{},
      routes: %{},
      feedback: %{count: 0, last_at: nil},
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {:reply, build_snapshot(state), state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  def handle_event([:tiannara, :campaign, :cycle_stop], %{duration_ms: d}, meta, _cfg) do
    GenServer.cast(__MODULE__, {:cycle, d, meta})
  end

  def handle_event([:tiannara, :campaign, :phase_run], %{duration_ms: d}, %{phase: p, ok: ok}, _cfg) do
    GenServer.cast(__MODULE__, {:phase, p, d, ok})
  end

  def handle_event([:tiannara, :campaign, :route], %{duration_ms: d}, %{from: from, ok: ok}, _cfg) do
    GenServer.cast(__MODULE__, {:route, from, d, ok})
  end

  def handle_event([:tiannara, :campaign, :feedback_closed], _meas, %{from: from}, _cfg) do
    GenServer.cast(__MODULE__, {:feedback, from})
  end

  @impl true
  def handle_cast({:cycle, duration, meta}, state) do
    entry = %{duration_ms: duration, ok: Map.get(meta, :ok, true), at: DateTime.utc_now()}
    {:noreply, %{state | cycles: [entry | state.cycles] |> Enum.take(@max_cycles)}}
  end

  def handle_cast({:phase, phase, duration, ok}, state) do
    current = Map.get(state.phases, phase, %{ok: 0, fail: 0, last_ms: nil, last_at: nil})
    updated = %{current |
      ok: current.ok + if(ok, do: 1, else: 0),
      fail: current.fail + if(ok, do: 0, else: 1),
      last_ms: duration,
      last_at: DateTime.utc_now()
    }
    {:noreply, %{state | phases: Map.put(state.phases, phase, updated)}}
  end

  def handle_cast({:route, from, duration, _ok}, state) do
    key = to_string(from)
    current = Map.get(state.routes, key, %{count: 0, last_ms: nil, last_at: nil})
    updated = %{current | count: current.count + 1, last_ms: duration, last_at: DateTime.utc_now()}
    {:noreply, %{state | routes: Map.put(state.routes, key, updated)}}
  end

  def handle_cast({:feedback, _from}, state) do
    {:noreply, %{state | feedback: %{count: state.feedback.count + 1, last_at: DateTime.utc_now()}}}
  end

  defp build_snapshot(state) do
    durations = Enum.map(state.cycles, & &1.duration_ms)

    %{
      cycles: %{
        recent: Enum.take(state.cycles, 20) |> Enum.reverse(),
        count: length(state.cycles),
        avg_ms: avg(durations),
        p95_ms: percentile(durations, 95),
        last_ms: List.first(durations)
      },
      phases: state.phases,
      routes: state.routes,
      feedback: state.feedback,
      started_at: state.started_at
    }
  end

  defp avg([]), do: nil
  defp avg(list), do: round(Enum.sum(list) / length(list))

  defp percentile([], _), do: nil
  defp percentile(list, p) do
    sorted = Enum.sort(list)
    idx = max(0, ceil(length(sorted) * p / 100) - 1)
    Enum.at(sorted, idx)
  end
end
