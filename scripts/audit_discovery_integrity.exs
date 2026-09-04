# Read-only audit of discovery-evidence integrity during the 72h soak.
#
# SAFETY CONTRACT:
#   * NEVER boots the app (run via `mix run --no-start`).
#   * NEVER writes to the soak's world (data/asc_archive, data/soak, ...).
#   * Reads only the soak log and the laws.ndjson archive.
#
# Checks (each produces a count; the verdict is derived, not asserted):
#   direct_registry_mint         - MINTED lines whose statement never appears
#                                  in the archive (mint that bypassed the
#                                  registry persist path).
#   pipeline_bypass              - NEW archive entries (discovered during the
#                                  soak window) that were never MINTED in the
#                                  log (written by some other path).
#   duplicate_mint_without_change- MINTED lines repeating an identical
#                                  (statement, confidence, support) signature;
#                                  the unchanged? guard should have skipped them.
#   rejected                     - REJECTED BY FALSIFICATION CHECK lines.
#   minted                       - total MINTED lines.
#
# Boundedness: per-window mint counts over 5-minute windows must stay finite
# and roughly constant; a burst would indicate an unbounded mint loop.

log_path = System.get_env("SOAK_LOG") || "C:/Users/user/AppData/Local/Temp/opencode/soak72.log"
archive_path = System.get_env("LAWS_NDJSON") || "data/asc_archive/laws.ndjson"
soak_start_utc = System.get_env("SOAK_START_UTC") || "2026-08-14T08:43:25Z"
output_path = System.get_env("AUDIT_OUTPUT")

if not File.exists?(log_path), do: raise("soak log not found: #{log_path}")
if not File.exists?(archive_path), do: raise("laws.ndjson not found: #{archive_path}")

defmodule IntegrityAudit do
  def run(log_path, archive_path, soak_start_utc) do
    mints = parse_mints(log_path)
    rejects = parse_rejects(log_path)
    archive = parse_archive(archive_path)
    soak_start = parse_utc(soak_start_utc)

    archive_statements = MapSet.new(Enum.map(archive, & &1.statement))
    mint_statements = MapSet.new(Enum.map(mints, & &1.statement))

    new_archive_entries =
      Enum.filter(archive, fn law ->
        discovered_at = parse_utc(law.discovered_at || "")
        discovered_at >= soak_start
      end)

    new_archive_statements = MapSet.new(Enum.map(new_archive_entries, & &1.statement))

    direct_registry_mint =
      Enum.filter(mints, fn m -> not MapSet.member?(archive_statements, m.statement) end)

    pipeline_bypass =
      Enum.filter(new_archive_entries, fn law ->
        not MapSet.member?(mint_statements, law.statement)
      end)

    duplicate_mint_without_change =
      mints
      |> Enum.group_by(fn m -> {m.statement, m.confidence, m.support} end)
      |> Enum.filter(fn {_sig, list} -> length(list) > 1 end)
      |> Enum.map(fn {sig, list} -> {sig, length(list)} end)

    # Boundedness: mint counts per 5-minute window.
    windows =
      mints
      |> Enum.group_by(fn m -> trunc(m.unix / 300) end)
      |> Enum.map(fn {window, list} ->
        {DateTime.from_unix!(window * 300, :second), length(list)}
      end)
      |> Enum.sort_by(&elem(&1, 0))

    %{
      minted: length(mints),
      rejected: length(rejects),
      direct_registry_mint: length(direct_registry_mint),
      pipeline_bypass: length(pipeline_bypass),
      duplicate_mint_without_change: length(duplicate_mint_without_change),
      distinct_statements_minted: MapSet.size(mint_statements),
      archive_entries: length(archive),
      new_archive_entries_during_soak: length(new_archive_entries),
      first_mint_at: first_at(mints),
      last_mint_at: last_at(mints),
      windows: windows,
      direct_mint_examples: Enum.take(direct_registry_mint, 5) |> Enum.map(& &1.statement),
      bypass_examples: Enum.take(pipeline_bypass, 5) |> Enum.map(& &1.statement),
      duplicate_examples: Enum.take(duplicate_mint_without_change, 5)
    }
  end

  defp parse_mints(log_path) do
    log_path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.map(fn line ->
      case Regex.run(~r/^(\S+) \[info\]   📜 MINTED: "(.*)" \(Confidence: ([\d.]+), Support: (\d+)\)/, line) do
        [_, at, statement, confidence, support] ->
          %{
            at: at,
            unix: parse_log_time(at),
            statement: statement,
            confidence: String.to_float(confidence),
            support: String.to_integer(support)
          }

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_rejects(log_path) do
    log_path
    |> File.stream!()
    |> Stream.filter(&String.contains?(&1, "REJECTED BY FALSIFICATION CHECK"))
    |> Enum.to_list()
  end

  defp parse_archive(path) do
    path
    |> File.stream!()
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == ""))
    |> Stream.flat_map(fn line ->
      case Jason.decode(line, keys: :atoms) do
        {:ok, law} -> [law]
        _ -> []
      end
    end)
    |> Enum.group_by(& &1.id)
    |> Enum.map(fn {_id, lines} -> List.last(lines) end)
  end

  defp parse_utc(nil), do: ~U[1970-01-01 00:00:00Z]
  defp parse_utc(""), do: ~U[1970-01-01 00:00:00Z]

  defp parse_utc(iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> dt
      _ -> ~U[1970-01-01 00:00:00Z]
    end
  end

  defp first_at([]), do: ""
  defp first_at([m | _]), do: m.at

  defp last_at([]), do: ""
  defp last_at(list), do: List.last(list).at

  defp parse_log_time("HH:MM:SS" <> _), do: 0

  defp parse_log_time(at) do
    case Regex.run(~r/^(\d{2}):(\d{2}):(\d{2})/, at) do
      [_, h, m, s] ->
        # Log timestamps are UTC (soak started 2026-08-14T08:43:25Z; first mints
        # appeared ~23:43Z = T+15h). Lines with hour < 08:43 must be the next
        # calendar day (midnight rollover across the 72h window).
        {hour, minute, sec} = {String.to_integer(h), String.to_integer(m), String.to_integer(s)}
        day = if hour < 8, do: 15, else: 14

        DateTime.to_unix(%DateTime{
          year: 2026,
          month: 8,
          day: day,
          hour: hour,
          minute: minute,
          second: sec,
          time_zone: "Etc/UTC",
          zone_abbr: "UTC",
          utc_offset: 0,
          std_offset: 0
        })

      _ ->
        0
    end
  end
end

audit = IntegrityAudit.run(log_path, archive_path, soak_start_utc)

report =
  """
  DISCOVERY EVIDENCE INTEGRITY AUDIT
  log:        #{log_path}
  archive:    #{archive_path}
  soak start: #{soak_start_utc}

  mints (log):                      #{audit.minted}
  distinct statements minted:       #{audit.distinct_statements_minted}
  rejected by falsification:        #{audit.rejected}
  archive entries (deduped):        #{audit.archive_entries}
  new archive entries during soak:  #{audit.new_archive_entries_during_soak}
  first mint at:                    #{audit.first_mint_at}
  last mint at:                     #{audit.last_mint_at}

  TRACEABILITY CHECKS
  direct_registry_mint (minted, never in archive):       #{audit.direct_registry_mint}
  pipeline_bypass (new in archive, never minted):        #{audit.pipeline_bypass}
  duplicate_mint_without_change (same signature twice):  #{audit.duplicate_mint_without_change}

  BOUNDEDNESS (mints per 5-minute window)
  #{Enum.map_join(audit.windows, "\n", fn {dt, n} -> "  #{dt}  #{n}" end)}

  EXAMPLES
  direct mint:   #{inspect(audit.direct_mint_examples)}
  pipeline:      #{inspect(audit.bypass_examples)}
  duplicates:    #{inspect(audit.duplicate_examples)}
  """

IO.puts(report)

if output_path do
  File.write!(output_path, Jason.encode!(audit, pretty: true))
  IO.puts("\nJSON written to: #{output_path}")
end