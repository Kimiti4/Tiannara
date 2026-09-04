# Run with: mix run scripts/verify_asc_gating.exs
#
# Verifies the ASC feature flag is honored by the supervision tree and that
# the autonomous-loop plumbing survives regardless of the flag.
#
# Constitutional Alignment (rules.md):
# - "Modularity / Replaceability" — ASC can be cleanly removed.
# - "Fault tolerance" — disabling ASC must not crash the loop.
# - "Capability must never outpace verification."

defmodule Tiannara.Audit.ASCGating do
  @moduledoc "Verifies ASC feature-flag gating against the live supervision tree."

  @asc_supervisors [
    Tiannara.ASC.Core.Supervisor,
    Tiannara.ASC.MetaScienceEngine,
    Tiannara.ASC.Engineering.Supervisor,
    Tiannara.ASC.Reality.Supervisor,
    Tiannara.ASC.Civilization.Supervisor,
    Tiannara.ASC.Supervisor,
    Tiannara.ToolForge.ToolForgeSupervisor
  ]

  @loop_plumbing [
    Tiannara.Operations.CampaignIntegration,
    Tiannara.Operations.FeedbackLoop,
    Tiannara.Operations.CampaignScheduler,
    Tiannara.Operations.Phase5FeedbackListener,
    Tiannara.Operations.CampaignTelemetry
  ]

  def run do
    # let the supervision tree settle
    Process.sleep(3_000)

    enabled = Tiannara.Application.asc_enabled?()
    IO.puts("═══ ASC FEATURE-FLAG GATING VERIFICATION ═══\n")
    IO.puts(" config :tiannara, :asc, enabled: #{enabled}\n")

    asc_results = check_group(@asc_supervisors, enabled)
    # loop must ALWAYS be up
    loop_results = check_group(@loop_plumbing, true)

    asc_ok = Enum.all?(asc_results, & &1.ok)
    loop_ok = Enum.all?(loop_results, & &1.ok)

    IO.puts("\n── ASC executors (expected running=#{enabled}) ──")
    print_group(asc_results)

    IO.puts("\n── Loop plumbing (expected running=true) ──")
    print_group(loop_results)

    IO.puts("\n── VERDICT ──")

    cond do
      asc_ok and loop_ok ->
        IO.puts(" ✅ GATING CORRECT — flag honored, loop intact")
        System.halt(0)

      not loop_ok ->
        IO.puts(" ❌ LOOP PLUMBING DOWN — the loop must survive regardless of the flag")
        System.halt(1)

      true ->
        IO.puts(" ❌ GATING MISMATCH — ASC supervisors don't match the flag")
        System.halt(1)
    end
  end

  defp check_group(modules, expected_running) do
    Enum.map(modules, fn mod ->
      running = Process.whereis(mod) != nil

      %{
        module: mod,
        running: running,
        expected: expected_running,
        ok: running == expected_running
      }
    end)
  end

  defp print_group(results) do
    Enum.each(results, fn r ->
      mark = if r.ok, do: "✅", else: "❌"
      state = if r.running, do: "running", else: "stopped"
      IO.puts(" #{mark} #{inspect(r.module)} — #{state} (expected #{r.expected})")
    end)
  end
end

Tiannara.Audit.ASCGating.run()
