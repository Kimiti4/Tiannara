{:ok, _} = Application.ensure_all_started(:tiannara)
Process.sleep(1000)
engine_pid = Process.whereis(Tiannara.Discovery.DiscoveryEngine)
IO.puts("Engine pid: #{inspect(engine_pid)}")
if engine_pid do
  # Get parent via Process.info
  info = Process.info(engine_pid, [:links, :dictionary])
  IO.puts("Engine links: #{inspect(info)}")
  # Try to find parent by checking which supervisor has it as child
  candidates = [Tiannara.Application, Tiannara.Discovery.DiscoverySupervisor, Tiannara.CEL.ServiceSupervisor]
  for sup <- candidates do
    children = try do Supervisor.which_children(sup) catch _ -> try do DynamicSupervisor.which_children(sup) catch _ -> [] end end
    has = Enum.any?(children, fn {id, pid, _, _} -> pid == engine_pid or id == Tiannara.Discovery.DiscoveryEngine end)
    IO.puts("Supervisor #{inspect(sup)} has engine: #{has}, children: #{inspect(Enum.map(children, fn {id, _, _, _} -> id end))}")
  end
  # Also check all supervisors via Process.list
  all_sup_pids = Process.list() |> Enum.filter(fn pid ->
    try do
      {:status, _, _, items} = :sys.get_status(pid)
      str = inspect(items)
      String.contains?(str, "Supervisor")
    catch _, _ -> false
    end
  end)
  IO.puts("Found #{length(all_sup_pids)} supervisors")
  for sup_pid <- Enum.take(all_sup_pids, 5) do
    children = try do Supervisor.which_children(sup_pid) catch _, _ -> [] end
    if Enum.any?(children, fn {id, pid, _, _} -> pid == engine_pid end) do
      IO.puts("Found parent supervisor pid #{inspect(sup_pid)}")
    end
  end
else
  IO.puts("Engine not running")
end
IO.puts("DiscoverySupervisor whereis: #{inspect(Process.whereis(Tiannara.Discovery.DiscoverySupervisor))}")
