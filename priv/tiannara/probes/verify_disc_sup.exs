{:ok, _} = Application.ensure_all_started(:tiannara)
Process.sleep(1000)
IO.puts("Before manual start: disc_sup whereis #{inspect(Process.whereis(Tiannara.Discovery.DiscoverySupervisor))}")
case Tiannara.Discovery.DiscoverySupervisor.start_link([]) do
  {:ok, pid} -> IO.puts("Manual start ok #{inspect(pid)}")
  {:error, {:already_started, pid}} -> IO.puts("Already started #{inspect(pid)}")
  other -> IO.puts("Other #{inspect(other)}")
end
Process.sleep(500)
IO.puts("After: #{inspect(Process.whereis(Tiannara.Discovery.DiscoverySupervisor))}")
children = try do Supervisor.which_children(Tiannara.Discovery.DiscoverySupervisor) catch e -> e end
IO.puts("Children: #{inspect(children)}")
