defmodule Tiannara.Sentinel.Heartbeat.Server do
  @moduledoc """
  The live Ω.1 heartbeat: an autonomous GenServer loop that repeatedly runs
  observe → interpret/detect → prioritize → emit epistemic event → schedule
  next cycle. No human action is required for the loop to continue, but it can
  be paused/resumed under supervision.

  Constitutional basis: "Detect anomalies / unexpected behavior / degraded
  performance", "Capability must never outpace verification", augmentation
  clause (it observes and emits; it does not act).
  """
  use GenServer

  alias Tiannara.Sentinel.EpistemicEvent

  def start_link(opts) do
    case Keyword.get(opts, :name) do
      nil -> GenServer.start_link(__MODULE__, opts)
      name -> GenServer.start_link(__MODULE__, opts, name: name)
    end
  end

  # --- public API ---

  def pause(server), do: GenServer.call(server, :pause)
  def resume(server), do: GenServer.call(server, :resume)
  def status(server), do: GenServer.call(server, :status)

  # --- callbacks ---

  @impl true
  def init(opts) do
    interval = Keyword.get(opts, :interval, 1_000)
    observer = Keyword.get(opts, :observer, fn -> [] end)
    analyzer = Keyword.get(opts, :analyzer, fn _obs, _cycle -> [] end)
    emitter = Keyword.get(opts, :emitter, fn _event -> :ok end)
    autostart = Keyword.get(opts, :autostart, true)

    state = %{
      interval: interval,
      observer: observer,
      analyzer: analyzer,
      emitter: emitter,
      cycle: 0,
      running: autostart,
      events_emitted: 0
    }

    if autostart, do: schedule_next(interval)
    {:ok, state}
  end

  @impl true
  def handle_info(:beat, %{running: true} = state) do
    state = run_cycle(state)
    schedule_next(state.interval)
    {:noreply, state}
  end

  def handle_info(:beat, state), do: {:noreply, state}

  @impl true
  def handle_call(:pause, _from, state), do: {:reply, :ok, %{state | running: false}}

  def handle_call(:resume, _from, state) do
    if not state.running, do: schedule_next(state.interval)
    {:reply, :ok, %{state | running: true}}
  end

  def handle_call(:status, _from, state) do
    {:reply,
     %{cycle: state.cycle, running: state.running, events_emitted: state.events_emitted},
     state}
  end

  # --- internals ---

  defp run_cycle(state) do
    cycle = state.cycle + 1
    observations = state.observer.()
    events = state.analyzer.(observations, cycle)

    Enum.each(events, fn %EpistemicEvent{} = e -> state.emitter.(e) end)

    %{state | cycle: cycle, events_emitted: state.events_emitted + length(events)}
  end

  defp schedule_next(interval), do: Process.send_after(self(), :beat, interval)
end