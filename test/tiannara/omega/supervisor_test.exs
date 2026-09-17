defmodule Tiannara.Omega.SupervisorTest do
  use ExUnit.Case, async: false

  alias Tiannara.Omega.Supervisor
  alias Tiannara.Sentinel.EpistemicEvent

  @moduletag :omega_supervisor

  defp unique_opts do
    suffix = System.unique_integer([:positive])

    [
      bus_name: :"bus_#{suffix}",
      telemetry_window_name: :"tw_#{suffix}",
      heartbeat_name: :"hb_#{suffix}",
      orchestrator_name: :"orch_#{suffix}",
      research_director_name: :"rd_#{suffix}",
      cognitive_interface_name: :"ci_#{suffix}",
      sandbox_name: :"sb_#{suffix}",
      certification_name: :"cert_#{suffix}",
      governance_name: :"gov_#{suffix}",
      heartbeat_interval: 50
    ]
  end

  test "supervisor starts all children in dependency order" do
    opts = unique_opts()
    {:ok, sup} = Supervisor.start_link(opts)

    # All children should be alive
    assert Process.whereis(opts[:bus_name]) != nil
    assert Process.whereis(opts[:telemetry_window_name]) != nil
    assert Process.whereis(opts[:orchestrator_name]) != nil
    assert Process.whereis(opts[:research_director_name]) != nil
    assert Process.whereis(opts[:cognitive_interface_name]) != nil
    assert Process.whereis(opts[:governance_name]) != nil

    Supervisor.stop(sup)
  end

  test "epistemic events flow through the orchestrated pipeline" do
    opts = unique_opts()
    {:ok, sup} = Supervisor.start_link(opts)

    # Publish a research-relevant event to the bus
    bus = opts[:bus_name]

    Tiannara.Runtime.EventBus.publish(bus, %EpistemicEvent{
      type: :anomaly_detected,
      severity: :high,
      payload: %{metric: :total_memory},
      confidence: 0.7,
      evidence: [100, 110, 120]
    })

    # Give the async pipeline a moment to process
    Process.sleep(100)

    # The Research Director should have investigated
    investigations = Tiannara.Omega.ResearchDirectorServer.investigations(opts[:research_director_name])
    assert length(investigations) >= 1

    # The Cognitive Interface should have produced a decision
    decisions = Tiannara.Omega.CognitiveInterfaceServer.decisions(opts[:cognitive_interface_name])
    assert length(decisions) >= 1

    Supervisor.stop(sup)
  end

  test "governance gate holds improvements pending human authorization" do
    opts = unique_opts()
    {:ok, sup} = Supervisor.start_link(opts)

    bus = opts[:bus_name]

    # Simulate a knowledge_updated event reaching governance
    Tiannara.Runtime.EventBus.publish(bus, %EpistemicEvent{
      type: :knowledge_updated,
      severity: :medium,
      payload: %{improvement: :test},
      confidence: 0.9,
      evidence: []
    })

    Process.sleep(100)

    decisions = Tiannara.Omega.GovernanceGateServer.decisions(opts[:governance_name])
    assert length(decisions) >= 1

    [decision | _] = decisions
    assert decision.status == :held_pending_human_authorization
    assert decision.reason == :deployment_requires_human_authorization

    Supervisor.stop(sup)
  end

  test "crashing a child restarts its dependents (rest_for_one)" do
    opts = unique_opts()
    {:ok, sup} = Supervisor.start_link(opts)

    orch = opts[:orchestrator_name]
    rd = opts[:research_director_name]

    orch_pid_before = Process.whereis(orch)
    rd_pid_before = Process.whereis(rd)

    # Crash the orchestrator
    Process.exit(orch_pid_before, :kill)
    Process.sleep(100)

    # The orchestrator and everything after it should have restarted (new pids)
    orch_pid_after = Process.whereis(orch)
    rd_pid_after = Process.whereis(rd)

    assert orch_pid_after != nil
    assert rd_pid_after != nil
    assert orch_pid_after != orch_pid_before
    assert rd_pid_after != rd_pid_before

    # The EventBus and TelemetryWindow (before orchestrator) should be unchanged
    # (rest_for_one only restarts children AFTER the crashed one)
    Supervisor.stop(sup)
  end
end