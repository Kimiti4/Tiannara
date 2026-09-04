# Read-only JARVIS capability audit. Run with (PowerShell):
#   mix run --no-start scripts/audit_capabilities.exs 2>&1 | Out-File -FilePath capability_audit.log -Encoding utf8
# then inspect with Select-String.
#
# --no-start is mandatory: it prevents booting a second instance that would
# conflict with the running soak. This script reads disk artifacts ONLY.

alias Tiannara.Omega.CapabilityAudit
alias Tiannara.Lineage.Store

reports =
  Path.wildcard("docs/operations/report_*.json")
  |> Enum.sort()
  |> Enum.flat_map(fn path ->
    with {:ok, body} <- File.read(path),
         {:ok, map} when is_map(map) <- Jason.decode(body) do
      [map]
    else
      _ -> []
    end
  end)

lineage =
  ["priv/lineage/soak_lineage.log", "data/lineage.log", "priv/lineage.log"]
  |> Enum.find_value([], fn path ->
    case Store.load_all(path) do
      {:ok, entries} when entries != [] -> entries
      _ -> nil
    end
  end)

cpl_checkpoints = Path.wildcard("data/cpl/*") |> length()

audit =
  CapabilityAudit.audit(%{
    operations_reports: reports,
    lineage_entries: lineage,
    cpl_checkpoints: cpl_checkpoints
  })

IO.puts(CapabilityAudit.render(audit))