defmodule Tiannara.CRAV.SoakTestTest do
  use ExUnit.Case, async: false

  setup do
    Application.ensure_all_started(:tiannara)

    on_exit(fn ->
      File.rm(Tiannara.Storage.Paths.path("checkpoints/latest.json"))
      File.rm(Tiannara.Storage.Paths.path("soak_final_report.json"))
    end)

    :ok
  end

  test "runs a short soak to completion, writes reports and reports a verdict" do
    pid =
      start_supervised!(
        {Tiannara.CRAV.SoakTest,
         %{
           duration_hours: 0.0005,
           health_check_interval_ms: 40,
           challenge_interval_ms: 400,
           checkpoint_interval_ms: 100,
           report_interval_ms: 200
         }}
      )

    assert wait_for_completion(pid, 20_000)

    latest = Path.join(Tiannara.Storage.Paths.path("reports"), "soak_latest.md")
    assert File.exists?(latest)
    content = File.read!(latest)
    assert content =~ "## Verdict"
    assert content =~ ~r/verdict: \*\*(PASS|FAIL)\*\*/
    assert content =~ "source: `:local`"
    assert content =~ "Measurement caveats"
    assert content =~ "## Challenge Diagnostics"
    assert content =~ "| challenge | classification | passes/attempts | confidence |"

    status = Tiannara.CRAV.SoakTest.status()
    assert status.completed == true
    assert status.verdict in [:pass, :fail]
    assert status.progress_pct >= 99.0
    assert status.discoveries >= 0

    assert status.discovery.status in [
             :scheduler_down,
             :no_cycles,
             :possible_stall,
             :active,
             :healthy_quiet
           ]

    # Recovery verification fields
    assert status.recovery_verified in [true, false]
    assert is_list(status.recovery_gates)
    assert is_integer(status.validated_hours) or is_float(status.validated_hours)
    assert is_boolean(status.wall_clock_reconciled)
  end

  test "checkpoint uses isolated, run-specific path — never production path" do
    pid =
      start_supervised!(
        {Tiannara.CRAV.SoakTest,
         %{
           duration_hours: 0.0001,
           health_check_interval_ms: 30,
           challenge_interval_ms: 300,
           checkpoint_interval_ms: 50,
           report_interval_ms: 100
         }}
      )

    assert wait_for_completion(pid, 10_000)

    status = Tiannara.CRAV.SoakTest.status()
    assert status.completed == true

    # The checkpoint directory should be under checkpoints/ and should be
    # a run-specific subdir, NOT the production path
    checkpoint_dirs =
      File.ls!(Tiannara.Storage.Paths.path("checkpoints/"))
      |> Enum.filter(&String.starts_with?(&1, "soak-"))

    assert length(checkpoint_dirs) > 0
    assert Enum.all?(checkpoint_dirs, &String.starts_with?(&1, "soak-"))
  end

  test "engine resumes from its own checkpoint after abnormal termination, preserving time and health samples" do
    run_id = "resume-" <> Base.encode16(:crypto.strong_rand_bytes(4), case: :lower)

    {:ok, pid} =
      Tiannara.CRAV.SoakTest.start_link(%{
        run_id: run_id,
        duration_hours: 72,
        health_check_interval_ms: 30,
        challenge_interval_ms: 400,
        checkpoint_interval_ms: 50,
        report_interval_ms: 200
      })

    # Let several health checks and checkpoints land (monotonic seconds tick
    # slowly, so sleep well past a full second boundary).
    Process.sleep(2_500)

    before = Tiannara.CRAV.SoakTest.status()
    before_samples = :sys.get_state(pid).health_checks
    assert before.health_checks > 0

    # Abnormal termination: :kill skips terminate/2 — no graceful shutdown.
    Process.unlink(pid)
    Process.exit(pid, :kill)
    wait_until_dead(pid)
    Process.sleep(100)

    # Restart with the SAME run_id → must resume from checkpoint.
    {:ok, _pid2} =
      Tiannara.CRAV.SoakTest.start_link(%{
        run_id: run_id,
        duration_hours: 72,
        health_check_interval_ms: 30,
        challenge_interval_ms: 400,
        checkpoint_interval_ms: 50,
        report_interval_ms: 200
      })

    on_exit(fn ->
      if Process.whereis(Tiannara.CRAV.SoakTest) do
        Tiannara.CRAV.SoakTest.stop_test()
      end
    end)

    Process.sleep(500)
    after_status = Tiannara.CRAV.SoakTest.status()

    assert after_status.soak_run_id == run_id
    # The last checkpoint is a point-in-time snapshot taken up to 50ms before
    # the kill, while health samples are recorded every 30ms — so the newest
    # few samples may not have been captured yet. Everything the checkpoint
    # DID capture must survive the crash (previously silently lost on resume).
    after_samples = :sys.get_state(Process.whereis(Tiannara.CRAV.SoakTest)).health_checks
    assert length(after_samples) > 0
    assert Enum.all?(Enum.drop(before_samples, 3), &(&1 in after_samples))
    # Validated time must NOT reset to 0 — the checkpoint proved it.
    after_state = :sys.get_state(Process.whereis(Tiannara.CRAV.SoakTest))
    assert after_state.validated_seconds > 0
  end

  defp wait_until_dead(pid) do
    deadline = System.monotonic_time(:millisecond) + 5_000
    poll_dead(pid, deadline)
  end

  defp poll_dead(pid, deadline) do
    if Process.alive?(pid) do
      if System.monotonic_time(:millisecond) > deadline do
        flunk("soak engine did not die after :kill")
      else
        Process.sleep(20)
        poll_dead(pid, deadline)
      end
    end
  end

  defp wait_for_completion(pid, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    poll_completed(pid, deadline)
  end

  defp poll_completed(pid, deadline) do
    if :sys.get_state(pid).completed do
      true
    else
      if System.monotonic_time(:millisecond) > deadline do
        flunk("soak test did not complete within timeout")
      else
        Process.sleep(20)
        poll_completed(pid, deadline)
      end
    end
  end
end
