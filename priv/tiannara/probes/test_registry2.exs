{:ok, _} = Application.ensure_all_started(:tiannara)
Process.sleep(1000)
IO.puts("Registry whereis: #{inspect(Process.whereis(Tiannara.CEL.Services.CapabilityRegistry))}")
IO.puts("Registry via ServiceRegistry: #{inspect(Tiannara.CEL.Kernel.ServiceRegistry.get(:capability_graph))}")
# Try to find via all providers if registry is running
try do
  IO.puts("All providers: #{inspect(Tiannara.CEL.Services.CapabilityRegistry.all_providers())}")
catch kind, reason -> IO.puts("Error: #{inspect({kind, reason})}")
end
# Try alternative name
IO.puts("Trying via :capability_graph id")
# The service id is :capability_graph, but the module is CapabilityRegistry
# The GenServer is registered as the module name, not the id
# Let's try to find the pid via ServiceRegistry
case Tiannara.CEL.Kernel.ServiceRegistry.get(:capability_graph) do
  {:ok, spec} -> IO.puts("Spec module: #{inspect(spec.module)}")
  other -> IO.puts("Get failed: #{inspect(other)}")
end
