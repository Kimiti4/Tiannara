defmodule Tiannara.CEL.Kernel.BootSequencerGateHonestyTest do
  use ExUnit.Case, async: true

  alias Tiannara.CEL.Kernel.BootSequencer
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  defmodule ExplicitStub do
    use Tiannara.Stub, subsystem: :test, phase: "test", priority: :low
  end

  defp spec(module), do: %{id: :gate_probe, module: module}

  test "constitution gate refuses an explicit stub even with a perfect self-reported score" do
    assert {:fail, "Service module is an explicit stub"} =
             BootSequencer.check_constitution(spec(ExplicitStub), fn _ ->
               ConstitutionalScore.default(:gate_probe)
             end)
  end

  test "constitution gate fails a non-stub boot-ready self-report without independent corroboration" do
    assert {:fail, reason} =
             BootSequencer.check_constitution(spec(Tiannara.World.ReplayEngine), fn _ ->
               ConstitutionalScore.default(:gate_probe)
             end)

    assert reason =~ "fail closed"
    assert reason =~ "deterministic_replay"
  end

  test "constitution gate fails a below-threshold score and reports observed values" do
    assert {:fail, reason} =
             BootSequencer.check_constitution(spec(Tiannara.World.ReplayEngine), fn _ ->
               ConstitutionalScore.unavailable(:gate_probe)
             end)

    assert reason =~ "not boot-ready"
    assert reason =~ "0.0"
  end

  test "constitution gate fails closed when the score checker raises (was a silent :pass)" do
    assert {:fail, reason} =
             BootSequencer.check_constitution(spec(Tiannara.World.ReplayEngine), fn _ ->
               raise "scoring subsystem down"
             end)

    assert reason =~ "fail closed"
    assert reason =~ "scoring subsystem down"
  end

  test "constitution gate fails closed on a non-struct score" do
    assert {:fail, reason} =
             BootSequencer.check_constitution(spec(Tiannara.World.ReplayEngine), fn _ -> nil end)

    assert reason =~ "fail closed"
  end

  test "unavailable score is all zeros and never boot-ready" do
    score = ConstitutionalScore.unavailable(:probe)

    assert score.health == 0.0
    assert score.constitutional_alignment == 0.0
    assert score.evidence_quality == 0.0
    refute ConstitutionalScore.boot_ready?(score)
  end

  test "full boot with a crashing score checker reports :failed, not a green boot" do
    report =
      BootSequencer.boot(
        fn _spec -> {:ok, self()} end,
        fn _spec -> :healthy end,
        fn _spec -> raise "score subsystem down" end,
        fn _spec -> :sufficient end
      )

    assert report.status == :failed
    assert report.failed_critical != []
    assert {:fail, reason} = report.gate_results[:executive_memory][:constitution]
    assert reason =~ "fail closed"
  end
end
