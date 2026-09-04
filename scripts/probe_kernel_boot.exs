# Probe: after full app boot, print CEL Kernel boot report + liveness of every registered service.
# Run: $env:STORAGE_CONTEXT="soak"; MIX_ENV=test mix run scripts/probe_kernel_boot.exs
# (test env boots synchronously, storage in test context — clean, does not touch soak/production data)

report = Tiannara.CEL.Kernel.boot_report()

IO.puts("=== Kernel boot report ===")
IO.puts("status=#{inspect(report && report.status)} duration_ms=#{inspect(report && report.duration_ms)}")
IO.puts("failed_critical=#{inspect(report && report.failed_critical)}")
IO.puts("\n--- services ---")

Enum.each(report.services, fn {id, result} ->
  spec =
    case Tiannara.CEL.Kernel.ServiceRegistry.get(id) do
      {:ok, s} -> s
      _ -> nil
    end

  mod = spec && spec.module
  alive = mod != nil and Process.whereis(mod) != nil
  IO.puts(
    String.pad_trailing(to_string(id), 30) <>
      String.pad_trailing(to_string(result), 12) <>
      "module=#{inspect(mod && mod.__info__(:module))} alive=#{alive}"
  )
end)

IO.puts("\n--- key services via whereis ---")
Enum.each([:workflow_engine, :resource_manager, :capability_graph, :event_store, :event_bus, :executive_memory], fn id ->
  spec =
    case Tiannara.CEL.Kernel.ServiceRegistry.get(id) do
      {:ok, s} -> s
      _ -> nil
    end

  mod = spec && spec.module
  IO.puts("#{String.pad_trailing(to_string(id), 20)} module=#{inspect(mod)} running=#{mod != nil and Process.whereis(mod) != nil}")
end)

IO.puts("\n--- ControlCenter subsystem count ---")
case Process.whereis(Tiannara.ControlCenter) do
  nil -> IO.puts("ControlCenter NOT RUNNING")
  _ ->
    st = Tiannara.ControlCenter.status()
    IO.puts("healthy=#{st.healthy}/#{st.total}")
end

IO.puts("PROBE DONE")
