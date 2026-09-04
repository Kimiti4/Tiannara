# Inspect Observatory snapshots

snapshots = Tiannara.ASC.Observatory.ProjectObservatory.all_snapshots()

IO.puts("\nTotal Snapshots: #{length(snapshots)}\n")

if snapshots != [] do
  first = hd(snapshots)
  IO.inspect(first, label: "First Snapshot", limit: :infinity, pretty: true)
else
  IO.puts("No snapshots found")
end
