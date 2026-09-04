IO.puts("\n=== Tiannara Phase 3.5: Performance Baseline ===\n")

# 1. Startup time
IO.puts("[1/5] Measuring startup time...")
{startup_us, _} = :timer.tc(fn ->
  Application.ensure_all_started(:tiannara)
end)
IO.puts("  Startup: #{Float.round(startup_us / 1_000_000, 3)}s")

# 2. Memory baseline
IO.puts("\n[2/5] Measuring memory baseline...")
:erlang.garbage_collect()
memory = :erlang.memory()
total_mb = Float.round(memory[:total] / 1_048_576, 2)
processes_mb = Float.round(memory[:processes] / 1_048_576, 2)
ets_mb = Float.round(memory[:ets] / 1_048_576, 2)
IO.puts("  Total: #{total_mb} MB")
IO.puts("  Processes: #{processes_mb} MB")
IO.puts("  ETS: #{ets_mb} MB")

# 3. Scheduler latency
IO.puts("\n[3/5] Measuring scheduler latency...")
latencies = for _ <- 1..100 do
  {us, _} = :timer.tc(fn -> :erlang.garbage_collect() end)
  us
end
avg_latency = Float.round(Enum.sum(latencies) / length(latencies), 2)
p99_latency = Enum.at(Enum.sort(latencies), 98) |> then(fn v -> Float.round(v / 1, 2) end)
IO.puts("  Avg GC latency: #{avg_latency} us")
IO.puts("  P99 GC latency: #{p99_latency} us")

# 4. DETS write throughput
IO.puts("\n[4/5] Measuring DETS write throughput...")
alias Tiannara.Council.AuditLog
{write_us, _} = :timer.tc(fn ->
  Enum.each(1..100, fn i ->
    AuditLog.append(:baseline_test, :perf_script, %{index: i})
  end)
end)
writes_per_sec = Float.round(100 / (write_us / 1_000_000), 0)
IO.puts("  Audit log writes: #{writes_per_sec}/s (100 writes in #{Float.round(write_us / 1_000, 2)}ms)")

# 5. World model query latency
IO.puts("\n[5/5] Measuring world model query latency...")
alias Tiannara.World.{UnifiedWorldModel, WorldQueryEngine}

test_id = "baseline_#{System.unique_integer([:positive])}"
spec = %{
  id: test_id, domain: :knowledge, type: :fact, subtype: :data,
  attributes: %{baseline: true}, confidence: 1.0, uncertainty: 0.0,
  provenance: %{origin: :baseline, produced_by: :perf_script, produced_at: DateTime.utc_now()},
  owner_subsystem: :perf_script, version: 1,
  created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), status: :active
}
{:ok, _} = UnifiedWorldModel.create_entity(spec)

{query_us, _} = :timer.tc(fn ->
  {:ok, _} = WorldQueryEngine.find(type: :fact, status: :active, limit: 10)
end)
IO.puts("  Query latency (10 results): #{Float.round(query_us / 1_000, 3)}ms")

IO.puts("\n=== Baseline Summary ===")
IO.puts("  Startup:        #{Float.round(startup_us / 1_000_000, 3)}s")
IO.puts("  Memory:         #{total_mb} MB")
IO.puts("  Scheduler P99:  #{p99_latency} us")
IO.puts("  DETS writes:    #{writes_per_sec}/s")
IO.puts("  Query latency:  #{Float.round(query_us / 1_000, 3)}ms")
IO.puts("\n  Record these values. Future runs must not regress > 20% without justification.")
IO.puts("=== Baseline complete ===\n")
