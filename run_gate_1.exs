# Execute Gate 1 validation
IO.puts("Starting Phase 12.1 Gate 1 Validation...")

# Start Runtime Atlas for institution registration
IO.puts("\n🔧 Starting Runtime Atlas...")
{:ok, _atlas_pid} = TiannaraOS.RuntimeAtlas.start_link([])
IO.puts("  ✓ Runtime Atlas started")

case TiannaraOS.Phase12Validation.run_gate_1() do
  {:ok, results} ->
    IO.puts("\n✅ GATE 1 SUCCESSFUL")
    IO.inspect(results, limit: :infinity, pretty: true)
    
  {:error, reason} ->
    IO.puts("\n❌ GATE 1 FAILED")
    IO.puts("Reason: #{reason}")
end
