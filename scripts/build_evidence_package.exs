# Evidence-package builder: idempotent skeleton + manifest for the Omega.R
# report. Read-only against the soak; writes ONLY under evidence_package/.
# --no-start mandatory.
#
# Usage:
#   mix run --no-start scripts/build_evidence_package.exs <soak_log>
#
# Findings escalated as first-class records (F1-F4); F2 closer recorded as
# :pending (soak ran the OLD image). erl_crash.dump is copied into
# evidence_package/oom/ as immutable evidence.

Application.ensure_all_started(:jason)

alias Tiannara.Omega.SoakEvidence

[log_path | _] = System.argv()

if is_nil(log_path), do: raise("usage: mix run --no-start scripts/build_evidence_package.exs <soak_log>")
if not File.exists?(log_path), do: raise("soak log not found: #{log_path}")

package = "evidence_package"
root = Path.join(package, ".")
subdirs = [
  "findings", "extractions", "audits_capability", "injections", "oom"
]

Enum.each(subdirs, &File.mkdir_p!(Path.join(package, &1)))

crash_dump_src = "erl_crash.dump"
crash_dump_dst = Path.join([package, "oom", "erl_crash.dump"])

dump_copied =
  if File.exists?(crash_dump_src) do
    if not File.exists?(crash_dump_dst) or File.stat!(crash_dump_dst).size != File.stat!(crash_dump_src).size do
      File.cp!(crash_dump_src, crash_dump_dst)
    end

    true
  else
    false
  end

dump_size_mb =
  if File.exists?(crash_dump_dst) do
    Float.round(File.stat!(crash_dump_dst).size / 1_048_576, 1)
  else
    nil
  end

now = DateTime.utc_now() |> DateTime.to_iso8601()

findings = [
  %{
    "id" => "F1",
    "title" => "unchanged? guard does not prevent repeated identical mints",
    "severity" => "evidence_problem",
    "status" => "open",
    "evidence" => [
      "48x identical mint of \"Repair Simplicity Improves Transferability\" (confidence 0.189, support 323)",
      "13 duplicate-mint groups total",
      "124 pipeline-bypass entries",
      "per-5min window bounded at 3 mints (no runaway loop; monoculture instead)"
    ],
    "category" => "P2 synthesis monoculture",
    "action" => "post-Omega.R: strengthen unchanged? guard; do not touch running evidence"
  },
  %{
    "id" => "F2",
    "title" => "WorkflowEngine put_in crash on missing retry_counts",
    "severity" => "defect_fixed",
    "status" => "fixed_with_regression_test",
    "soak_runtime_patched" => false,
    "post_fix_soak_evidence" => :pending,
    "evidence" => [
      "363x identical ArgumentError: could not put/update key \"step_execute\" on a nil value in soak log",
      "fix: defensive retry_counts Map.put at workflow_engine.ex:614",
      "regression test: test/tiannara/cel/services/workflow_engine_retry_test.exs (passing)",
      "soak BEAM ran the OLD image -> crash loop persisted until OOM death; see F4"
    ],
    "action" => "F2 closer: run check_f2_closed.exs --since <post-fix-soak-start>; PASS only when signature count is 0 on a new image"
  },
  %{
    "id" => "F3",
    "title" => "soak evidence trail is log-only",
    "severity" => "observability_gap",
    "status" => "open",
    "evidence" => [
      "no hourly reports on disk during soak (docs/operations/report_*.json are stale, pre-soak)",
      "no data/cpl/ checkpoints on disk",
      "no lineage files on disk from the soak",
      "capability audit therefore reports :not_measured for disk-derived capabilities"
    ],
    "action" => "post-Omega.R: persist hourly reports/lineage/CPL from the soak context"
  },
  %{
    "id" => "F4",
    "title" => "soak terminated early by BEAM heap exhaustion (OOM)",
    "severity" => "experiment_termination",
    "status" => "recorded",
    "evidence" => [
      "ran 38.3h of planned 72h; died 2026-08-15T23:03:13Z",
      "eheap_alloc: Cannot allocate 600904 bytes (type \"heap\")",
      "erl_crash.dump written to repo root (62.7MB) - copied into evidence_package/oom/",
      "final PhaseOmega runtime verification: 1/16 healthy (subsystems dying under memory pressure)",
      "last crash stack: DiscoveryScheduler.run_cycle -> Events.emit -> GenServer.call (timeout)",
      "plausible leak contributor: F2 WorkflowEngine crash loop accumulating supervisor restarts"
    ],
    "action" => "parallel track: analyze_oom_dump.exs over evidence_package/oom/erl_crash.dump; root-cause before any future re-soak"
  }
]

manifest = %{
  "generated_at" => now,
  "soak" => %{
    "log_path" => log_path,
    "planned_hours" => 72,
    "ran_hours" => 38.3,
    "terminated" => "beam_oom",
    "died_at_utc" => "2026-08-15T23:03:13Z",
    "log_frozen" => true,
    "log_lines" => File.stream!(log_path) |> Enum.count()
  },
  "findings" => findings,
  "artifacts" => %{
    "crash_dump" => %{"in_package" => dump_copied, "path" => crash_dump_dst, "size_mb" => dump_size_mb},
    "t0_extraction" => "evidence_package/extractions/t0.json",
    "t24_extraction" => "evidence_package/extractions/t24.json (written by t24_audit.exs)",
    "injections" => "scripts/inject_failures.exs (3/3 PASS, isolated scratch node)"
  }
}

manifest_path = Path.join(package, "manifest.json")
File.write!(manifest_path, Jason.encode!(manifest, pretty: true))

IO.puts("""
==== EVIDENCE PACKAGE BUILT ====
root:      #{root}
findings:  F1 (open) F2 (fixed, closer pending) F3 (open) F4 (recorded)
crash dump copied: #{dump_copied} (#{dump_size_mb}MB)
manifest:  #{manifest_path}
=================================
""")