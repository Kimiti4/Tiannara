defmodule Tiannara.Runtime.LiveWiringTest do
  use ExUnit.Case, async: false

  alias Tiannara.Runtime.{EventBus, Supervisor, LiveWiringHelper}
  alias Tiannara.Sentinel.Heartbeat.Server, as: Heartbeat
  alias Tiannara.Sentinel.EpistemicEvent

  @moduletag :live_wiring

  defp uniq(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"

  test "event bus delivers published events to subscribers" do
    bus = uniq(:bus)
    {:ok, _} = EventBus.start_link(name: bus)

    :ok = EventBus.subscribe(bus, self())
    EventBus.publish(bus, %EpistemicEvent{type: :anomaly_detected})

    assert_receive {:epistemic_event, %EpistemicEvent{type: :anomaly_detected}}, 200
    assert length(EventBus.history(bus)) == 1

    GenServer.stop(bus)
  end

  test "heartbeat cycles autonomously and emits events" do
    test_pid = self()
    observer = fn -> [%{x: 1}] end

    analyzer = fn _obs, cycle ->
      [EpistemicEvent.new(:anomaly_detected,
         severity: :medium, payload: %{cycle: cycle}, confidence: 0.5)]
    end

    emitter = fn event -> send(test_pid, {:emitted, event}) end

    {:ok, pid} =
      Heartbeat.start_link(interval: 20, observer: observer, analyzer: analyzer, emitter: emitter)

    assert_receive {:emitted, %EpistemicEvent{type: :anomaly_detected}}, 500

    status = Heartbeat.status(pid)
    assert status.cycle >= 1
    assert status.running

    GenServer.stop(pid)
  end

  test "heartbeat can be paused and resumed" do
    {:ok, pid} =
      Heartbeat.start_link(interval: 10, observer: fn -> [] end,
        analyzer: fn _, _ -> [] end, emitter: fn _ -> :ok end)

    :ok = Heartbeat.pause(pid)
    refute Heartbeat.status(pid).running

    :ok = Heartbeat.resume(pid)
    assert Heartbeat.status(pid).running

    GenServer.stop(pid)
  end

  test "supervisor wires heartbeat -> event bus" do
    bus = uniq(:bus)
    sup = uniq(:sup)

    analyzer = fn _obs, cycle ->
      [EpistemicEvent.new(:anomaly_detected,
         severity: :low, payload: %{cycle: cycle}, confidence: 0.5)]
    end

    {:ok, _} =
      Supervisor.start_link(
        name: sup,
        bus_name: bus,
        heartbeat: [interval: 30, observer: fn -> [] end, analyzer: analyzer]
      )

    :ok = EventBus.subscribe(bus, self())
    assert_receive {:epistemic_event, %EpistemicEvent{type: :anomaly_detected}}, 500

    Supervisor.stop(sup)
  end
end