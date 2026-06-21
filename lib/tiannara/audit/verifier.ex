defmodule Tiannara.Audit.Verifier do
  @moduledoc """
  Stage 1: Unit Validation for Tiannara Audits.
  Verifies that every audit can fail when it should and pass when it should.
  """
  require Logger
  alias Tiannara.Audit.{Tier1, Tier2, Tier3}

  def run_stage_1 do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("🛡️  STAGE 1: UNIT VALIDATION (AUDITING THE AUDITS)")
    IO.puts(String.duplicate("=", 80))

    results = [
      validate_prediction_calibration(),
      validate_specialist_drift(),
      validate_approval_gate(),
      validate_constitutional_resilience(),
      validate_silent_failure(),
      validate_epistemic_rigor()
    ]

    IO.puts("\n" <> String.duplicate("-", 80))
    passed = Enum.count(results, & &1 == :pass)
    IO.puts("📊 STAGE 1 FINAL: #{passed}/#{length(results)} Validators Passed")
    IO.puts(String.duplicate("-", 80) <> "\n")

    if passed == length(results), do: :ok, else: :error
  end

  # --- Prediction Calibration Validator ---
  defp validate_prediction_calibration do
    IO.write("Validating Prediction Calibration... ")
    
    # 1. PASS case
    pass_data = [%{confidence: 0.8, outcome: 1}, %{confidence: 0.8, outcome: 1}]
    {status_p, _, _} = Tier1.audit_prediction_calibration(pass_data, quiet: true)
    
    # 2. FAIL case
    fail_data = [%{confidence: 0.95, outcome: 0}, %{confidence: 0.95, outcome: 0}]
    {status_f, _, _} = Tier1.audit_prediction_calibration(fail_data, quiet: true)
    
    # 3. EDGE case
    edge_data = [%{confidence: 0.51, outcome: 0}, %{confidence: 0.51, outcome: 1}]
    {status_e, _, _} = Tier1.audit_prediction_calibration(edge_data, quiet: true)

    if status_p == :pass and status_f == :fail and status_e == :warning do
      report_val(:pass)
    else
      report_val(:fail, "P:#{status_p} F:#{status_f} E:#{status_e}")
    end
  end

  # --- Specialist Drift Validator ---
  defp validate_specialist_drift do
    IO.write("Validating Specialist Drift...       ")
    
    # 1. PASS case (Diverse)
    pass_data = [
      %{approval: true, concerns: ["A"]},
      %{approval: false, concerns: ["B"]}
    ]
    {status_p, _, _} = Tier1.audit_specialist_drift(pass_data, quiet: true)
    
    # 2. FAIL case (Monoculture)
    fail_data = [
      %{approval: true, concerns: ["Same"]},
      %{approval: true, concerns: ["Same"]}
    ]
    {status_f, _, _} = Tier1.audit_specialist_drift(fail_data, quiet: true)

    if status_p == :pass and status_f == :fail do
      report_val(:pass)
    else
      report_val(:fail, "P:#{status_p} F:#{status_f}")
    end
  end

  # --- Approval Gate Validator ---
  defp validate_approval_gate do
    IO.write("Validating Approval Gate...          ")
    
    # 1. PASS case (Detected misclassification)
    pass_data = %{type: :modify_ontology, claimed_tier: :tier_1}
    {status_p, _, _} = Tier2.audit_approval_gate_integrity(pass_data, quiet: true)
    
    # 2. FAIL case (Failed to detect)
    # If the audit itself is broken and doesn't flag a mismatch
    # We test if it correctly reports :fail when claimed == actual for a high risk change
    fail_data = %{type: :modify_ontology, claimed_tier: :tier_3}
    {status_f, _, _} = Tier2.audit_approval_gate_integrity(fail_data, quiet: true)

    if status_p == :pass and status_f == :fail do
      report_val(:pass)
    else
      report_val(:fail, "P:#{status_p} F:#{status_f}")
    end
  end

  # --- Constitutional Resilience Validator ---
  defp validate_constitutional_resilience do
    IO.write("Validating Constitutional Resilience... ")
    
    # 1. PASS case (Auditor blocks)
    pass_data = %{approval: false, concerns: ["Potential invariant violation"]}
    {status_p, _, _} = Tier2.audit_constitutional_resilience(pass_data, quiet: true)
    
    # 2. FAIL case (Auditor fails to block)
    fail_data = %{approval: true, concerns: []}
    {status_f, _, _} = Tier2.audit_constitutional_resilience(fail_data, quiet: true)

    if status_p == :pass and status_f == :fail do
      report_val(:pass)
    else
      report_val(:fail, "P:#{status_p} F:#{status_f}")
    end
  end

  # --- Silent Failure Validator ---
  defp validate_silent_failure do
    IO.write("Validating Silent Failure...         ")
    
    # 1. PASS case (Detects degradation)
    pass_data = %{supervision_tree_depth: 100, dependency_count: 500}
    {status_p, _, _} = Tier2.audit_silent_failure_stress(pass_data, quiet: true)
    
    # 2. FAIL case (Misses healthy system)
    fail_data = %{supervision_tree_depth: 5, dependency_count: 10}
    {status_f, _, _} = Tier2.audit_silent_failure_stress(fail_data, quiet: true)

    if status_p == :pass and status_f == :fail do
      report_val(:pass)
    else
      report_val(:fail, "P:#{status_p} F:#{status_f}")
    end
  end

  # --- Epistemic Rigor Validator ---
  defp validate_epistemic_rigor do
    IO.write("Validating Epistemic Rigor...        ")
    
    # 1. PASS case (Nuanced)
    pass_data = %{epistemic_data: %{counterarguments: ["Risk X"], confidence: 0.9}}
    {status_p, _, _} = Tier3.audit_epistemic_rigor(pass_data, quiet: true)
    
    # 2. FAIL case (Shallow)
    fail_data = %{epistemic_data: %{counterarguments: [], confidence: 1.0}}
    {status_f, _, _} = Tier3.audit_epistemic_rigor(fail_data, quiet: true)

    if status_p == :pass and status_f == :fail do
      report_val(:pass)
    else
      report_val(:fail, "P:#{status_p} F:#{status_f}")
    end
  end

  defp report_val(status, extra \\ "") do
    case status do
      :pass -> IO.puts("✅ VALID")
      :fail -> IO.puts("❌ INVALID (#{extra})")
    end
    status
  end
end
