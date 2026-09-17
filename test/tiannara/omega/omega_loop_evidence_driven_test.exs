defmodule Tiannara.Omega.OmegaLoopEvidenceDrivenTest do
  use ExUnit.Case, async: false

  alias Tiannara.Runtime.EventBus
  alias Tiannara.Omega.Loop
  alias Tiannara.Sentinel.EpistemicEvent

  @moduletag :omega_loop_evidence_driven

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

  test "omega loop uses the evidence-driven director and stores full investigations" do
    bus = uniq(:bus)
    omega = uniq(:omega)

    {:ok, _} = EventBus.start_link(name: bus)
    {:ok, _} = Loop.start_link(name: omega, bus: bus)

    EventBus.publish(bus,
      EpistemicEvent.new(:contradiction_detected,
        severity: :high,
        payload: %{quantity: :x},
        confidence: 0.7,
        evidence: [%{quantity: :x, value: 10}, %{quantity: :x, value: 20}]))

    wait_for(fn -> Loop.status(omega).investigations > 0 end)

    [investigation] = Loop.investigations(omega)

    # evidence-driven director exposes the full investigation
    assert investigation.evidence_assessment.sufficiency == :contradicted
    assert length(investigation.hypotheses) == 3
    assert Enum.all?(investigation.hypotheses, &(&1.falsifiers != []))

    # proposals are extracted and still :proposed only
    proposals = Loop.proposals(omega)
    assert length(proposals) == 3
    assert Enum.all?(proposals, &(&1.status == :proposed))

    GenServer.stop(omega)
    GenServer.stop(bus)
  end
end