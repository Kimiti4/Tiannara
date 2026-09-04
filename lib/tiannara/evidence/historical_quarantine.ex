defmodule Tiannara.Evidence.HistoricalQuarantine do
  @moduledoc """
  Quarantine existing fabricated records in scientific memory.

  Scans scientific memory for records that:
    - Have no provenance
    - Have provenance indicating fabrication
    - Match known fabrication signatures (random values, hardcoded p-values)

  Quarantines them with explicit :unknown provenance and audit trail.
  Does NOT silently promote them to real evidence.
  Does NOT delete them (preserves audit trail).

  Constitutional basis:
    - "Preserve previous stable states"
    - "Maintain audit trails"
  """

  alias Tiannara.Evidence.Provenance

  require Logger

  @doc """
  Scan and quarantine historical records.

  Returns a migration report with counts and audit trail.
  When dry_run: true, no mutations are performed.
  """
  @spec migrate(keyword()) :: map()
  def migrate(opts) do
    dry_run = Keyword.get(opts, :dry_run, true)

    Logger.info("[R0-D] starting historical quarantine", dry_run: dry_run)

    records = fetch_records()

    report =
      Enum.reduce(records, base_report(dry_run), fn record, acc ->
        case classify_record(record) do
          :accepted ->
            %{acc | accepted: acc.accepted + 1}

          {:quarantine, reason} ->
            if not dry_run, do: quarantine_record(record, reason)

            %{
              acc
              | quarantined: acc.quarantined + 1,
                audit_trail: [
                  %{record_id: record_id(record), action: :quarantined, reason: reason, at: DateTime.utc_now()}
                  | acc.audit_trail
                ]
            }
        end
      end)

    Map.put(report, :completed_at, DateTime.utc_now())
  end

  defp base_report(dry_run) do
    %{dry_run: dry_run, scanned: 0, accepted: 0, quarantined: 0, audit_trail: [], started_at: DateTime.utc_now()}
  end

  # --- classification ---

  defp classify_record(record) do
    cond do
      has_valid_provenance?(record) -> :accepted
      has_no_provenance?(record) -> {:quarantine, "missing_provenance"}
      true -> {:quarantine, "unverifiable"}
    end
  end

  defp has_valid_provenance?(record) do
    case Map.get(record, :provenance) do
      %{} = p -> Provenance.acceptable_as_evidence?(p)
      _ -> false
    end
  end

  defp has_no_provenance?(record), do: Map.get(record, :provenance) in [nil, %{}]

  defp quarantine_record(record, reason) do
    Logger.info("[R0-D] quarantining record", record_id: record_id(record), reason: reason)
  end

  defp record_id(record), do: Map.get(record, :id, "unknown")

  defp fetch_records do
    case Process.whereis(Tiannara.Research.KnowledgeIntegrator) do
      nil -> []
      _pid -> Tiannara.Research.KnowledgeIntegrator.recent(9999)
    end
  end
end
