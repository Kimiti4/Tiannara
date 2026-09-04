# Execute Capability 12.1.2B - Adaptive Institutional Scientific Episodes
IO.puts("Starting Phase 12.1 Capability 12.1.2B Validation...")
IO.puts("Testing Adaptive Institutional Cognition Under Uncertainty\n")

# Start Runtime Atlas for institution registration
IO.puts("🔧 Starting Runtime Atlas...")
{:ok, _atlas_pid} = TiannaraOS.RuntimeAtlas.start_link([])
IO.puts("  ✓ Runtime Atlas started\n")

# Create test institution (similar to Gate 1)
IO.puts("🔧 Creating test institution...")
institution_id = :test_lab
world_id = :test_world
founded_tick = 0

research_institution = TiannaraOS.ResearchInstitution.new(institution_id, world_id, founded_tick)
{:ok, kernel_pid} = TiannaraOS.InstitutionKernel.start_link(institution_id, research_institution)
IO.puts("  ✓ Test institution created (PID: #{inspect(kernel_pid)})\n")

# Start Constitution Dashboard
IO.puts("🔧 Starting Constitution Dashboard...")
{:ok, _dashboard_pid} = TiannaraOS.ConstitutionDashboard.start_link(:test_lab, kernel_pid)
IO.puts("  ✓ Constitution Dashboard started\n")

# Execute Five Adaptive Research Episodes
IO.puts(String.duplicate("=", 80))
IO.puts("EXECUTING FIVE ADAPTIVE RESEARCH EPISODES")
IO.puts(String.duplicate("=", 80))

# Episode 1: Successful Discovery
IO.puts("\n" <> String.duplicate("-", 80))
IO.puts("EPISODE 1: SUCCESSFUL DISCOVERY")
IO.puts("Goal: Does increasing mutation rate improve capability diversity?")
IO.puts(String.duplicate("-", 80))

{:ok, result1} = TiannaraOS.InstitutionKernel.conduct_research_cycle(kernel_pid, 
  "Does increasing mutation rate improve capability diversity?",
  %{budget: 100.0, evidence_scenario: :positive})
IO.puts("✓ Episode 1 completed successfully")
episode_report1 = TiannaraOS.InstitutionEpisodeReport.generate(result1, :test_lab, %{})
TiannaraOS.InstitutionEpisodeReport.print(episode_report1)

# Episode 2: Negative Result
IO.puts("\n" <> String.duplicate("-", 80))
IO.puts("EPISODE 2: NEGATIVE RESULT")
IO.puts("Goal: Does decreasing mutation rate improve capability diversity?")
IO.puts(String.duplicate("-", 80))

{:ok, result2} = TiannaraOS.InstitutionKernel.conduct_research_cycle(kernel_pid,
  "Does decreasing mutation rate improve capability diversity?",
  %{budget: 100.0, evidence_scenario: :negative})
IO.puts("✓ Episode 2 completed (negative result)")
episode_report2 = TiannaraOS.InstitutionEpisodeReport.generate(result2, :test_lab, %{})
TiannaraOS.InstitutionEpisodeReport.print(episode_report2)

# Episode 3: Contradictory Evidence
IO.puts("\n" <> String.duplicate("-", 80))
IO.puts("EPISODE 3: CONTRADICTORY EVIDENCE")
IO.puts("Goal: Does mutation rate affect innovation speed?")
IO.puts(String.duplicate("-", 80))

{:ok, result3} = TiannaraOS.InstitutionKernel.conduct_research_cycle(kernel_pid,
  "Does mutation rate affect innovation speed?",
  %{budget: 100.0, evidence_scenario: :contradictory})
IO.puts("✓ Episode 3 completed (inconclusive)")
episode_report3 = TiannaraOS.InstitutionEpisodeReport.generate(result3, :test_lab, %{})
TiannaraOS.InstitutionEpisodeReport.print(episode_report3)

# Episode 4: Governance Rejection
IO.puts("\n" <> String.duplicate("-", 80))
IO.puts("EPISODE 4: GOVERNANCE REJECTION")
IO.puts("Goal: Test research violating institutional policy")
IO.puts(String.duplicate("-", 80))

{:ok, result4} = TiannaraOS.InstitutionKernel.conduct_research_cycle(kernel_pid,
  "Test research that violates ethical guidelines",
  %{budget: 100.0, reject_by_governance: true})
IO.puts("✓ Episode 4 completed (governance rejected)")
episode_report4 = TiannaraOS.InstitutionEpisodeReport.generate(result4, :test_lab, %{})
TiannaraOS.InstitutionEpisodeReport.print(episode_report4)

# Episode 5: Budget Exhaustion
IO.puts("\n" <> String.duplicate("-", 80))
IO.puts("EPISODE 5: BUDGET EXHAUSTION")
IO.puts("Goal: Attempt research exceeding available budget")
IO.puts(String.duplicate("-", 80))

{:ok, result5} = TiannaraOS.InstitutionKernel.conduct_research_cycle(kernel_pid,
  "Attempt expensive research requiring more budget than available",
  %{budget: 999999.0})  # Request impossible budget
IO.puts("✓ Episode 5 completed (deferred due to budget)")
episode_report5 = TiannaraOS.InstitutionEpisodeReport.generate(result5, :test_lab, %{})
TiannaraOS.InstitutionEpisodeReport.print(episode_report5)

# Generate Comparison Report
IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("GENERATING INSTITUTION EPISODE COMPARISON REPORT")
IO.puts(String.duplicate("=", 80))

comparison_report = TiannaraOS.InstitutionEpisodeComparisonReport.generate([
  episode_report1,
  episode_report2,
  episode_report3,
  episode_report4,
  episode_report5
])

TiannaraOS.InstitutionEpisodeComparisonReport.print(comparison_report)

# Final validation
IO.puts("\n" <> String.duplicate("=", 80))
IO.puts("CAPABILITY 12.1.2B VALIDATION SUMMARY")
IO.puts(String.duplicate("=", 80))

if comparison_report.overall_status == :pass do
  IO.puts("\n✅ CAPABILITY 12.1.2B PASSED")
  IO.puts("Institution demonstrates adaptive scientific reasoning under uncertainty.")
  IO.puts("ResearchCycleResult is now frozen as canonical transaction.")
  IO.puts("\nPhase 12.2 (Inter-Institution Knowledge Exchange) may now begin.\n")
else
  IO.puts("\n❌ CAPABILITY 12.1.2B FAILED")
  IO.puts("Institution did not demonstrate sufficient adaptive behavior.\n")
  System.halt(1)
end
