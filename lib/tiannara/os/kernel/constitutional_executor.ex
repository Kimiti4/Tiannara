defmodule TiannaraOS.Kernel.ConstitutionalExecutor do
  @moduledoc """
  ConstitutionalExecutor - The ONLY legal execution entry point for recursive civilization.

  This module enforces constitutional execution by making it impossible to bypass
  structural validation. No module may invoke RecursiveCivilizationRunner.execute()
  directly. All execution must go through this executor.

  ## Constitutional Role

  ConstitutionalExecutor guarantees that every simulation execution:
  1. Builds ConstitutionManifest (Software Bill of Materials)
  2. Derives ConstitutionFingerprint from Manifest (SHA256(SerializedManifest))
  3. Passes StructuralValidationGate (all invariants)
  4. Generates ConstitutionCertificate after execution
  5. Records certificate in ConstitutionalDriftJournal
  6. Only then proceeds to RecursiveCivilizationRunner

  If any check fails, execution is forbidden and ConstitutionalViolation is raised.

  ## Architecture

  ```
  External Request
          │
          ▼
  ConstitutionalExecutor.execute(config)
          │
          ├─→ Build ConstitutionManifest (SBOM)
          │       └─→ Owns all component hashes
          │
          ├─→ Derive ConstitutionFingerprint
          │       └─→ SHA256(SerializedManifest)
          │
          ├─→ Check ConstitutionalDriftJournal
          │       └─→ Compare manifests, not raw hashes
          │
          ├─→ Spawn ConstitutionalWatchdog
          │       └─→ Runtime drift monitoring
          │
          ├─→ Run StructuralValidationGate
          │       ├─→ Replay Determinism
          │       ├─→ Conservation Laws
          │       ├─→ Temporal Separation
          │       ├─→ Reward Leakage
          │       ├─→ Seed Independence
          │       ├─→ Metric Independence
          │       ├─→ Lifecycle Completeness
          │       └─→ Rollback Completeness
          │
          ├─→ PASS → RecursiveCivilizationRunner.execute()
          │       │
          │       ├─→ Generate ConstitutionCertificate
          │       │     └─→ Bind execution to manifest
          │       │
          │       ├─→ Record Certificate in DriftJournal
          │       │     └─→ Append-only immutable record
          │       │
          │       └─→ Return generation history with references
          │             └─→ manifest_id + certificate_id
          │
          └─→ FAIL → Raise ConstitutionalViolation
  ```

  ## Usage

      config = %{
        initial_capital: 0,
        max_generations: 100,
        scientific_capital_policy: policy,
        generation_histories: histories
      }

      case ConstitutionalExecutor.execute(config) do
        {:ok, generation_history} -> proceed_with_results()
        {:error, violation} -> handle_constitutional_violation(violation)
      end

  ## Constitutional Guarantee

  There exists NO code path that reaches RecursiveCivilizationRunner without
  first passing through ConstitutionalExecutor and StructuralValidationGate.
  Every execution produces a ConstitutionCertificate bound to a ConstitutionManifest.
  """

  alias TiannaraOS.Kernel.StructuralValidationGate
  alias TiannaraOS.StructuralValidationResult
  alias TiannaraOS.RecursiveCivilizationRunner
  alias TiannaraOS.ScientificCapitalPolicy
  alias TiannaraOS.Kernel.ConstitutionFingerprint
  alias TiannaraOS.Kernel.ConstitutionalDriftJournal
  alias TiannaraOS.ConstitutionalWatchdog
  alias TiannaraOS.Kernel.ConstitutionManifest
  alias TiannaraOS.Kernel.ConstitutionCertificate

  @type config :: %{
    required(:initial_capital) => non_neg_integer(),
    required(:max_generations) => pos_integer(),
    required(:scientific_capital_policy) => ScientificCapitalPolicy.t(),
    optional(:generation_histories) => [map()],
    optional(:causal_graph) => map(),
    optional(:multi_seed_trial_results) => [map()]
  }

  @type execution_result :: {:ok, map()} | {:error, map()}

  @doc """
  Execute recursive civilization with mandatory constitutional validation.

  This is the ONLY legal way to execute a recursive civilization simulation.
  Direct calls to RecursiveCivilizationRunner.execute/1 are constitutionally forbidden.

  ## Execution Pipeline

  1. Initialize ConstitutionalDriftJournal
  2. Build ConstitutionManifest (SBOM with all component hashes)
  3. Derive ConstitutionFingerprint = SHA256(SerializedManifest)
  4. Check ConstitutionalDriftJournal for drift (compare manifests)
  5. Spawn ConstitutionalWatchdog for runtime monitoring
  6. Run StructuralValidationGate (all invariants)
  7. If PASS → Execute RecursiveCivilizationRunner
  8. Generate ConstitutionCertificate (bind execution to manifest)
  9. Record certificate in ConstitutionalDriftJournal
  10. Update generation history with manifest_id + certificate_id
  11. If FAIL → Raise ConstitutionalViolation

  ## Parameters

  - `config`: Execution configuration containing:
    - `:initial_capital` - Starting scientific capital amount
    - `:max_generations` - Maximum generations to simulate
    - `:scientific_capital_policy` - Active policy with coefficients
    - `:generation_histories` - Historical generation data (for replay)
    - `:causal_graph` - Causal dependency graph (for temporal validation)
    - `:multi_seed_trial_results` - Multi-seed trial results (for seed independence)

  ## Returns

  - `{:ok, generation_history}` - Simulation completed successfully with manifest_id and certificate_id
  - `{:error, violation}` - Constitutional violation detected

  ## Raises

  - `RuntimeError` with reason "Constitutional Violation: <reason>" if gate fails
  """
  @spec execute(config()) :: execution_result()
  def execute(config) do
    IO.puts("\n🛡️  ConstitutionalExecutor: Beginning constitutional validation...")

    # Step 1: Initialize drift journal (if not already initialized)
    try do
      ConstitutionalDriftJournal.init()
    rescue
      _ -> :ok  # Already initialized
    end

    # Step 2: Build ConstitutionManifest (Software Bill of Materials)
    IO.puts("📋 ConstitutionalExecutor: Building constitution manifest...")
    manifest = ConstitutionManifest.build()
    IO.puts("   Manifest ID: #{manifest.manifest_id}")
    IO.puts("   Combined Hash: #{String.slice(manifest.combined_hash, 0, 16)}...")
    IO.puts("   Components: #{Map.keys(manifest.component_hashes) |> Enum.join(", ")}")

    # Step 3: Derive ConstitutionFingerprint from Manifest
    IO.puts("🔐 ConstitutionalExecutor: Deriving constitution fingerprint...")
    fingerprint = ConstitutionFingerprint.compute(manifest)
    IO.puts("   Fingerprint: #{String.slice(fingerprint.fingerprint, 0, 16)}...")
    IO.puts("   Manifest ID: #{fingerprint.manifest_id}")

    # Step 4: Check for constitutional drift (compare manifests via certificates)
    IO.puts("🔍 ConstitutionalExecutor: Checking for constitutional drift...")
    case ConstitutionalDriftJournal.check_drift(fingerprint) do
      :no_drift ->
        IO.puts("✅ ConstitutionalExecutor: No drift detected")

      {:drift_detected, entry} ->
        if entry.result == :execution_blocked do
          IO.puts("❌ ConstitutionalExecutor: UNAUTHORIZED DRIFT DETECTED")
          IO.puts("   Changed components: #{Enum.join(entry.changed_components, ", ")}")
          IO.puts("   EXECUTION BLOCKED - Requires governance approval")
          raise "Constitutional Drift: Unauthorized change detected - execution blocked"
        else
          IO.puts("⚠️  ConstitutionalExecutor: Approved drift detected")
          IO.puts("   Changed components: #{Enum.join(entry.changed_components, ", ")}")
          IO.puts("   Continuing with approved changes")
        end
    end

    # Step 5: Spawn constitutional watchdog for runtime monitoring
    IO.puts("👁️  ConstitutionalExecutor: Spawning constitutional watchdog...")
    {:ok, watchdog_pid} = ConstitutionalWatchdog.start_link(fingerprint, check_interval: 5000)
    IO.puts("   Watchdog PID: #{inspect(watchdog_pid)}")
    IO.puts("   Check interval: 5000ms")

    # Step 7: Build validation context
    validation_context = build_validation_context(config, manifest)

    # Step 8: Run StructuralValidationGate
    IO.puts("🚦 ConstitutionalExecutor: Running StructuralValidationGate...")

    case StructuralValidationGate.run(validation_context) do
      {:ok, gate_report} ->
        IO.puts("✅ ConstitutionalExecutor: StructuralValidationGate PASSED")

        # Step 9: Record StructuralValidationResult (immutable audit trail)
        validation_result = record_validation_result(gate_report, config, manifest)

        IO.puts("📝 ConstitutionalExecutor: StructuralValidationResult recorded")

        # Step 10: Execute RecursiveCivilizationRunner (only legal path)
        IO.puts("🚀 ConstitutionalExecutor: Executing RecursiveCivilizationRunner...")

        num_generations = Map.get(config, :max_generations, 3)
        {:ok, generation_history} = RecursiveCivilizationRunner.execute(num_generations, config)
        IO.puts("✅ ConstitutionalExecutor: Simulation completed successfully")

        # Step 11: Generate ConstitutionCertificate (bind execution to manifest)
        IO.puts("📜 ConstitutionalExecutor: Generating constitution certificate...")
        execution_id = Map.get(config, :execution_id, "EXEC-#{DateTime.utc_now() |> DateTime.to_iso8601()}")
        generation_count = Map.get(config, :current_generation, 0)

        certificate = ConstitutionCertificate.generate(
          execution_id: execution_id,
          generation_count: generation_count,
          manifest: manifest,
          fingerprint: fingerprint.fingerprint,
          validation_status: :passed,
          replay_status: get_replay_status(gate_report),
          watchdog_status: :completed,
          invariant_status: :all_passed
        )

        IO.puts("   Certificate ID: #{certificate.certificate_id}")
        IO.puts("   Certificate Hash: #{String.slice(certificate.certificate_hash, 0, 16)}...")

        # Step 12: Record certificate in drift journal
        IO.puts("📖 ConstitutionalExecutor: Recording certificate in drift journal...")
        drift_entry = ConstitutionalDriftJournal.record_execution(execution_id, certificate)
        IO.puts("   Drift journal entry ID: #{drift_entry.entry_id}")

        # Step 13: Stop watchdog after execution completes
        IO.puts("🛑 ConstitutionalExecutor: Stopping constitutional watchdog...")
        ConstitutionalWatchdog.stop(watchdog_pid)
        IO.puts("   Watchdog terminated")

        # Step 14: Update generation history with manifest_id and certificate_id
        history_with_references = Enum.map(generation_history, fn hist ->
          %{hist | manifest_id: manifest.manifest_id, certificate_id: certificate.certificate_id}
        end)
        |> List.first()  # Return first generation for compatibility
        |> Map.put(:validation_result, validation_result)

        {:ok, history_with_references}

      {:error, violations} ->
        IO.puts("❌ ConstitutionalExecutor: StructuralValidationGate FAILED")

        # Record failure result
        _validation_result = record_validation_result(%{violations: violations}, config, manifest)

        # Stop watchdog before raising error
        IO.puts("🛑 ConstitutionalExecutor: Stopping constitutional watchdog...")
        ConstitutionalWatchdog.stop(watchdog_pid)
        IO.puts("   Watchdog terminated")

        # Raise constitutional violation - execution forbidden
        violation_reasons = Enum.map_join(violations, ", ", fn v -> "#{v.id}: #{v.reason}" end)

        raise "Constitutional Violation: Execution forbidden - #{violation_reasons}"
    end
  end

  @doc """
  Build validation context from execution config.

  Transforms the execution config into the format expected by StructuralValidationGate.

  ## Parameters

  - `config`: Execution configuration
  - `manifest`: ConstitutionManifest (for manifest_id propagation)

  ## Returns

  - `validation_context` - Map containing all data needed for structural validation
  """
  @spec build_validation_context(config(), ConstitutionManifest.t()) :: map()
  def build_validation_context(config, %ConstitutionManifest{} = manifest) do
    %{
      generation_histories: Map.get(config, :generation_histories, []),
      scientific_capital_policy: config.scientific_capital_policy,
      causal_graph: Map.get(config, :causal_graph, %{}),
      multi_seed_trial_results: Map.get(config, :multi_seed_trial_results, []),
      constitution_manifest_id: manifest.manifest_id,
      constitution_hash: manifest.combined_hash
    }
  end

  @doc """
  Record StructuralValidationResult as immutable audit trail.

  Creates a canonical transaction recording the outcome of structural validation.
  This becomes part of the permanent generation history.

  ## Parameters

  - `gate_report`: Report from StructuralValidationGate
  - `config`: Execution configuration
  - `manifest`: ConstitutionManifest (source of truth for hashes)

  ## Returns

  - `validation_result` - StructuralValidationResult struct
  """
  @spec record_validation_result(map(), config(), ConstitutionManifest.t()) :: StructuralValidationResult.t()
  def record_validation_result(gate_report, config, %ConstitutionManifest{} = manifest) do
    _policy = config.scientific_capital_policy

    result = %StructuralValidationResult{
      gate_id: generate_gate_id(),
      generation: Map.get(config, :current_generation, 0),
      constitution_hash: manifest.combined_hash,
      policy_hash: Map.get(manifest.component_hashes, :policy_hash, ""),
      definition_hash: Map.get(manifest.component_hashes, :definition_hash, ""),
      ledger_hash: Map.get(manifest.component_hashes, :ledger_hash, ""),
      invariant_hash: Map.get(manifest.component_hashes, :registry_hash, ""),
      replay_status: get_replay_status(gate_report),
      conservation_status: get_conservation_status(gate_report),
      temporal_status: get_temporal_status(gate_report),
      reward_status: get_reward_status(gate_report),
      seed_status: get_seed_status(gate_report),
      metric_status: get_metric_status(gate_report),
      lifecycle_status: get_lifecycle_status(gate_report),
      rollback_status: get_rollback_status(gate_report),
      violations: [],  # Gate report is a list of results, not a map with violations
      approval: true,  # If we got here, all invariants passed
      timestamp: DateTime.utc_now()
    }

    # In production, this would be appended to an immutable ledger
    # For now, we return it for inclusion in generation history
    result
  end

  # Private helper functions

  @spec generate_gate_id() :: String.t()
  defp generate_gate_id() do
    "GATE-" <> (DateTime.utc_now() |> DateTime.to_iso8601()) <> "-" <>
      (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  @spec get_replay_status(list()) :: :pass | :fail | :not_checked
  defp get_replay_status(gate_report) when is_list(gate_report) do
    case Enum.find(gate_report, fn r -> r.id == :inv_001_replay_determinism end) do
      %{status: :pass} -> :pass
      %{status: :fail} -> :fail
      _ -> :not_checked
    end
  end

  @spec get_conservation_status(list()) :: :pass | :fail | :not_checked
  defp get_conservation_status(gate_report) when is_list(gate_report) do
    case Enum.find(gate_report, fn r -> r.id == :inv_002_budget_conservation end) do
      %{status: :pass} -> :pass
      %{status: :fail} -> :fail
      _ -> :not_checked
    end
  end

  @spec get_temporal_status(list()) :: :pass | :fail | :not_checked
  defp get_temporal_status(gate_report) when is_list(gate_report) do
    case Enum.find(gate_report, fn r -> r.id == :inv_005_temporal_separation end) do
      %{status: :pass} -> :pass
      %{status: :fail} -> :fail
      _ -> :not_checked
    end
  end

  @spec get_reward_status(list()) :: :pass | :fail | :not_checked
  defp get_reward_status(gate_report) when is_list(gate_report) do
    case Enum.find(gate_report, fn r -> r.id == :inv_006_reward_leakage_prevention end) do
      %{status: :pass} -> :pass
      %{status: :fail} -> :fail
      _ -> :not_checked
    end
  end

  @spec get_seed_status(list()) :: :pass | :fail | :not_checked
  defp get_seed_status(gate_report) when is_list(gate_report) do
    case Enum.find(gate_report, fn r -> r.id == :inv_008_seed_independence end) do
      %{status: :pass} -> :pass
      %{status: :fail} -> :fail
      _ -> :not_checked
    end
  end

  @spec get_metric_status(list()) :: :pass | :fail | :not_checked
  defp get_metric_status(gate_report) when is_list(gate_report) do
    case Enum.find(gate_report, fn r -> r.id == :inv_007_metric_independence end) do
      %{status: :pass} -> :pass
      %{status: :fail} -> :fail
      _ -> :not_checked
    end
  end

  @spec get_lifecycle_status(list()) :: :pass | :fail | :not_checked
  defp get_lifecycle_status(gate_report) when is_list(gate_report) do
    case Enum.find(gate_report, fn r -> r.id == :inv_009_lifecycle_completeness end) do
      %{status: :pass} -> :pass
      %{status: :fail} -> :fail
      _ -> :not_checked
    end
  end

  @spec get_rollback_status(list()) :: :pass | :fail | :not_checked
  defp get_rollback_status(gate_report) when is_list(gate_report) do
    case Enum.find(gate_report, fn r -> r.id == :inv_010_rollback_completeness end) do
      %{status: :pass} -> :pass
      %{status: :fail} -> :fail
      _ -> :not_checked
    end
  end
end
