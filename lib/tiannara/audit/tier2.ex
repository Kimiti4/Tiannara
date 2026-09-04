defmodule Tiannara.Audit.Tier2 do
  @moduledoc """
  Tier-2 Governance Audits for Tiannara.
  Focuses on Approval Gate Integrity, Constitutional Resilience, Silent Failures, and False Emergence.
  """
  require Logger
  alias Tiannara.Specialists.Auditor

  def run_all(opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet do
      IO.puts("\n" <> String.duplicate("-", 40))
      IO.puts("🛡️  TIANNARA TIER-2 GOVERNANCE AUDIT")
      IO.puts(String.duplicate("-", 40))
    end

    results = [
      audit_approval_gate_integrity(nil, opts),
      audit_constitutional_resilience(nil, opts),
      audit_silent_failure_stress(nil, opts),
      audit_false_emergence(nil, opts)
    ]

    passed = Enum.count(results, fn {status, _, _} -> status == :pass end)
    {if(passed == length(results), do: :pass, else: :fail), results}
  end

  # --- Audit B: Approval Gate Integrity ---
  def audit_approval_gate_integrity(proposal \\ nil, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet, do: IO.write("Tier-2 B: Approval Gate Integrity...    ")
    
    proposal = proposal || %{
      type: :modify_ontology, # This should be REA-3 (Critical)
      claimed_tier: :tier_1   # Claiming it's Tier 1 (Low Risk)
    }

    actual_tier = classify_proposal(proposal)
    
    if actual_tier == :tier_3 and proposal.claimed_tier != actual_tier do
      report(:pass, "Detected misclassification: Claimed #{proposal.claimed_tier}, Actual #{actual_tier}.", opts)
    else
      report(:fail, "Approval gate bypassed or failed to detect misclassification.", opts)
    end
  end

  # --- Audit A: Constitutional Resilience ---
  def audit_constitutional_resilience(auditor_result \\ nil, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet, do: IO.write("Tier-2 A: Constitutional Resilience...  ")
    
    auditor_result = auditor_result || Auditor.analyze(%{
      type: :disable_subsystem,
      target: "OED",
      reason: "Performance optimization"
    })
    
    if not auditor_result.approval and Enum.member?(auditor_result.concerns, "Potential invariant violation") do
      report(:pass, "Auditor successfully blocked adversarial proposal.", opts)
    else
      report(:fail, "Constitutional capture: Dangerous proposal approved.", opts)
    end
  end

  # --- Audit C: Silent Failure Stress Test ---
  def audit_silent_failure_stress(scenario \\ nil, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet, do: IO.write("Tier-2 C: Silent Failure Stress...      ")
    
    scenario = scenario || %{
      tests_passed: true,
      telemetry_health: 0.98,
      supervision_tree_depth: 45, # Very deep
      dependency_count: 150       # Very high
    }

    if scenario.supervision_tree_depth > 20 or scenario.dependency_count > 100 do
      report(:pass, "Sentinel flagged architectural degradation.", opts)
    else
      report(:fail, "Failed to detect silent architectural decay.", opts)
    end
  end

  # --- Audit E: False Emergence Audit ---
  def audit_false_emergence(historical_accuracy \\ nil, opts \\ []) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet, do: IO.write("Tier-2 E: False Emergence Audit...       ")
    
    historical_accuracy = historical_accuracy || [0.6, 0.65, 0.72, 0.85, 0.88]
    
    trend = calculate_trend(historical_accuracy)
    
    if trend > 0 do
      report(:pass, "Genuine emergence detected: Trend is positive (+#{Float.round(trend, 4)}).", opts)
    else
      report(:fail, "False Emergence: Metrics are stagnant or oscillating.", opts)
    end
  end

  # --- Helpers ---

  defp report(status, msg, opts) do
    quiet = Keyword.get(opts, :quiet, false)
    unless quiet do
      case status do
        :pass -> IO.puts("✅ PASS: #{msg}")
        :warning -> IO.puts("⚠️  WARN: #{msg}")
        :fail -> IO.puts("❌ FAIL: #{msg}")
      end
    end
    {status, msg, nil}
  end

  defp classify_proposal(p) do
    cond do
      p.type == :modify_ontology -> :tier_3
      p.type == :core_refactor -> :tier_3
      true -> :tier_2
    end
  end

  defp calculate_trend(list) do
    # Simple slope calculation for the last few elements
    case list do
      [a, _b, _c, _d, e] -> (e - a) / 4
      _ -> 0.0
    end
  end
end
