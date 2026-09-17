defmodule Tiannara.ObservabilityTest do
  use ExUnit.Case, async: true

  test "runtime_snapshot reports memory, processes and subsystem health" do
    snap = Tiannara.Observability.runtime_snapshot()

    assert snap.memory_mb > 0
    assert snap.process_count > 0
    assert snap.run_queue >= 0
    assert snap.uptime_seconds >= 0
    assert snap.subsystems_total > 0
    assert is_boolean(snap.all_healthy)
    assert snap.at != nil
  end

  test "discovery_snapshot reports scheduler liveness and counters" do
    snap = Tiannara.Observability.discovery_snapshot()

    assert is_boolean(snap.scheduler_alive)
    assert snap.discovery_cycles >= 0
    assert snap.gaps_detected >= 0
    assert snap.hypotheses_generated >= 0
    assert snap.knowledge_entities >= 0
    assert snap.world_entities >= 0
    assert snap.at != nil
  end

  test "discovery_interpretation returns a status without raising" do
    result = Tiannara.Observability.discovery_interpretation()

    assert result.status in [
             :scheduler_down,
             :no_cycles,
             :possible_stall,
             :active,
             :healthy_quiet
           ]

    assert result.label != nil
  end
end
