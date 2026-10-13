defmodule Tiannara.CEL.Kernel.BootSequencerValueGateTest do
  use ExUnit.Case, async: true

  alias Tiannara.CEL.Kernel.BootSequencer
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  defmodule LiveHealthyProbe do
    def healthy?, do: true
    def capabilities, do: [:probe_capability]
  end

  defp spec(module), do: %{id: :b12_probe, module: module}

  defp perfect_score, do: ConstitutionalScore.default(:b12_probe)

  defp fresh_evidence(_spec) do
    %{
      collected_at: DateTime.utc_now(),
      process_alive: true,
      health_observed: :healthy,
      capability_probes: %{}
    }
  end

  test "corroborated boot-ready claim passes the constitution gate" do
    assert :pass =
             BootSequencer.check_constitution(spec(LiveHealthyProbe), fn _ -> perfect_score() end, &fresh_evidence/1)
  end

  test "missing corroboration evidence fails closed and never credits the self-report" do
    assert {:fail, reason} =
             BootSequencer.check_constitution(spec(LiveHealthyProbe), fn _ -> perfect_score() end, fn _ -> %{} end)

    assert reason =~ "malformed"
    assert reason =~ "missing keys"
    assert reason =~ "fail closed"
  end

  test "perfect score contradicted by observed health fails closed" do
    evidence = fn spec ->
      %{fresh_evidence(spec) | health_observed: :unhealthy}
    end

    assert {:fail, reason} =
             BootSequencer.check_constitution(spec(LiveHealthyProbe), fn _ -> perfect_score() end, evidence)

    assert reason =~ "contradicted"
    assert reason =~ "fail closed"
  end

  test "partial evidence missing required keys fails closed" do
    evidence = fn spec ->
      Map.drop(fresh_evidence(spec), [:health_observed])
    end

    assert {:fail, reason} =
             BootSequencer.check_constitution(spec(LiveHealthyProbe), fn _ -> perfect_score() end, evidence)

    assert reason =~ "missing keys"
    assert reason =~ "health_observed"
  end

  test "malformed evidence field types fail closed" do
    evidence = fn spec ->
      %{fresh_evidence(spec) | process_alive: "yes"}
    end

    assert {:fail, reason} =
             BootSequencer.check_constitution(spec(LiveHealthyProbe), fn _ -> perfect_score() end, evidence)

    assert reason =~ "malformed"
    assert reason =~ "process_alive"
    assert reason =~ "fail closed"
  end

  test "stale corroboration evidence fails closed" do
    evidence = fn spec ->
      %{fresh_evidence(spec) | collected_at: DateTime.add(DateTime.utc_now(), -400, :second)}
    end

    assert {:fail, reason} =
             BootSequencer.check_constitution(spec(LiveHealthyProbe), fn _ -> perfect_score() end, evidence)

    assert reason =~ "stale"
    assert reason =~ "fail closed"
  end

  test "corroboration failure never substitutes ConstitutionalScore.default as a pass" do
    assert {:fail, reason} =
             BootSequencer.check_constitution(spec(LiveHealthyProbe), fn _ -> perfect_score() end, fn _ ->
               raise "corroboration source down"
             end)

    assert reason =~ "fail closed"
    assert reason =~ "corroboration source down"
    refute reason =~ "pass"
  end

  test "ReplayEngine unavailable admission fails despite a perfect self-reported score" do
    assert {:fail, reason} =
             BootSequencer.check_constitution(
               spec(Tiannara.World.ReplayEngine),
               fn _ ->
                 %ConstitutionalScore{
                   service_id: :replay_engine,
                   health: 1.0,
                   constitutional_alignment: 1.0,
                   transparency: 1.0,
                   explainability: 1.0,
                   evidence_quality: 1.0,
                   human_oversight: 1.0,
                   computed_at: DateTime.utc_now()
                 }
               end
             )

    assert reason =~ "not independently executable"
    assert reason =~ "deterministic_replay"
    assert reason =~ "fail closed"
  end

  test "healthy service with live process still passes independent corroboration" do
    pid = spawn(fn -> Process.sleep(:infinity) end)
    Process.register(pid, LiveHealthyProbe)

    on_exit(fn ->
      if Process.alive?(pid), do: Process.exit(pid, :kill)
    end)

    assert :pass = BootSequencer.check_constitution(spec(LiveHealthyProbe), fn _ -> perfect_score() end)
  end

  test "failure path still fails: below-threshold score and raising checker never pass" do
    assert {:fail, below} =
             BootSequencer.check_constitution(spec(LiveHealthyProbe), fn _ ->
               ConstitutionalScore.unavailable(:b12_probe)
             end)

    assert below =~ "not boot-ready"

    assert {:fail, raised} =
             BootSequencer.check_constitution(spec(LiveHealthyProbe), fn _ ->
               raise "scoring subsystem down"
             end)

    assert raised =~ "fail closed"
    assert raised =~ "scoring subsystem down"
  end
end
