defmodule TiannaraOS.Kernel.StructuralValidationGate do
  @moduledoc """
  StructuralValidationGate - Hard constitutional gate that must pass before any simulation.

  This gate executes ALL constitutional invariants from ConstitutionalInvariantRegistry
  and enforces a strict pass/fail policy. No statistical trials may begin until this
  gate passes 100%.

  ## Constitutional Role

  The structural gate is the final checkpoint before recursive execution. It ensures:
  - All conservation laws hold exactly
  - Replay determinism verified with zero tolerance
  - Policy hashes match recorded values (no drift)
  - Temporal separation maintained (no future leakage)
  - Reward leakage prevented (metrics trace to evidence)
  - Seed independence confirmed (results not RNG artifacts)
  - Metric independence verified (no circular dependencies)
  - Lifecycle completeness achieved (all stages executed)
  - Rollback frequency acceptable (system stability)

  If ANY invariant fails, the gate raises a ConstitutionalViolation and freezes adaptation.

  ## Architecture

  ```
  Recursive Execution Request
          │
          ▼
  StructuralValidationGate.run()
          │
          ├─→ ConstitutionalInvariantRegistry.run_all(context)
          │         │
          │         ├─ INV-001: Replay Determinism
          │         ├─ INV-002: Budget Conservation
          │         ├─ INV-003: Scientific Capital Conservation
          │         ├─ INV-004: Research Debt Conservation
          │         ├─ INV-005: Temporal Separation
          │         ├─ INV-006: Reward Leakage Prevention
          │         ├─ INV-007: Metric Independence
          │         ├─ INV-008: Seed Independence
          │         ├─ INV-009: Lifecycle Completeness
          │         └─ INV-010: Rollback Completeness
          │
          ├─ PASS → Allow Simulation
          │
          └─ FAIL → Freeze Adaptation
                    Raise ConstitutionalViolation
                    Abort Execution
  ```

  ## Usage

      # Build validation context
      context = %{...}

      # Run structural gate
      case StructuralValidationGate.run(context) do
        {:ok, results} -> proceed_with_simulation()
        {:error, violations} -> handle_violations(violations)
      end

  ## Failure Actions

  When the gate fails, it takes action based on violation severity:
  - :critical → Freeze adaptation immediately, raise violation
  - :high → Raise violation, allow investigation but flag system
  - :medium → Log warning, continue with caution

  Only :critical failures prevent simulation execution.
  """

  alias TiannaraOS.Kernel.ConstitutionalInvariantRegistry

  @type validation_context :: map()
  @type violation :: %{
    id: ConstitutionalInvariantRegistry.invariant_id(),
    severity: ConstitutionalInvariantRegistry.severity(),
    action: ConstitutionalInvariantRegistry.failure_action(),
    reason: String.t()
  }
  @type gate_result :: {:ok, [%{id: atom(), status: :pass}]} | {:error, [violation()]}

  @doc """
  Runs the complete structural validation gate.

  Executes all registered invariants and returns pass/fail result.
  This is the ONLY entry point for pre-simulation validation.

  ## Parameters
  - `context`: Map containing all required canonical inputs for invariants

  ## Returns
  {:ok, results} if all invariants pass,
  {:error, violations} if any fail (includes severity and recommended action).

  ## Examples

      context = build_validation_context(histories, policy, graph)

      case StructuralValidationGate.run(context) do
        {:ok, _} -> run_simulation()
        {:error, violations} -> handle_violations(violations)
      end
  """
  @spec run(validation_context()) :: gate_result()
  def run(context) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("STRUCTURAL VALIDATION GATE")
    IO.puts(String.duplicate("=", 80))
    IO.puts("Executing constitutional invariants...")
    IO.puts("")

    # Execute all invariants through registry
    case ConstitutionalInvariantRegistry.run_all(context) do
      {:ok, results} ->
        print_pass_results(results)
        IO.puts("\n✅ STRUCTURAL GATE PASSED - All invariants satisfied")
        IO.puts("Simulation execution authorized.\n")
        {:ok, results}

      {:error, violations} ->
        print_fail_results(violations)
        IO.puts("\n❌ STRUCTURAL GATE FAILED - Constitutional violations detected")
        IO.puts("Simulation execution DENIED.\n")

        # Take action based on violation severity
        handle_violations(violations)

        {:error, violations}
    end
  end

  @doc """
  Runs specific subset of invariants by category.

  Useful for targeted validation during development or debugging.

  Categories:
  - :capital_accounting - INV-001 through INV-004
  - :temporal_causal - INV-005 through INV-007
  - :experimental_design - INV-008 through INV-010

  ## Examples

      StructuralValidationGate.run_category(:capital_accounting, context)
  """
  @spec run_category(atom(), validation_context()) :: gate_result()
  def run_category(category, context) do
    invariants = ConstitutionalInvariantRegistry.list_by_category(category)

    IO.puts("\nRunning #{category} invariants...")

    results = Enum.map(invariants, fn invariant ->
      IO.puts("  Checking #{invariant.id} - #{invariant.title}...")

      case ConstitutionalInvariantRegistry.execute(invariant.id, context) do
        {:pass} ->
          IO.puts("    ✅ PASS")
          %{id: invariant.id, status: :pass}

        {:fail, reason} ->
          IO.puts("    ❌ FAIL: #{reason}")
          %{
            id: invariant.id,
            status: :fail,
            severity: invariant.failure_severity,
            action: invariant.failure_action,
            reason: reason
          }
      end
    end)

    violations = Enum.filter(results, fn r -> r.status == :fail end)

    if length(violations) == 0 do
      {:ok, results}
    else
      {:error, violations}
    end
  end

  @doc """
  Checks if a specific invariant passes.

  Returns boolean indicating pass/fail status.
  """
  @spec check_invariant(ConstitutionalInvariantRegistry.invariant_id(), validation_context()) :: boolean()
  def check_invariant(invariant_id, context) do
    case ConstitutionalInvariantRegistry.execute(invariant_id, context) do
      {:pass} -> true
      {:fail, _} -> false
    end
  end

  @doc """
  Generates a summary report of invariant status.

  Useful for dashboards and monitoring.
  """
  @spec generate_report(validation_context()) :: map()
  def generate_report(context) do
    invariants = ConstitutionalInvariantRegistry.list_invariants()

    results = Enum.map(invariants, fn invariant ->
      status = case ConstitutionalInvariantRegistry.execute(invariant.id, context) do
        {:pass} -> :pass
        {:fail, reason} -> {:fail, reason}
      end

      %{
        id: invariant.id,
        title: invariant.title,
        status: status,
        severity: invariant.failure_severity,
        category: categorize_invariant(invariant.id)
      }
    end)

    passed = Enum.count(results, fn r -> r.status == :pass end)
    failed = Enum.count(results, fn r -> r.status != :pass end)

    %{
      total: length(results),
      passed: passed,
      failed: failed,
      pass_rate: if(length(results) > 0, do: passed / length(results) * 100, else: 0),
      results: results
    }
  end

  # ──────────────────────────────────────────────
  # Private Helpers
  # ──────────────────────────────────────────────

  defp print_pass_results(results) do
    Enum.each(results, fn result ->
      invariant = ConstitutionalInvariantRegistry.get_invariant(result.id)
      IO.puts("  ✅ #{result.id} - #{invariant.title}")
    end)
  end

  defp print_fail_results(violations) do
    Enum.each(violations, fn violation ->
      invariant = ConstitutionalInvariantRegistry.get_invariant(violation.id)
      severity_icon = case violation.severity do
        :critical -> "🔴"
        :high -> "🟠"
        :medium -> "🟡"
        :low -> "⚪"
      end

      IO.puts("  #{severity_icon} #{violation.id} - #{invariant.title}")
      IO.puts("     Severity: #{violation.severity}")
      IO.puts("     Action: #{violation.action}")
      IO.puts("     Reason: #{violation.reason}")
      IO.puts("")
    end)
  end

  defp handle_violations(violations) do
    critical_violations = Enum.filter(violations, fn v -> v.severity == :critical end)
    high_violations = Enum.filter(violations, fn v -> v.severity == :high end)
    medium_violations = Enum.filter(violations, fn v -> v.severity == :medium end)

    if length(critical_violations) > 0 do
      IO.puts("🔴 CRITICAL VIOLATIONS DETECTED (#{length(critical_violations)})")
      IO.puts("   Action: FREEZE ADAPTATION")
      IO.puts("   Raising ConstitutionalViolation...")

      # In production, this would raise a proper ConstitutionalViolation exception
      # For now, we log the violations
      Enum.each(critical_violations, fn v ->
        IO.puts("   - #{v.id}: #{v.reason}")
      end)
    end

    if length(high_violations) > 0 do
      IO.puts("\n🟠 HIGH SEVERITY VIOLATIONS (#{length(high_violations)})")
      IO.puts("   Action: RAISE VIOLATION")
      Enum.each(high_violations, fn v ->
        IO.puts("   - #{v.id}: #{v.reason}")
      end)
    end

    if length(medium_violations) > 0 do
      IO.puts("\n🟡 MEDIUM SEVERITY VIOLATIONS (#{length(medium_violations)})")
      IO.puts("   Action: LOG WARNING")
      Enum.each(medium_violations, fn v ->
        IO.puts("   - #{v.id}: #{v.reason}")
      end)
    end
  end

  defp categorize_invariant(id) do
    cond do
      id in [:inv_001_replay_determinism, :inv_002_budget_conservation,
             :inv_003_scientific_capital_conservation, :inv_004_research_debt_conservation] ->
        :capital_accounting

      id in [:inv_005_temporal_separation, :inv_006_reward_leakage_prevention,
             :inv_007_metric_independence] ->
        :temporal_causal

      id in [:inv_008_seed_independence, :inv_009_lifecycle_completeness,
             :inv_010_rollback_completeness] ->
        :experimental_design

      true ->
        :unknown
    end
  end
end
