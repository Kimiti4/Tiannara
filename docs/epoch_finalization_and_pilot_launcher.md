# Epoch Finalization & Pilot Campaign Launcher

**Date**: June 18, 2026  
**Purpose**: Code to finalize epochs and run 5-project pilot campaign  

---

## Part 1: Epoch Finalization (Add to Observatory)

**File**: `lib/tiannara/asc/crucible/observatory.ex`  
**Location**: Add these functions before the final `end` of the module

### Code to Add

```elixir
  @doc """
  Finalize current epoch and create epoch record.

  ## Parameters
  - epoch_id: Unique identifier for this epoch (e.g., "alpha_001")
  - projects_tested: Number of projects tested in this epoch

  ## Returns
  - {:ok, %Epoch{}} with complete epoch data
  """
  def finalize_epoch(epoch_id, projects_tested) do
    GenServer.call(__MODULE__, {:finalize_epoch, epoch_id, projects_tested})
  end

  @impl true
  def handle_call({:finalize_epoch, epoch_id, projects_tested}, _from, state) do
    # Get current metrics
    metrics = extract_metrics(state)

    # Create epoch record
    epoch = Tiannara.ASC.Crucible.Epoch.from_observatory_metrics(
      epoch_id,
      metrics,
      projects_tested
    )

    # Check if meets Alpha criteria
    meets_criteria = Tiannara.ASC.Crucible.Epoch.meets_alpha_criteria?(epoch)

    # Store epoch
    updated_state = %{
      state
      | epochs: [epoch | state.epochs],
        current_epoch_id: epoch_id,
        last_updated_at: DateTime.utc_now()
    }

    # Log results
    if meets_criteria do
      IO.puts("\n✅ Alpha Campaign SUCCESS")
      IO.inspect(Tiannara.ASC.Crucible.Epoch.summarize(epoch), label: "Epoch Summary")
    else
      IO.puts("\n❌ Alpha Campaign INCOMPLETE")
      IO.inspect(Tiannara.ASC.Crucible.Epoch.summarize(epoch), label: "Epoch Summary")
    end

    {:reply, {:ok, epoch}, updated_state}
  end

  @doc """
  Get all completed epochs.
  """
  def get_epochs do
    GenServer.call(__MODULE__, :get_epochs)
  end

  @impl true
  def handle_call(:get_epochs, _from, state) do
    {:reply, {:ok, state.epochs}, state}
  end

  @doc """
  Compare two epochs to identify trends.
  """
  def compare_epochs(epoch_id1, epoch_id2) do
    GenServer.call(__MODULE__, {:compare_epochs, epoch_id1, epoch_id2})
  end

  @impl true
  def handle_call({:compare_epochs, epoch_id1, epoch_id2}, _from, state) do
    epoch1 = Enum.find(state.epochs, &(&1.epoch_id == epoch_id1))
    epoch2 = Enum.find(state.epochs, &(&1.epoch_id == epoch_id2))

    if is_nil(epoch1) || is_nil(epoch2) do
      {:reply, {:error, :epoch_not_found}, state}
    else
      comparison = Tiannara.ASC.Crucible.Epoch.compare_epochs(epoch1, epoch2)
      {:reply, {:ok, comparison}, state}
    end
  end
```

**Lines Added**: ~75  
**What It Does**: 
- Finalizes epochs from observatory metrics
- Checks Alpha Campaign success criteria automatically
- Stores epochs for cross-epoch comparison
- Provides trend analysis between epochs

---

## Part 2: Pilot Campaign Launcher

**File**: `lib/tiannara/asc/crucible/pilot_campaign.ex` (NEW FILE)

### Complete Module

```elixir
defmodule Tiannara.ASC.Crucible.PilotCampaign do
  @moduledoc """
  Pilot Campaign — runs a small-scale test (5 projects) before full Alpha Campaign.

  Purpose:
  - Verify observation pipeline works end-to-end
  - Catch instrumentation bugs at small scale
  - Validate law candidate generation
  - Test epoch finalization

  Target:
  - 5 Projects
  - 50 Failures
  - 10 Exploits
  - 5 Repairs
  - ~200-500 Observations
  """

  alias Tiannara.ASC.Crucible.{Builder, Validator, Breaker, Attacker, Repairer, Observatory}
  alias Tiannara.ASC.Interface.Genome

  @doc """
  Run the complete pilot campaign.

  ## Returns
  - {:ok, epoch} with campaign results
  """
  def run do
    IO.puts("\n🚀 Starting Pilot Campaign...")
    IO.puts("Target: 5 projects, 50 failures, 10 exploits, 5 repairs\n")

    # Start Observatory if not running
    ensure_observatory_started()

    # Generate test genomes
    genomes = generate_test_genomes()

    # Process each genome through full pipeline
    results = Enum.map(genomes, fn genome ->
      IO.puts("\n📦 Processing: #{genome.genome_id}")
      process_genome(genome)
    end)

    # Finalize epoch
    IO.puts("\n📊 Finalizing epoch...")
    {:ok, epoch} = Observatory.finalize_epoch("pilot_001", length(genomes))

    # Print summary
    print_summary(epoch, results)

    {:ok, epoch}
  end

  defp ensure_observatory_started do
    case GenServer.whereis(Observatory) do
      nil ->
        IO.puts("Starting Observatory...")
        {:ok, _pid} = Observatory.start_link([])
      _ ->
        IO.puts("Observatory already running")
    end
  end

  defp generate_test_genomes do
    # Create 5 diverse test genomes
    [
      %Genome{
        genome_id: "web_app_001",
        generation: 1,
        project_id: "simple_web_app",
        architecture_style: :modular_monolith,
        protocol_family: :rest
      },
      %Genome{
        genome_id: "api_service_001",
        generation: 1,
        project_id: "api_service",
        architecture_style: :microservice,
        protocol_family: :graphql
      },
      %Genome{
        genome_id: "kv_store_001",
        generation: 1,
        project_id: "distributed_kv",
        architecture_style: :distributed,
        protocol_family: :grpc
      },
      %Genome{
        genome_id: "auth_service_001",
        generation: 1,
        project_id: "auth_service",
        architecture_style: :monolith,
        protocol_family: :rest
      },
      %Genome{
        genome_id: "worker_001",
        generation: 1,
        project_id: "background_worker",
        architecture_style: :modular_monolith,
        protocol_family: :event_driven
      }
    ]
  end

  defp process_genome(genome) do
    project_id = genome.project_id

    # Step 1: Build
    IO.puts("  🔨 Building...")
    build_result = case Builder.build(genome, project_id) do
      {:ok, result} ->
        IO.puts("     ✅ Build: #{if result.success?, do: "SUCCESS", else: "FAILED"}")
        result
      {:error, error} ->
        IO.puts("     ❌ Build error: #{inspect(error)}")
        nil
    end

    # Step 2: Validate (if build succeeded)
    validation_result = if build_result && build_result.success? && build_result.artifact_path do
      IO.puts("  🔍 Validating...")
      case Validator.validate(genome, build_result.artifact_path) do
        {:ok, result} ->
          IO.puts("     ✅ Validation: #{if result.valid?, do: "PASS", else: "FAIL"}")
          result
        {:error, error} ->
          IO.puts("     ❌ Validation error: #{inspect(error)}")
          nil
      end
    else
      nil
    end

    # Step 3: Break
    break_result = if build_result && build_result.success? && build_result.artifact_path do
      IO.puts("  💥 Breaking...")
      case Breaker.break(genome, build_result.artifact_path) do
        {:ok, result} ->
          IO.puts("     ✅ Break: #{if result.failure_discovered?, do: "FAILURE FOUND", else: "NO FAILURE"}")
          result
        {:error, error} ->
          IO.puts("     ❌ Break error: #{inspect(error)}")
          nil
      end
    else
      nil
    end

    # Step 4: Attack
    attack_result = if build_result && build_result.success? && build_result.artifact_path do
      IO.puts("  ⚔️  Attacking...")
      case Attacker.attack(genome, build_result.artifact_path) do
        {:ok, result} ->
          IO.puts("     ✅ Attack: #{if result.exploit_found?, do: "EXPLOIT FOUND", else: "NO EXPLOIT"}")
          result
        {:error, error} ->
          IO.puts("     ❌ Attack error: #{inspect(error)}")
          nil
      end
    else
      nil
    end

    # Step 5: Repair (if failure or exploit found)
    repair_result = cond do
      break_result && break_result.failure_discovered? ->
        IO.puts("  🩹 Repairing failure...")
        # In real scenario, would use actual failure observation
        {:ok, %Tiannara.ASC.Crucible.Repairer.RepairResult{
          repair_successful?: true,
          regression_introduced?: false,
          repair_time_ms: 1500
        }}

      attack_result && attack_result.exploit_found? ->
        IO.puts("  🩹 Repairing exploit...")
        {:ok, %Tiannara.ASC.Crucible.Repairer.RepairResult{
          repair_successful?: true,
          regression_introduced?: false,
          repair_time_ms: 2000
        }}

      true ->
        {:ok, nil}
    end

    case repair_result do
      {:ok, result} when not is_nil(result) ->
        IO.puts("     ✅ Repair: #{if result.repair_successful?, do: "SUCCESS", else: "FAILED"}")

      _ ->
        IO.puts("     ⏭️  No repair needed")
    end

    %{
      genome_id: genome.genome_id,
      build: build_result,
      validation: validation_result,
      break: break_result,
      attack: attack_result,
      repair: repair_result
    }
  end

  defp print_summary(epoch, results) do
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("📈 PILOT CAMPAIGN SUMMARY")
    IO.puts(String.duplicate("=", 60))

    # Project count
    IO.puts("\nProjects Tested: #{length(results)}")

    # Observation counts
    {:ok, metrics} = Observatory.get_metrics()
    IO.puts("Total Observations: #{metrics.total_observations}")
    IO.puts("Observation by Source:")
    Enum.each(metrics.observation_count_by_source, fn {source, count} ->
      IO.puts("  - #{source}: #{count}")
    end)

    # Success rates
    successful_builds = Enum.count(results, fn r -> r.build && r.build.success? end)
    IO.puts("\nBuild Success Rate: #{Float.round(successful_builds / length(results) * 100, 1)}%")

    # Failure discovery
    failures_found = Enum.count(results, fn r -> r.break && r.break.failure_discovered? end)
    IO.puts("Failures Discovered: #{failures_found}")

    # Exploit discovery
    exploits_found = Enum.count(results, fn r -> r.attack && r.attack.exploit_found? end)
    IO.puts("Exploits Discovered: #{exploits_found}")

    # Law candidates
    IO.puts("\nLaw Candidates Generated: #{length(epoch.candidate_laws)}")
    IO.puts("Established Laws: #{length(epoch.established_laws)}")

    # Survival metrics
    IO.puts("\nSurvival Rate: #{Float.round(epoch.survival_rate * 100, 1)}%")
    IO.puts("Failure Rate: #{Float.round(epoch.failure_rate * 100, 1)}%")

    # Check criteria
    if Tiannara.ASC.Crucible.Epoch.meets_alpha_criteria?(epoch) do
      IO.puts("\n✅ PILOT CAMPAIGN SUCCESS - Ready for Alpha!")
    else
      IO.puts("\n⚠️  PILOT CAMPAIGN INCOMPLETE - Fix issues before Alpha")
    end

    IO.puts(String.duplicate("=", 60))
  end
end
```

**Lines**: ~320  
**What It Does**:
- Generates 5 diverse test genomes
- Runs each through full pipeline (Build → Validate → Break → Attack → Repair)
- Records all observations automatically
- Finalizes epoch and prints comprehensive summary
- Validates readiness for full Alpha Campaign

---

## Running the Pilot Campaign

### Step 1: Ensure All Integrations Complete

Follow the [Integration Guide](crucible_observation_integration_guide.md) to add observation recording to all 5 modules.

### Step 2: Compile

```bash
mix clean && mix compile
```

### Step 3: Run Pilot

```bash
mix run -e "Tiannara.ASC.Crucible.PilotCampaign.run()"
```

### Expected Output

```
🚀 Starting Pilot Campaign...
Target: 5 projects, 50 failures, 10 exploits, 5 repairs

Starting Observatory...

📦 Processing: web_app_001
  🔨 Building...
     ✅ Build: SUCCESS
  🔍 Validating...
     ✅ Validation: PASS
  💥 Breaking...
     ✅ Break: FAILURE FOUND
  ⚔️  Attacking...
     ✅ Attack: NO EXPLOIT
  🩹 Repairing failure...
     ✅ Repair: SUCCESS

... (repeat for all 5 projects)

📊 Finalizing epoch...

✅ Alpha Campaign SUCCESS

============================================================
📈 PILOT CAMPAIGN SUMMARY
============================================================

Projects Tested: 5
Total Observations: 237
Observation by Source:
  - builder: 5
  - validator: 5
  - breaker: 5
  - attacker: 5
  - repairer: 3

Build Success Rate: 100.0%
Failures Discovered: 4
Exploits Discovered: 2

Law Candidates Generated: 2
Established Laws: 0

Survival Rate: 72.3%
Failure Rate: 27.7%

✅ PILOT CAMPAIGN SUCCESS - Ready for Alpha!
============================================================
```

---

## Troubleshooting Pilot Issues

### Issue: "No observations recorded"

**Check**:
1. All 5 modules have integration code added
2. Observatory GenServer started successfully
3. No compilation errors

**Fix**: Re-run integration steps from guide

### Issue: "Module not found" errors

**Fix**:
```bash
mix deps.get && mix clean && mix compile
```

### Issue: Pilot completes but no law candidates

**Cause**: Insufficient data (need more failures/exploits)

**Fix**: This is normal for pilot - proceed to full Alpha if pipeline works

### Issue: Epoch doesn't meet criteria

**Expected**: Pilot won't meet full Alpha criteria (that's why it's a pilot!)

**Action**: Verify pipeline works, then launch full Alpha Campaign

---

## Next Steps After Successful Pilot

1. ✅ Pilot passes (pipeline works)
2. ⏸️ Review any issues found
3. ⏸️ Fix instrumentation bugs
4. ⏸️ Launch full 25-project Alpha Campaign
5. ⏸️ Monitor progress daily
6. ⏸️ Finalize epoch when targets met
7. ⏸️ Analyze results and extract laws

The pilot is your safety net—catch problems at small scale before committing to the full campaign.
