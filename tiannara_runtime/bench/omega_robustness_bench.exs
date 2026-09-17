Mix.install([])

alias TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer, as: CPL
alias TiannaraRuntime.Omega

base = Path.join(System.tmp_dir!(), "tiannara_omega_bench_#{System.unique_integer([:positive])}")
File.rm_rf!(base)

{:ok, _cpl} = CPL.start_link(storage_path: Path.join(base, "cpl"), checkpoint_interval: 60_000)

{:ok, _omega} =
  Omega.Supervisor.start_link(
    heartbeat: [interval: 1_000],
    scheduler: [jobs: []],
    executive_memory: [storage_path: Path.join(base, "memory"), checkpoint_interval: 60_000],
    checkpoint_reliability: [interval: 60_000],
    event_store_audit: [interval: 60_000],
    runtime_health: [interval: 60_000]
  )

iterations = 1_000

{put_us, :ok} =
  :timer.tc(fn ->
    Enum.each(1..iterations, fn i ->
      Omega.ExecutiveMemory.put({:bench, i}, %{value: i})
    end)
  end)

{publish_us, _events} =
  :timer.tc(fn ->
    Enum.map(1..iterations, fn i ->
      Omega.SentinelEventBus.publish(:bench_event, %{value: i})
    end)
  end)

{checkpoint_us, {:ok, _checkpoint}} = :timer.tc(fn -> Omega.ExecutiveMemory.checkpoint() end)

IO.puts("Omega robustness bench")
IO.puts("memory_put_avg_us=#{div(put_us, iterations)}")
IO.puts("event_publish_avg_us=#{div(publish_us, iterations)}")
IO.puts("checkpoint_us=#{checkpoint_us}")

File.rm_rf!(base)
