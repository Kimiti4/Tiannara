# Multi-Scale Test - 10K samples
IO.puts("\n🎯 Multi-Scale Test - 10K")
IO.puts("═══════════════════════════════════════════\n")

{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])

seed = 42
sample_count = 10_000

IO.puts("Running GC-001 replay with #{sample_count} samples (seed=#{seed})...\n")

ctx = TiannaraOS.Governance.DeterministicContext.new(seed: seed)

case TiannaraOS.Governance.Certification.Laboratory.execute_campaign(:gc_001_replay, context: ctx, sample_count: sample_count) do
  {:ok, result} ->
    IO.puts("\n✅ GC-001 completed!")
    IO.puts("   Sample count: #{sample_count}")
    IO.puts("   Successes: #{result.successes}")
    IO.puts("   Failures: #{result.failures}")
    IO.puts("   Success rate: #{result.success_rate * 100}%")
    IO.puts("   Determinism verified: #{result.determinism_verified}")
    
    # Hash the result for comparison
    hash = :crypto.hash(:sha256, :erlang.term_to_binary(result))
           |> Base.encode16(case: :lower)
    IO.puts("   Result hash: #{hash}")
  error ->
    IO.inspect(error, label: "ERROR")
end
