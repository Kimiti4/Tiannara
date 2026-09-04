# Read-only soak evidence extraction: frozen 38.3h soak log -> structured JSON.
# --no-start mandatory; read-only; never attaches to anything.
#
# The log lines carry only HH:MM:SS.mmm, so this script ENRICHES each line
# with a virtual ISO-8601 prefix (YYYY-MM-DDTHH:MM:SS|) computed from the
# soak start (SOAK_START_UTC, default 2026-08-14T08:43:25Z) with day rollover
# whenever the hour regresses. Untimestamped lines (flush-left "** (ArgumentError)"
# crash lines, stack traces) inherit the last seen timestamp so crash hourly
# buckets work.
#
# Usage:
#   mix run --no-start scripts/extract_soak_evidence.exs <soak_log> <out.json> [--reference ref.json]
#
# --reference: an independent audit JSON (e.g. audit_soak_signals output) whose
#              keys may be atoms or strings; cross_check is differential, no
#              hard-coded ground truth.

Application.ensure_all_started(:jason)

alias Tiannara.Omega.SoakEvidence

log_path = System.argv() |> Enum.at(0)
out_path = System.argv() |> Enum.at(1)

args = System.argv()

reference_path =
  case Enum.find_index(args, &(&1 == "--reference")) do
    nil -> nil
    i -> Enum.at(args, i + 1)
  end

if is_nil(log_path) or is_nil(out_path) do
  raise "usage: mix run --no-start scripts/extract_soak_evidence.exs <soak_log> <out.json> [--reference ref.json]"
end

if not File.exists?(log_path), do: raise("soak log not found: #{log_path}")

soak_start_utc = System.get_env("SOAK_START_UTC") || "2026-08-14T08:43:25Z"
start_day = soak_start_utc |> String.slice(8, 2) |> String.to_integer()

defmodule Enrich do
  def run(lines, start_day) do
    {enriched, _st} =
      Enum.map_reduce(lines, %{day: start_day, last_h: nil, last_iso: nil}, fn line, st ->
        case Regex.run(~r/^(\d{2}):(\d{2}):(\d{2})\.?\d*/, line) do
          [_, h, m, s] ->
            day = if st.last_h != nil and String.to_integer(h) < st.last_h, do: st.day + 1, else: st.day
            iso = "2026-08-#{pad(day)}T#{h}:#{m}:#{s}"
            {"#{iso}|#{line}", %{day: day, last_h: String.to_integer(h), last_iso: iso}}

          nil ->
            if st.last_iso, do: {"#{st.last_iso}|#{line}", st}, else: {line, st}
        end
      end)

    enriched
  end

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(2, "0")
end

raw_lines = File.stream!(log_path) |> Stream.map(&String.trim/1) |> Enum.to_list()
enriched = Enrich.run(raw_lines, start_day)

evidence = SoakEvidence.extract(enriched)
trajectory = SoakEvidence.trajectory(evidence)
diversity = SoakEvidence.mint_diversity(evidence)

reference =
  if reference_path do
    if not File.exists?(reference_path), do: raise("reference not found: #{reference_path}")
    Jason.decode!(File.read!(reference_path))
  end

cross =
  case reference do
    nil -> nil
    ref -> SoakEvidence.cross_check(evidence, ref, 0)
  end

hours = Enum.map(trajectory, & &1.hour)

payload = %{
  "soak_start_utc" => soak_start_utc,
  "extractor_version" => "soak_evidence.v1",
  "extracted_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
  "log_path" => log_path,
  "log_lines" => evidence.total_lines,
  "totals" => %{
    "agency_loops" => evidence.agency_loops,
    "loop_monotonic" => evidence.loop_monotonic,
    "recoveries" => evidence.recoveries,
    "restraints" => evidence.restraints,
    "improvement_cycles" => evidence.improvement_cycles,
    "self_diagnoses" => evidence.self_diagnoses,
    "workflow_crashes" => evidence.workflow_crashes,
    "mints" => evidence.mints,
    "pipeline_bypasses" => evidence.pipeline_bypasses,
    "rejects" => evidence.rejects,
    "first_mint_at" => evidence.first_mint_at,
    "unmatched_lines" => evidence.unmatched_lines,
    "total_lines" => evidence.total_lines
  },
  "mint_diversity" => %{
    "unique_mints" => diversity.unique_mints,
    "unique_ratio" => Float.round(diversity.unique_ratio, 4),
    "duplicate_mint_rate" => Float.round(diversity.duplicate_mint_rate, 4),
    "duplicate_mint_groups" =>
      Enum.map(Enum.take(evidence.duplicate_mint_groups, 10), fn {sig, n} ->
        %{"signature" => sig, "count" => n}
      end),
    "top_crash_signatures" =>
      Enum.map(
        evidence.workflow_crash_signatures
        |> Enum.sort_by(fn {_s, n} -> -n end)
        |> Enum.take(5),
        fn {sig, n} -> %{"signature" => String.slice(sig, 0, 120), "count" => n} end
      )
  },
  "trajectory_hours" => hours,
  "trajectory" =>
    Enum.map(trajectory, fn h ->
      %{"hour" => h.hour, "loops_per_hour" => h.loops_per_hour,
        "recoveries_per_hour" => h.recoveries_per_hour, "crashes_per_hour" => h.crashes_per_hour,
        "mints_per_hour" => h.mints_per_hour, "diagnoses_per_hour" => h.diagnoses_per_hour,
        "improvements_per_hour" => h.improvements_per_hour, "restraints_per_hour" => h.restraints_per_hour}
    end),
  "cross_check" =>
    case cross do
      nil -> %{"status" => "no_reference"}
      %{status: s, checks: checks} ->
        %{"status" => to_string(s),
          "checks" =>
            Enum.map(checks, fn {field, c} ->
              %{"field" => to_string(field), "extracted" => c.extracted,
                "reference" => c.reference, "delta" => c.delta, "match" => c.match}
            end)}
    end
}

File.mkdir_p!(Path.dirname(out_path))
File.write!(out_path, Jason.encode!(payload, pretty: true))

IO.puts(SoakEvidence.render(evidence))

IO.puts("""
==== TRAJECTORY (per-hour rates) ====
#{Enum.map_join(trajectory, "\n", fn h ->
  "  #{h.hour}  loops=#{h.loops_per_hour} recover=#{h.recoveries_per_hour} crash=#{h.crashes_per_hour} mint=#{h.mints_per_hour} diag=#{h.diagnoses_per_hour} improve=#{h.improvements_per_hour} restrain=#{h.restraints_per_hour}"
end)}
=====================================
""")

case cross do
  nil ->
    IO.puts("cross_check: no reference supplied")

  %{status: s, checks: checks} ->
    IO.puts("cross_check status: #{s}")
    IO.puts("  reference: #{reference_path}")

    Enum.each(checks, fn {field, c} ->
      IO.puts("  #{field}: extracted=#{c.extracted} reference=#{c.reference} delta=#{c.delta} match=#{c.match}")
    end)
end

IO.puts("wrote: #{out_path}")