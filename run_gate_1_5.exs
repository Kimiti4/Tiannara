# Execute Gate 1.5 validation - Constitutional Wiring Validation
IO.puts("Starting Phase 12.1 Gate 1.5 Validation...")
IO.puts("Objective: Prove the Constitution is alive (not just surviving)")

case TiannaraOS.Phase12Validation.run_gate_1_5() do
  {:ok, results} ->
    IO.puts("\n✅ GATE 1.5 COMPLETED")
    IO.inspect(results, limit: :infinity, pretty: true)
    
    if results.overall_status == :CONSTITUTIONALLY_WIRED do
      IO.puts("\n🎉 THE CONSTITUTION IS ALIVE!")
      IO.puts("All integrations connected - ready for Gate 2")
    else
      IO.puts("\n⚠️  Some integrations pending - review report above")
    end
    
  {:error, reason} ->
    IO.puts("\n❌ GATE 1.5 FAILED")
    IO.puts("Reason: #{reason}")
end
