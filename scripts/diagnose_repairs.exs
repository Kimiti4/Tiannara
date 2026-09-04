#!/usr/bin/env elixir

# Diagnostic script to understand why all repairs are failing in Phase 4.7

Mix.install_deps()

# Start required applications
Application.ensure_all_started(:logger)
Application.ensure_all_started(:jason)

# Load modules
Code.require_file("lib/tiannara/asc/crucible/observation.ex")
Code.require_file("lib/tiannara/asc/crucible/repairer.ex")
Code.require_file("lib/tiannara/asc/crucible/repair_reuse_engine.ex")

IO.puts("=" |> String.duplicate(80))
IO.puts("🔍 PHASE 4.7 REPAIR DIAGNOSTIC")
IO.puts("=" |> String.duplicate(80))

# Create a sample failure observation
failure_obs = %Tiannara.ASC.Crucible.Observation{
  id: "test_failure_001",
  project_id: "test_project",
  genome_id: "test_genome",
  source: :breaker,
  observation_type: :failure,
  severity: :medium,
  origin: :implementation,
  reproducible: true,
  confidence: 0.8,
  evidence: ["Test failure for diagnosis"],
  timestamp: DateTime.utc_now(),
  generation: 1
}

IO.puts("\n📋 Test Failure Observation:")
IO.inspect(failure_obs, limit: :infinity)

# Test 1: Direct Repairer call
IO.puts("\n" <> ("-" |> String.duplicate(80)))
IO.puts("TEST 1: Direct Repairer.repair() call")
IO.puts("-" |> String.duplicate(80))

case Tiannara.ASC.Crucible.Repairer.repair(failure_obs, "/tmp/test_artifact") do
  {:ok, result} ->
    IO.puts("✅ Repairer returned {:ok, result}")
    IO.puts("   repair_successful?: #{result.repair_successful?}")
    IO.puts("   regression_introduced?: #{result.regression_introduced?}")
    IO.puts("   repair_description: #{result.repair_description}")
    
    if result.repair_successful? do
      IO.puts("\n🎉 SUCCESS! Repair worked as expected (60% simulated rate)")
    else
      IO.puts("\n❌ FAILED! Repair failed despite 60% simulated success rate")
    end
    
  {:error, error} ->
    IO.puts("❌ Repairer returned {:error, #{inspect(error)}}")
end

# Test 2: RepairReuseEngine call
IO.puts("\n" <> ("-" |> String.duplicate(80)))
IO.puts("TEST 2: RepairReuseEngine.repair_failure() call")
IO.puts("-" |> String.duplicate(80))

# Initialize the engine
Tiannara.ASC.Crucible.RepairReuseEngine.initialize_metrics()

case Tiannara.ASC.Crucible.RepairReuseEngine.repair_failure(failure_obs, "/tmp/test_artifact") do
  {:ok, result} ->
    IO.puts("✅ RepairReuseEngine returned {:ok, result}")
    IO.puts("   repair_successful?: #{result.repair_successful?}")
    IO.puts("   reused_pattern?: #{result.reused_pattern?}")
    IO.puts("   pattern_id: #{result.pattern_id || "nil"}")
    IO.puts("   knowledge_reuse_rate: #{Float.round(result.knowledge_reuse_rate * 100, 1)}%")
    
  {:error, error} ->
    IO.puts("❌ RepairReuseEngine returned {:error, #{inspect(error)}}")
end

IO.puts("\n" <> ("=" |> String.duplicate(80)))
IO.puts("DIAGNOSTIC COMPLETE")
IO.puts("=" |> String.duplicate(80))
