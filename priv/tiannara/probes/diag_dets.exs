Process.flag(:trap_exit, true)

p = fn label, val -> IO.puts("#{label} #{inspect(val)}") end

{:ok, _} =
  Supervisor.start_link(
    [Tiannara.CEL.Services.EventStore, Tiannara.CEL.Services.ExecutiveMemory],
    strategy: :one_for_one,
    name: :diag_sup
  )

Process.sleep(200)
p.("dets_info_event_store", :dets.info(:cel_event_store))
p.("dets_info_mem", :dets.info(:cel_memory_v2))
p.("es_healthy", Tiannara.CEL.Services.EventStore.healthy?())
p.("em_health", Tiannara.CEL.Services.ExecutiveMemory.health())
p.("es_stats", Tiannara.CEL.Services.EventStore.stats())

Process.exit(Process.whereis(:diag_sup), :kill)
Process.sleep(300)
p.("after_kill_es", Process.whereis(Tiannara.CEL.Services.EventStore))

{:ok, _} =
  Supervisor.start_link(
    [Tiannara.CEL.Services.EventStore, Tiannara.CEL.Services.ExecutiveMemory],
    strategy: :one_for_one,
    name: :diag_sup2
  )

Process.sleep(200)
p.("dets_info_event_store_reopened", :dets.info(:cel_event_store))
p.("dets_info_mem_reopened", :dets.info(:cel_memory_v2))
p.("es_healthy_reopened", Tiannara.CEL.Services.EventStore.healthy?())
p.("em_health_reopened", Tiannara.CEL.Services.ExecutiveMemory.health())