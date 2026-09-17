# The app is started by `mix run` before this script loads, so no
# Mix.Task.run(:app.start) here — under `mix run` that call errors with
# ":app.start/0 is undefined (module :app is not available)".

# Disk circuit-breaker: bound the soak's own on-disk footprint so a storage
# overrun aborts gracefully (with a report) instead of dying of ENOSPC. The
# ceiling sits above the modeled TTL-30 projection and below free disk, so a
# trip is always a real tail-risk, never a flake. The launch loop below
# (scripts/soak_test.exs) is a foreground Process.sleep loop with no pid to
# signal, so an abort halts the node itself after the report is written.
soak_dets_dir =
  case Application.get_env(:tiannara, :dets_base_path) do
    nil -> Path.join([Tiannara.Storage.Paths.base(), "soak", "dets"])
    base -> Path.join([base, "dets", "soak"])
  end

Tiannara.Storage.SoakFootprintGuard.start_link(
  dir: soak_dets_dir,
  ceiling_bytes: 14 * 1024 * 1024 * 1024,
  on_breach: fn ->
    # Report already written inside the guard; halt so the run stops with
    # state intact rather than bleeding into ENOSPC.
    System.halt(1)
  end
)

defmodule SoakTest do
  @default_duration_hours 72
  @interval_seconds 60
  @failure_injection_hour 24
  @load_spike_hour 48

  def run(opts \\ []) do
    duration_hours = Keyword.get(opts, :duration_hours, @default_duration_hours)
    duration_ms = duration_hours * 60 * 60 * 1000

    IO.puts("=" |> String.duplicate(60))
    IO.puts("Soak Test — #{duration_hours}-hour Autonomous Operation")
    IO.puts("=" |> String.duplicate(60))
    IO.puts("Start time: #{DateTime.utc_now() |> DateTime.to_string()}")
    IO.puts("Failure injection at: T+#{@failure_injection_hour}h")
    IO.puts("Load spike at: T+#{@load_spike_hour}h")
    IO.puts("=" |> String.duplicate(60))
    IO.puts("")

    start_time = DateTime.utc_now()
    results = run_loop(start_time, duration_ms, %{
      cycles: 0, passes: 0, failures: 0, errors: [],
      phase6_results: [], phase7_results: [],
      phase8_results: [], phase9_results: [],
      phase10_results: [], feedback_results: [],
      failure_injected: false, load_spike_done: false
    })

    elapsed_hours = DateTime.diff(DateTime.utc_now(), start_time) / 3600.0

    IO.puts("")
    IO.puts("=" |> String.duplicate(60))
    IO.puts("Soak Test Complete")
    IO.puts("=" |> String.duplicate(60))
    IO.puts("Duration: #{Float.round(elapsed_hours, 2)} hours")
    IO.puts("Cycles completed: #{results.cycles}")
    IO.puts("Passes: #{results.passes}")
    IO.puts("Failures: #{results.failures}")
    IO.puts("Total errors: #{length(results.errors)}")
    IO.puts("")

    if results.failures == 0 and length(results.errors) == 0 do
      IO.puts("SOAK TEST: ALL CHECKS PASSED — system is stable")
    else
      IO.puts("SOAK TEST: #{results.failures + length(results.errors)} ISSUES DETECTED")
      if length(results.errors) > 0 do
        IO.puts("Last 10 errors:")
        results.errors |> Enum.take(-10) |> Enum.each(&IO.puts("  #{inspect(&1)}"))
      end
    end

    results
  end

  defp run_loop(start_time, duration_ms, state) when duration_ms <= 0, do: state

  defp run_loop(start_time, duration_ms, state) do
    elapsed_ms = DateTime.diff(DateTime.utc_now(), start_time, :millisecond)
    elapsed_hours = elapsed_ms / 3600000.0

    state = maybe_inject_failure(elapsed_hours, state)
    state = maybe_run_load_spike(elapsed_hours, state)

    phase6_result = check_phase("Phase 6 — Research Civilization", fn ->
      check_process(Tiannara.ASC.Core.Supervisor) &&
        check_process(Tiannara.ASC.Core.Registry)
    end)
    state = record_phase_result(state, :phase6, phase6_result)

    phase7_result = check_phase("Phase 7 — Meta-Science Engine", fn ->
      check_process(Tiannara.ASC.MetaScienceEngine)
    end)
    state = record_phase_result(state, :phase7, phase7_result)

    phase8_result = check_phase("Phase 8 — Autonomous Engineering", fn ->
      check_process(Tiannara.ASC.Engineering.Supervisor) &&
        check_process(Tiannara.ASC.Engineering.Director)
    end)
    state = record_phase_result(state, :phase8, phase8_result)

    phase9_result = check_phase("Phase 9 — Reality Engineering", fn ->
      check_process(Tiannara.ASC.Reality.Director) &&
        check_process(Tiannara.ASC.Reality.RiskAssessmentEngine) &&
        check_process(Tiannara.ASC.Reality.SafetyVerificationEngine) &&
        check_process(Tiannara.ASC.Reality.ComplianceEngine) &&
        check_process(Tiannara.ASC.Reality.RollbackEngine)
    end)
    state = record_phase_result(state, :phase9, phase9_result)

    phase10_result = check_phase("Phase 10 — Civilizational Intelligence", fn ->
      check_process(Tiannara.ASC.Civilization.Director) &&
        check_process(Tiannara.ASC.Civilization.WorldModel) &&
        check_process(Tiannara.ASC.Civilization.Planner) &&
        check_process(Tiannara.ASC.Civilization.DecisionEngine)
    end)
    state = record_phase_result(state, :phase10, phase10_result)

    feedback_result = check_phase("Feedback Loop (Phase 5)", fn ->
      check_process(Tiannara.Operations.CampaignScheduler) &&
        check_process(Tiannara.Operations.CampaignIntegration) &&
        check_process(Tiannara.Operations.FeedbackLoop)
    end)
    state = record_phase_result(state, :feedback, feedback_result)

    runtime_result = check_phase("CEL Executive Kernel", fn ->
      check_process(Tiannara.CEL.Kernel)
    end)
    state = record_phase_result(state, :cel, runtime_result)

    all_pass = phase6_result && phase7_result && phase8_result &&
               phase9_result && phase10_result && feedback_result && runtime_result

    state = %{state |
      cycles: state.cycles + 1,
      passes: state.passes + if(all_pass, do: 1, else: 0),
      failures: state.failures + if(all_pass, do: 0, else: 1)
    }

    if rem(state.cycles, 10) == 0 do
      IO.puts("[T+#{Float.round(elapsed_hours, 1)}h] Cycle #{state.cycles}: " <>
        "Pass=#{all_pass} " <>
        "Phase6=#{phase6_result} Phase7=#{phase7_result} " <>
        "Phase8=#{phase8_result} Phase9=#{phase9_result} " <>
        "Phase10=#{phase10_result} Feedback=#{feedback_result}")
    end

    remaining_ms = duration_ms - elapsed_ms
    sleep_ms = min(@interval_seconds * 1000, max(0, remaining_ms))
    if sleep_ms > 0, do: Process.sleep(sleep_ms)

    run_loop(start_time, duration_ms, state)
  end

  defp maybe_inject_failure(elapsed_hours, state) do
    if elapsed_hours >= @failure_injection_hour and not state.failure_injected do
      IO.puts("[FAILURE INJECTION] Simulating temporary service failure at T+#{@failure_injection_hour}h")

      try do
        pid = Process.whereis(Tiannara.ASC.Reality.IncidentResponseEngine)
        if pid, do: Process.exit(pid, :kill)
        IO.puts("  Killed IncidentResponseEngine — verifying automatic restart...")
        Process.sleep(5000)
        case Process.whereis(Tiannara.ASC.Reality.IncidentResponseEngine) do
          nil -> IO.puts("  WARNING: IncidentResponseEngine did NOT restart")
          _ -> IO.puts("  OK: IncidentResponseEngine restarted automatically")
        end
      rescue
        e -> IO.puts("  Failure injection error: #{inspect(e)}")
      end

      %{state | failure_injected: true}
    else
      state
    end
  end

  defp maybe_run_load_spike(elapsed_hours, state) do
    if elapsed_hours >= @load_spike_hour and not state.load_spike_done do
      IO.puts("[LOAD SPIKE] Simulating high load at T+#{@load_spike_hour}h")

      case Tiannara.Storage.SoakFootprintGuard.footprint() do
        {{:ok, bytes}, ceiling} when bytes > ceiling ->
          IO.puts("[LOAD SPIKE] footprint #{bytes}B over ceiling #{ceiling}B — skipping load spike")
          %{state | load_spike_done: true}

        _ ->
          artifacts =
            1..50
            |> Enum.map(fn i ->
              {%{name: "load_test_#{i}", version: "1.0", payload: %{data: "test_#{i}"}},
               :digital, %{staged: true}}
            end)

          results =
            artifacts
            |> Task.async_stream(
              fn {artifact, target, params} ->
                try do
                  Tiannara.ASC.Reality.Director.safe_deploy(artifact, target, params, 60_000)
                rescue
                  e -> {:error, {:deploy_raised, e}}
                end
              end,
              max_concurrency: 50,
              timeout: 60_000,
              on_timeout: :kill_task
            )
            |> Enum.map(fn
              {:ok, r} -> r
              {:exit, reason} -> {:error, {:stream_failed, reason}}
            end)

          ok_count = Enum.count(results, &match?({:ok, _}, &1))
          fail_count = Enum.count(results, &match?({:error, _}, &1))
          timeout_count = Enum.count(results, &match?(:exit, &1))
          IO.puts("  Load spike FINAL: #{ok_count}/50 ok / #{fail_count} failed / #{timeout_count} exited (logged, not abortive)")

          failures = Enum.with_index(results) |> Enum.filter(fn {{:error, _}, _} -> true; _ -> false end)
          Enum.each(failures, fn {{:error, detail}, idx} ->
            ingest_failure(idx, detail)
          end)

          %{state | load_spike_done: true}
      end
    else
      state
    end
  end

  defp check_phase(label, fun) do
    try do
      fun.()
    rescue
      e ->
        IO.puts("  [#{label}] check raised: #{inspect(e)}")
        false
    end
  end

  defp record_phase_result(state, phase, result) do
    key = :"#{phase}_results"
    history = Map.get(state, key, [])
    trimmed = (history ++ [result]) |> Enum.take(-100)
    Map.put(state, key, trimmed)
  end

  defp check_process(mod) do
    case Process.whereis(mod) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  rescue
    _ -> false
  end

  defp ingest_failure(task_idx, detail) do
    try do
      exception = case detail do
        {:deploy_failed, {:error, reason, _pipeline}} -> reason
        {:deploy_failed, reason} -> reason
        {:deploy_timeout, _} -> :timeout
        {:deploy_raised, e} -> e
        _ -> detail
      end

      failure = %{
        exception: exception,
        stacktrace_ref: "load_spike_task_#{task_idx}",
        task_id: task_idx,
        phase: :t_plus_48h_load_spike,
        timestamp: DateTime.utc_now()
      }

      case Process.whereis(Tiannara.Engineering.ProposalGenerator) do
        nil ->
          IO.puts("  [L4] ProposalGenerator not available — logging failure #{task_idx}")
        pid ->
          Tiannara.Engineering.ProposalGenerator.ingest_failure(failure)
          IO.puts("  [L4] Failure #{task_idx} ingested for L4 proposal generation")
      end
    rescue
      e -> IO.puts("  [L4] Failed to ingest failure #{task_idx}: #{inspect(e)}")
    end
  end
end

duration_hours = case System.argv() do
  [h] -> String.to_integer(h)
  _ -> 72
end

SoakTest.run(duration_hours: duration_hours)
