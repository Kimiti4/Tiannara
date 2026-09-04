# Read-only soak-signal extraction (log-based JARVIS evidence).
# Reads the LIVE 72h soak log and derives P0/P1/P2 capability signals.
# --no-start mandatory; read-only; never touches the running soak.
#
# Run: mix run --no-start scripts/audit_soak_signals.exs 2>&1 | Out-File soak_signals.log -Encoding utf8

log_path = System.get_env("SOAK_LOG") || "C:/Users/user/AppData/Local/Temp/opencode/soak72.log"

if not File.exists?(log_path), do: raise("soak log not found: #{log_path}")

defmodule SoakSignals do
  def run(log_path) do
    lines =
      log_path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Enum.to_list()

    agency_loops =
      lines
      |> Enum.flat_map(fn line ->
        case Regex.run(~r/\[debug\] \[AgencyLoop\] Loop (\d+) completed/, line) do
          [_, n] -> [String.to_integer(n)]
          _ -> []
        end
      end)

    crash_lines =
      lines
      |> Enum.filter(&(String.contains?(&1, "terminating") or String.contains?(&1, "[error]")))

    crashes_by_module =
      crash_lines
      |> Enum.flat_map(fn line ->
        case Regex.run(~r/\[error\] GenServer ([\w.]+) terminating/, line) do
          [_, mod] -> [mod]
          _ -> []
        end
      end)
      |> Enum.frequencies()

    crash_signatures =
      lines
      |> Enum.flat_map(fn line ->
        case Regex.run(~r/^\*\* \(([\w.]+)\) (.*)/, line) do
          [_, kind, msg] -> [kind <> ": " <> String.slice(msg, 0, 100)]
          _ -> []
        end
      end)
      |> Enum.frequencies()

    recoveries =
      lines
      |> Enum.filter(fn line ->
        String.contains?(line, "recovering") or String.contains?(line, "Recovered") or
          String.contains?(line, "recovered") or String.contains?(line, "resume") or
          String.contains?(line, "Resumed")
      end)
      |> Enum.reject(&String.contains?(&1, "lib/"))

    restraint =
      lines
      |> Enum.filter(fn line ->
        String.contains?(line, "REJECTED BY FALSIFICATION") or
          String.contains?(line, "not authorized") or
          String.contains?(line, "unauthorized") or
          String.contains?(line, "illegal_transition") or
          String.contains?(line, "BLOCKED") or
          String.contains?(line, ":gate_closed") or
          String.contains?(line, "GATE CLOSED")
      end)

    proactive =
      lines
      |> Enum.filter(fn line ->
        String.contains?(line, "improvement cycle") or
          String.contains?(line, "Proposing") or
          String.contains?(line, "proposal approved") or
          String.contains?(line, "suggested")
      end)

    self_diagnosis =
      lines
      |> Enum.filter(fn line ->
        String.contains?(line, "systemic bottleneck") or
          String.contains?(line, "monoculture") or
          String.contains?(line, "stall") or
          String.contains?(line, "bottleneck detected")
      end)

    mints = Enum.count(lines, &String.contains?(&1, "MINTED:"))
    rejects = Enum.count(lines, &String.contains?(&1, "REJECTED BY FALSIFICATION CHECK"))

    monotonic? =
      agency_loops == Enum.sort(agency_loops) and agency_loops == Enum.uniq(agency_loops)

    %{
      agency_loop_count: length(agency_loops),
      agency_loop_first: List.first(agency_loops),
      agency_loop_last: List.last(agency_loops),
      agency_loop_monotonic?: monotonic?,
      crashes_total: length(crash_lines),
      crashes_by_module: crashes_by_module,
      crash_signature_recurrence: crash_signatures,
      recovery_lines: length(recoveries),
      recovery_examples: Enum.take(recoveries, 3),
      restraint_events: length(restraint),
      restraint_examples: Enum.take(restraint, 3),
      proactive_events: length(proactive),
      proactive_examples: Enum.take(proactive, 3),
      self_diagnosis_events: length(self_diagnosis),
      self_diagnosis_examples: Enum.take(self_diagnosis, 3),
      mints: mints,
      falsification_rejects: rejects
    }
  end
end

s = SoakSignals.run(log_path)

IO.puts("""
SOAK SIGNAL EXTRACTION (read-only, from soak log)
log: #{log_path}

P0 continuity: AgencyLoop #{s.agency_loop_count} loops (#{s.agency_loop_first} -> #{s.agency_loop_last}), monotonic=#{s.agency_loop_monotonic?}
P0 recovery:   #{s.recovery_lines} recovery lines; #{s.crashes_total} crash lines
  by module: #{inspect(s.crashes_by_module)}
P0 restraint:  #{s.restraint_events} restraint events; #{s.falsification_rejects} falsification rejects
P1 proactivity:#{s.proactive_events} improvement cycles (e.g. #{hd(s.proactive_examples || ["(none)"])})
P1 self-diag:  #{s.self_diagnosis_events} bottleneck/anomaly lines
P1 learning:   recurrence #{inspect(s.crash_signature_recurrence)}
P2 synthesis:  #{s.mints} MINTED, #{s.falsification_rejects} REJECTED
""")