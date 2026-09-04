# T+24 audit: deterministic capability briefing over the frozen soak evidence.
# --no-start mandatory; read-only.
#
# Usage:
#   mix run --no-start scripts/t24_audit.exs <soak_log> <out.json> [baseline.json]
#
# Produces the five-question briefing (alive? constitutional? learning?
# discovering? increasingly useful?) from: the frozen log extraction,
# YieldMetrics, the read-only CapabilityAudit over disk artifacts, and the
# recorded OOM termination. If a baseline extraction JSON is given, prints a
# differential trajectory comparison (no hard-coded ground truth).

Application.ensure_all_started(:jason)

alias Tiannara.Omega.{SoakEvidence, YieldMetrics, CapabilityAudit, CapabilityBriefing}
alias Tiannara.Lineage.Store

defmodule StringifyHelper do
  def stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), stringify_keys(v)} end)
  end

  def stringify_keys({k, v}), do: %{to_string(k) => stringify_keys(v)}

  def stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  def stringify_keys(other), do: other
end

[log_path, out_path | rest] = System.argv()
baseline_path = List.first(rest)

if is_nil(log_path) or is_nil(out_path) do
  raise "usage: mix run --no-start scripts/t24_audit.exs <soak_log> <out.json> [baseline.json]"
end

if not File.exists?(log_path), do: raise("soak log not found: #{log_path}")

raw_lines = File.stream!(log_path) |> Stream.map(&String.trim/1) |> Enum.to_list()

enrich = fn lines, start_day ->
  {enriched, _st} =
    Enum.map_reduce(lines, %{day: start_day, last_h: nil, last_iso: nil}, fn line, st ->
      case Regex.run(~r/^(\d{2}):(\d{2}):(\d{2})\.?\d*/, line) do
        [_, h, m, s] ->
          day = if st.last_h != nil and String.to_integer(h) < st.last_h, do: st.day + 1, else: st.day
          iso = "2026-08-#{String.pad_leading(Integer.to_string(day), 2, "0")}T#{h}:#{m}:#{s}"
          {"#{iso}|#{line}", %{day: day, last_h: String.to_integer(h), last_iso: iso}}

        nil ->
          if st.last_iso, do: {"#{st.last_iso}|#{line}", st}, else: {line, st}
      end
    end)

  enriched
end

evidence = raw_lines |> enrich.(15) |> SoakEvidence.extract()
metrics = YieldMetrics.compute(evidence)

audit =
  CapabilityAudit.audit(%{
    operations_reports:
      Path.wildcard("docs/operations/report_*.json")
      |> Enum.sort()
      |> Enum.flat_map(fn path ->
        with {:ok, body} <- File.read(path),
             {:ok, map} when is_map(map) <- Jason.decode(body) do
          [map]
        else
          _ -> []
        end
      end),
    lineage_entries:
      ["priv/lineage/soak_lineage.log", "data/lineage.log", "priv/lineage.log"]
      |> Enum.find_value([], fn path ->
        case Store.load_all(path) do
          {:ok, entries} when entries != [] -> entries
          _ -> nil
        end
      end),
    cpl_checkpoints: Path.wildcard("data/cpl/*") |> length()
  })

termination = %{
  terminated: "beam_oom",
  at_utc: "2026-08-15T23:03:34Z",
  ran_hours: 38.3,
  planned_hours: 72,
  crash_dump: "erl_crash.dump (62.7MB, repo root)"
}

briefing = CapabilityBriefing.brief(
  soak_evidence: evidence,
  capability_audit: audit,
  yield_metrics: metrics,
  soak_terminated: termination
)

payload = %{
  "generated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
  "termination" => termination,
  "briefing" =>
    Enum.map(briefing.questions, fn q ->
      %{"question" => q.question, "status" => to_string(q.status),
        "verdict" => q.verdict, "evidence" => StringifyHelper.stringify_keys(q.evidence)}
    end),
  "capability_audit" => audit |> Map.from_struct() |> Map.drop([:synthesis]) |> StringifyHelper.stringify_keys(),
  "yield_metrics" =>
    Enum.map(metrics, fn {name, m} ->
      %{"metric" => to_string(name), "value" => m.value, "proxy" => m.proxy,
        "formula" => m.formula, "measured" => m.measured, "note" => m.note}
    end),
  "totals" => %{
    "agency_loops" => evidence.agency_loops,
    "loop_monotonic" => evidence.loop_monotonic,
    "recoveries" => evidence.recoveries,
    "restraints" => evidence.restraints,
    "improvement_cycles" => evidence.improvement_cycles,
    "self_diagnoses" => evidence.self_diagnoses,
    "workflow_crashes" => evidence.workflow_crashes,
    "mints" => evidence.mints,
    "total_lines" => evidence.total_lines,
    "unmatched_lines" => evidence.unmatched_lines
  }
}

File.mkdir_p!(Path.dirname(out_path))
File.write!(out_path, Jason.encode!(payload, pretty: true))

IO.puts("==== T+24 AUDIT (frozen-log snapshot) ====")
IO.puts(CapabilityBriefing.render(briefing))
IO.puts("==== CAPABILITY AUDIT (disk artifacts) ====")
IO.puts(CapabilityAudit.render(audit))
IO.puts("==== YIELD METRICS (labeled proxies) ====")
IO.puts(YieldMetrics.render(metrics))

if baseline_path do
  if File.exists?(baseline_path) do
    base = Jason.decode!(File.read!(baseline_path))
    base_totals = base["totals"]

    IO.puts("==== DIFFERENTIAL vs BASELINE #{baseline_path} ====")

    for {k, _} <- base_totals, k != "loop_monotonic" do
      cur = Map.get(payload["totals"], k)
      ref = Map.get(base_totals, k)
      IO.puts("  #{k}: baseline=#{ref} now=#{cur} delta=#{if is_number(cur) and is_number(ref), do: cur - ref, else: "n/a"}")
    end
  else
    IO.puts("baseline not found: #{baseline_path} (skipping differential)")
  end
end

IO.puts("wrote: #{out_path}")