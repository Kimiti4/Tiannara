defmodule Tiannara.Omega.OmegaLoopTest do
  use ExUnit.Case, async: false

  alias Tiannara.Runtime.{EventBus, Supervisor}
  alias Tiannara.Omega.{Loop, ResearchDirector}
  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Communication.Director, as: CommDirector

  @moduletag :omega_loop

  defp uniq(prefix), do: :"#{prefix}_#{System.unique_integer([:positive])}"

  defp wait_for(fun, timeout \\ 1_000) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_wait(fun, deadline)
  end

  defp do_wait(fun, deadline) do
    cond do
      fun.() -> :ok
      System.monotonic_time(:millisecond) > deadline -> flunk("condition not met in time")
      true -> Process.sleep(20) && do_wait(fun, deadline)
    end
  end

  test "research director ranks hypotheses by information gain and proposes only" do
    event =
      EpistemicEvent.new(:contradiction_detected,
        severity: :high, payload: %{a: 10, b: 20}, confidence: 0.7)

    rd = ResearchDirector.investigate(event)

    assert length(rd.hypotheses) == 3

    gains = Enum.map(rd.hypotheses, & &1.expected_information_gain)
    assert gains == Enum.sort(gains, :desc)

    assert length(rd.proposals) == 3
    assert Enum.all?(rd.proposals, &(&1.status == :proposed))
    assert hd(rd.proposals).rank == 1
  end

  test "research director ignores non-research events" do
    refute ResearchDirector.research_relevant?(
             %EpistemicEvent{type: :knowledge_updated})

    assert ResearchDirector.research_relevant?(
             %EpistemicEvent{type: :contradiction_detected})
  end

  test "omega loop turns a bus event into ranked proposals" do
    bus = uniq(:bus)
    omega = uniq(:omega)

    {:ok, _} = EventBus.start_link(name: bus)
    {:ok, _} = Loop.start_link(name: omega, bus: bus)

    EventBus.publish(bus,
      EpistemicEvent.new(:contradiction_detected,
        severity: :high, payload: %{a: 1, b: 2}, confidence: 0.7))

    wait_for(fn -> Loop.status(omega).proposals > 0 end)

    proposals = Loop.proposals(omega)
    assert length(proposals) == 3
    assert Enum.all?(proposals, &(&1.status == :proposed))

    GenServer.stop(omega)
    GenServer.stop(bus)
  end

  test "omega loop routes improvement_proposed to the improvement queue" do
    bus = uniq(:bus)
    omega = uniq(:omega)

    {:ok, _} = EventBus.start_link(name: bus)
    {:ok, _} = Loop.start_link(name: omega, bus: bus)

    EventBus.publish(bus,
      EpistemicEvent.new(:improvement_proposed,
        severity: :medium, payload: %{target: :scheduler}, confidence: 0.5))

    wait_for(fn -> Loop.status(omega).improvement_queue > 0 end)

    assert length(Loop.improvement_queue(omega)) == 1

    GenServer.stop(omega)
    GenServer.stop(bus)
  end

  test "omega loop records communication decisions when a director is wired" do
    bus = uniq(:bus)
    omega = uniq(:omega)

    {:ok, _} = EventBus.start_link(name: bus)
    {:ok, _} = Loop.start_link(name: omega, bus: bus, comm_director: CommDirector)

    EventBus.publish(bus,
      EpistemicEvent.new(:constitutional_concern,
        severity: :critical, payload: %{}, confidence: 0.9))

    wait_for(fn -> Loop.status(omega).notification_decisions > 0 end)

    [decision | _] = Loop.notification_decisions(omega)
    assert decision.notify

    GenServer.stop(omega)
    GenServer.stop(bus)
  end

  test "end-to-end: heartbeat -> bus -> omega loop produces ranked proposals" do
    bus = uniq(:bus)
    sup = uniq(:sup)
    omega = uniq(:omega)

    analyzer = fn _obs, _cycle ->
      [EpistemicEvent.new(:contradiction_detected,
         severity: :high, payload: %{a: 10, b: 20}, confidence: 0.7)]
    end

    {:ok, _} =
      Supervisor.start_link(
        name: sup,
        bus_name: bus,
        heartbeat: [interval: 30, observer: fn -> [] end, analyzer: analyzer],
        omega: [name: omega]
      )

    wait_for(fn -> Loop.status(omega).proposals > 0 end, 2_000)

    proposals = Loop.proposals(omega)
    assert length(proposals) >= 3
    assert Enum.all?(proposals, &(&1.status == :proposed))
    assert hd(proposals).rank == 1

    Supervisor.stop(sup)
  end
end