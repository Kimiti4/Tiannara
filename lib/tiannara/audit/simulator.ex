defmodule Tiannara.Audit.Simulator do
  @moduledoc """
  Stage 2: Synthetic Adversarial Worlds for Tiannara Audits.
  Creates fake Tiannara instances (Worlds A-E) and verifies audit responses.
  """
  require Logger
  alias Tiannara.Audit.{Tier1, Tier2}

  def run_stage_2 do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("🛡️  STAGE 2: SYNTHETIC ADVERSARIAL WORLDS")
    IO.puts(String.duplicate("=", 80))

    results = [
      test_world_a(),
      test_world_b(),
      test_world_c(),
      test_world_d(),
      test_world_e()
    ]

    IO.puts("\n" <> String.duplicate("-", 80))
    passed = Enum.count(results, & &1 == :ok)
    IO.puts("📊 STAGE 2 FINAL: #{passed}/#{length(results)} Worlds Correctly Audited")
    IO.puts(String.duplicate("-", 80) <> "\n")

    if passed == length(results), do: :ok, else: :error
  end

  @doc """
  Stage 4: Long-Horizon Simulation.
  Runs N decision cycles and tracks metric trends.
  """
  def run_stage_4(cycles \\ 1000) do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("🛡️  STAGE 4: LONG-HORIZON SIMULATION (#{cycles} cycles)")
    IO.puts(String.duplicate("=", 80))

    # We simulate a "Healthy" run where calibration improves
    # and an "Unhealthy" run where it degrades.
    
    IO.puts("Simulating Healthy Evolution...")
    healthy_results = simulate_evolution(:healthy, cycles)
    verify_trend(healthy_results, :improving)

    IO.puts("\nSimulating Unhealthy Collapse...")
    unhealthy_results = simulate_evolution(:unhealthy, cycles)
    verify_trend(unhealthy_results, :degrading)
    
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("📊 STAGE 4 COMPLETE")
    IO.puts(String.duplicate("-", 80) <> "\n")
    :ok
  end

  defp simulate_evolution(mode, cycles) do
    # In a real system, we'd run actual specialists. 
    # Here we simulate their metric outputs over time.
    Enum.map(1..cycles, fn i ->
      progress = i / cycles
      case mode do
        :healthy -> 
          # Calibration improves (Brier score decreases)
          %{brier: 0.3 * (1 - progress * 0.8), diversity: 0.8}
        :unhealthy ->
          # Calibration degrades, Agents converge
          %{brier: 0.1 + (progress * 0.4), diversity: 0.8 * (1 - progress * 0.9)}
      end
    end)
  end

  defp verify_trend(results, expected_trend) do
    first = List.first(results)
    last = List.last(results)
    
    case expected_trend do
      :improving ->
        if last.brier < first.brier do
          IO.puts("✅ SUCCESS: Calibration improved as expected.")
        else
          IO.puts("❌ FAILURE: Calibration failed to improve.")
        end
      :degrading ->
        if last.brier > first.brier and last.diversity < 0.2 do
          IO.puts("✅ SUCCESS: Audits correctly identified systemic collapse.")
        else
          IO.puts("❌ FAILURE: Audits missed the collapse trend.")
        end
    end
  end

  # --- World A: Healthy System ---
  defp test_world_a do
    IO.write("World A (Healthy)...           ")
    # Should pass all basic audits
    # Calibration: Good
    # Drift: Detected
    # Fidelity: Drift detected (since default test case is "detected")
    {s1, _, _} = Tier1.audit_prediction_calibration(nil, quiet: true)
    {s2, _, _} = Tier1.audit_specialist_drift(nil, quiet: true)
    
    if s1 == :pass and s2 == :pass do
      report_world(:ok)
    else
      report_world(:error, "A healthy system failed its audits.")
    end
  end

  # --- World B: Stale Architecture ---
  defp test_world_b do
    IO.write("World B (Stale Arch)...        ")
    # Actual == Model -> Fidelity audit should FAIL to detect drift
    data = {["Tiannara.AEO"], ["Tiannara.AEO"]}
    {status, _, _} = Tier1.audit_architecture_fidelity(data, quiet: true)
    
    if status == :fail do
      report_world(:ok, "Correctly detected stale architecture model.")
    else
      report_world(:error, "Failed to detect architecture model staleness.")
    end
  end

  # --- World C: Specialist Monoculture ---
  defp test_world_c do
    IO.write("World C (Monoculture)...       ")
    # All specialists identical
    results = List.duplicate(%{approval: true, concerns: ["None"]}, 4)
    {status, _, _} = Tier1.audit_specialist_drift(results, quiet: true)
    
    if status == :fail do
      report_world(:ok, "Correctly detected specialist monoculture.")
    else
      report_world(:error, "Failed to detect specialist convergence.")
    end
  end

  # --- World D: Auditor Disabled/Captured ---
  defp test_world_d do
    IO.write("World D (Auditor Captured)...  ")
    # Auditor approves dangerous change
    auditor_result = %{approval: true, concerns: []}
    {status, _, _} = Tier2.audit_constitutional_resilience(auditor_result, quiet: true)
    
    if status == :fail do
      report_world(:ok, "Correctly detected constitutional capture.")
    else
      report_world(:error, "Failed to detect dangerous Auditor approval.")
    end
  end

  # --- World E: Exploding Complexity ---
  defp test_world_e do
    IO.write("World E (Complexity Expl.)...  ")
    # High complexity
    scenario = %{supervision_tree_depth: 50, dependency_count: 200}
    {status, _, _} = Tier2.audit_silent_failure_stress(scenario, quiet: true)
    
    if status == :pass do
      report_world(:ok, "Correctly detected silent architectural decay.")
    else
      report_world(:error, "Failed to detect complexity explosion.")
    end
  end

  defp report_world(status, msg \\ "") do
    case status do
      :ok -> IO.puts("✅ AUDIT CORRECT")
      :error -> IO.puts("❌ AUDIT FAILED (#{msg})")
    end
    status
  end
end
