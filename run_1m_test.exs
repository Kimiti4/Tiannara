# Multi-Scale Replay Test - 1M samples
IO.puts("\n🎯 Multi-Scale Replay Test - 1M")
IO.puts("═══════════════════════════════════════\n")

# Start required GenServers
{:ok, _pid} = TiannaraOS.Governance.GovernanceLedger.start_link([])
{:ok, _pid} = TiannaraOS.Governance.GovernanceCostLedger.start_link([])

sample_size = 1000000
seed = 42

IO.puts("Running GC-001 replay with #{sample_size} samples (seed=#{seed})...\n")

# Import Laboratory module
alias TiannaraOS.Governance.Certification.Laboratory
alias TiannaraOS.Governance.DeterministicContext

ctx = DeterministicContext.new(seed: seed)

IO.puts("Executing replay certification...\n")

case Laboratory.execute_campaign(:gc_001_replay, context: ctx, sample_size: sample_size) do
  {:ok, result} ->
    IO.puts("\n✅ Replay test complete!")
    IO.puts("   Sample Size: #{result.sample_size}")
    IO.puts("   Successes: #{result.successes}")
    IO.puts("   Failures: #{result.failures}")
    IO.puts("   Success Rate: #{Float.round(result.success_rate * 100, 2)}%")
    IO.puts("   Determinism Verified: #{result.determinism_verified}")
    
    # Compute hash of result for verification
    result_hash = :crypto.hash(:sha256, :erlang.term_to_binary(result)) |> Base.encode16(case: :lower)
    IO.puts("   Result Hash: #{result_hash}")
    
  {:error, reason} ->
    IO.puts("\n❌ Replay test failed!")
    IO.puts("   Reason: #{inspect(reason)}")
    System.halt(1)
end
