# Execute Gate 2 validation - Institutional Episode Validation
IO.puts("Starting Phase 12.1 Gate 2 Validation...")
IO.puts("Capability 12.1.2 - Institution Investigates Scientific Question")

# Start Runtime Atlas for institution registration
IO.puts("\n🔧 Starting Runtime Atlas...")
{:ok, _atlas_pid} = TiannaraOS.RuntimeAtlas.start_link([])
IO.puts("  ✓ Runtime Atlas started")

# First run Gate 1 to establish constitutional substrate
IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("STEP 1: Running Gate 1 (Constitutional Substrate)")
IO.puts(String.duplicate("=", 80))

case TiannaraOS.Phase12Validation.run_gate_1() do
  {:ok, gate1_results} ->
    IO.puts("\n✅ GATE 1 PASSED - Constitutional substrate validated")
    
    # Now run Gate 2 to validate institutional episode
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("STEP 2: Running Gate 2 (Institutional Episode)")
    IO.puts(String.duplicate("=", 80))
    
    case TiannaraOS.Phase12Validation.run_gate_2(gate1_results) do
      {:ok, final_results} ->
        IO.puts("\n✅ GATE 2 SUCCESSFUL")
        IO.puts("\n🎉 CAPABILITY 12.1.2 VALIDATED")
        IO.puts("The Institution can complete autonomous scientific episodes.")
        
        # Print summary
        episode_report = final_results.episode_report
        IO.puts("\n📊 EPISODE SUMMARY:")
        IO.puts("  Research Goal: #{episode_report.research_goal}")
        IO.puts("  Status: #{episode_report.status}")
        IO.puts("  Execution Time: #{episode_report.execution_time_ms}ms")
        if episode_report.tick_range do
          {start_tick, end_tick} = episode_report.tick_range
          IO.puts("  Ticks: #{start_tick} → #{end_tick}")
        end
        
        IO.puts("\n🔗 NEXT CAPABILITIES ENABLED:")
        IO.puts("  12.2 - Inter-Institution Knowledge Exchange")
        IO.puts("  12.3 - Human-Institution Collaboration")
        IO.puts("  12.4 - JTMS++ Belief Revision")
        IO.puts("  12.5 - VSA Memory Retrieval")
        IO.puts("  12.6 - Do-Calculus Causal Reasoning")
        
      {:error, reason} ->
        IO.puts("\n❌ GATE 2 FAILED")
        IO.puts("Reason: #{reason}")
        IO.puts("\n⚠️  Capability 12.1.2 NOT validated")
    end
    
  {:error, reason} ->
    IO.puts("\n❌ GATE 1 FAILED")
    IO.puts("Reason: #{reason}")
    IO.puts("\n⚠️  Cannot proceed to Gate 2 without constitutional substrate")
end
