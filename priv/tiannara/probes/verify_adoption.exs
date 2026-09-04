{:ok, _} = Application.ensure_all_started(:tiannara)
report = Tiannara.CEL.Kernel.boot_report()
IO.puts("VERIFY_RESULT " <> Jason.encode!(%{
  boot_status: report.status,
  failed_critical: report.failed_critical,
  runtime_state: Tiannara.CEL.Kernel.runtime_state(),
  event_store_healthy: Tiannara.CEL.Services.EventStore.healthy?(),
  executive_memory_health: Tiannara.CEL.Services.ExecutiveMemory.health(),
  event_bus_health: Tiannara.CEL.Services.EventBus.health()
}))
