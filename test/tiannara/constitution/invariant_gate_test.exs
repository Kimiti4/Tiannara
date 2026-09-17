defmodule Tiannara.Constitution.InvariantGateTest do
  use ExUnit.Case, async: false

  alias Tiannara.Constitution.{Invariant, Suite, Gate, Registry}
  alias Tiannara.Constitution.Runtime.Monitor
  alias Tiannara.Certification.Certificate
  alias Tiannara.Sentinel.EpistemicEvent

  @moduletag :constitutional_gate

  test "default invariant suite passes (all guarantees hold)" do
    run = Suite.run(Suite.new(Registry.default_invariants()))
    assert run.all_passed
    assert run.failed == []
    assert Gate.verdict(run) == :gate_open
  end

  test "a failing invariant closes the gate" do
    failing = Invariant.new(:forced_failure, "forced", :test, fn -> {:error, :forced} end)
    passing = Invariant.new(:ok_check, "ok", :test, fn -> :ok end)

    run = Suite.run(Suite.new([passing, failing]))
    refute run.all_passed
    assert run.failed == [:forced_failure]
    assert Gate.verdict(run) == {:gate_closed, [:forced_failure]}
  end

  test "a raising probe is treated as a violation, never skipped" do
    raising = Invariant.new(:raising, "raises", :test, fn -> raise "boom" end)
    run = Suite.run(Suite.new([raising]))
    refute run.all_passed
    assert [result] = run.results
    refute result.passed
  end

  test "certification is refused while any invariant fails" do
    failing = Invariant.new(:forced_failure, "forced", :test, fn -> {:error, :forced} end)
    run = Suite.run(Suite.new([failing]))

    assert {:refused, cert} = Certificate.certify(:subsystem_x, run)
    assert cert.verdict == :not_certified
    assert cert.reason == {:constitutional_invariants_failed, [:forced_failure]}
  end

  test "certification granted when invariants pass and functional gates open" do
    run = Suite.run(Suite.new(Registry.default_invariants()))

    assert {:certified, cert} =
             Certificate.certify(:subsystem_x, run,
               functional_gates: %{recovery: :open, evidence_integrity: :open})

    assert cert.verdict == :certified
  end

  test "certification refused if a functional gate is closed even when invariants pass" do
    run = Suite.run(Suite.new(Registry.default_invariants()))

    assert {:refused, cert} =
             Certificate.certify(:subsystem_x, run, functional_gates: %{recovery: :closed})

    assert cert.reason == {:functional_gates_closed, [:recovery]}
  end

  test "runtime monitor emits a constitutional_concern when invariants fail" do
    failing = Invariant.new(:forced_failure, "forced", :test, fn -> {:error, :forced} end)
    suite = Suite.new([failing])
    test_pid = self()
    publisher = fn event -> send(test_pid, {:published, event}) end

    {:ok, pid} = Monitor.start_link(suite: suite, interval: 50, publisher: publisher)

    assert_receive {:published, %EpistemicEvent{type: :constitutional_concern}}, 500

    run = Monitor.last_run(pid)
    assert Gate.verdict(run) == {:gate_closed, [:forced_failure]}
    GenServer.stop(pid)
  end

  test "runtime monitor does not emit when invariants pass" do
    suite = Suite.new(Registry.default_invariants())
    test_pid = self()
    publisher = fn event -> send(test_pid, {:published, event}) end

    {:ok, pid} = Monitor.start_link(suite: suite, interval: 50, publisher: publisher)

    run = Monitor.run_now(pid)
    assert run.all_passed

    refute_receive {:published, _}, 200
    GenServer.stop(pid)
  end
end