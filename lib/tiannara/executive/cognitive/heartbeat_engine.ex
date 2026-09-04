defmodule Tiannara.Executive.Cognitive.HeartbeatEngine do
  @moduledoc """
  Heartbeat Engine — the continuous clock driving the cognitive cycle.

  Emits a `:heartbeat` message at a configurable interval, triggering
  the ExecutiveCycle to advance through its phases.
  """

  use GenServer

  require Logger

  @default_interval_ms 5_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @spec uptime_seconds() :: non_neg_integer()
  def uptime_seconds do
    GenServer.call(__MODULE__, :uptime_seconds)
  end

  @spec trigger() :: :ok
  def trigger do
    GenServer.cast(__MODULE__, :trigger)
  end

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval_ms, @default_interval_ms)
    started_at = DateTime.utc_now()
    schedule_heartbeat(interval)
    Logger.info("[HeartbeatEngine] Started. Interval: #{interval}ms")
    {:ok, %{interval_ms: interval, started_at: started_at, beat_count: 0, last_beat_at: nil}}
  end

  @impl true
  def handle_info(:heartbeat, state) do
    beat_count = state.beat_count + 1
    now = DateTime.utc_now()

    :telemetry.execute(
      [:tiannara, :ecr, :heartbeat],
      %{count: beat_count},
      %{interval_ms: state.interval_ms}
    )

    Tiannara.Executive.Cognitive.ExecutiveCycle.advance()
    schedule_heartbeat(state.interval_ms)
    {:noreply, %{state | beat_count: beat_count, last_beat_at: now}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{interval_ms: state.interval_ms, beat_count: state.beat_count, last_beat_at: state.last_beat_at, started_at: state.started_at}, state}
  end

  @impl true
  def handle_call(:uptime_seconds, _from, state) do
    uptime = DateTime.diff(DateTime.utc_now(), state.started_at, :second)
    {:reply, uptime, state}
  end

  @impl true
  def handle_cast(:trigger, state) do
    send(self(), :heartbeat)
    {:noreply, state}
  end

  defp schedule_heartbeat(interval) do
    Process.send_after(self(), :heartbeat, interval)
  end
end
