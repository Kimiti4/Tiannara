defmodule Tiannara.Evolution.ConstitutionalAuditor do
  @spec audit(map()) :: map()
  def audit(system_state) when is_map(system_state) do
    checks = [
      check_verification_pace(system_state),
      check_uncertainty_visibility(system_state),
      check_human_judgment(system_state),
      check_lineage_integrity(system_state),
      check_safety_constraints(system_state),
      check_optimization_alignment(system_state),
      check_modularity(system_state),
      check_evolution_validation_balance(system_state)
    ]

    passed = Enum.count(checks, & &1.passed)
    total = length(checks)

    %{
      audit_id: "audit_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
      checks: checks,
      passed: passed,
      total: total,
      compliance_rate: if(total > 0, do: passed / total, else: 0.0),
      status: if(passed == total, do: :compliant, else: :non_compliant),
      critical_violations: Enum.filter(checks, fn c -> not c.passed and c.severity == :critical end),
      recommendations: generate_recommendations(checks),
      audited_at: DateTime.utc_now()
    }
  end

  @spec compliant?(map()) :: boolean()
  def compliant?(system_state) do
    audit = audit(system_state)
    audit.status == :compliant
  end

  defp check_verification_pace(state) do
    capabilities = Map.get(state, :capabilities_deployed, 0)
    verifications = Map.get(state, :verifications_completed, 0)

    ratio = if capabilities > 0, do: verifications / capabilities, else: 1.0
    passed = ratio >= 0.8

    %{
      principle: "Capability must never outpace verification",
      passed: passed,
      severity: if(passed, do: :info, else: :critical),
      metric: ratio,
      detail: "#{verifications} verifications for #{capabilities} capabilities (ratio: #{Float.round(ratio, 2)})"
    }
  end

  defp check_uncertainty_visibility(state) do
    hidden_uncertainty = Map.get(state, :hidden_uncertainty_count, 0)
    passed = hidden_uncertainty == 0

    %{
      principle: "Uncertainty should never be hidden",
      passed: passed,
      severity: if(passed, do: :info, else: :high),
      metric: hidden_uncertainty,
      detail: "#{hidden_uncertainty} instances of hidden uncertainty detected"
    }
  end

  defp check_human_judgment(state) do
    mandatory_reviews = Map.get(state, :mandatory_reviews_completed, 0)
    mandatory_required = Map.get(state, :mandatory_reviews_required, 0)

    passed = mandatory_required == 0 or mandatory_reviews >= mandatory_required

    %{
      principle: "Humans remain the final authority for high-impact decisions",
      passed: passed,
      severity: if(passed, do: :info, else: :critical),
      metric: if(mandatory_required > 0, do: mandatory_reviews / mandatory_required, else: 1.0),
      detail: "#{mandatory_reviews}/#{mandatory_required} mandatory reviews completed"
    }
  end

  defp check_lineage_integrity(state) do
    lineage_violations = Map.get(state, :lineage_violations, 0)
    passed = lineage_violations == 0

    %{
      principle: "Every architectural decision should remain traceable",
      passed: passed,
      severity: if(passed, do: :info, else: :high),
      metric: lineage_violations,
      detail: "#{lineage_violations} lineage integrity violations"
    }
  end

  defp check_safety_constraints(state) do
    safety_violations = Map.get(state, :safety_violations, 0)
    passed = safety_violations == 0

    %{
      principle: "Preserve previous stable states. Recover gracefully.",
      passed: passed,
      severity: if(passed, do: :info, else: :critical),
      metric: safety_violations,
      detail: "#{safety_violations} safety constraint violations"
    }
  end

  defp check_optimization_alignment(state) do
    objective_alignment = Map.get(state, :objective_alignment_score, 1.0)
    passed = objective_alignment >= 0.7

    %{
      principle: "Optimize for decades rather than product cycles",
      passed: passed,
      severity: if(passed, do: :info, else: :medium),
      metric: objective_alignment,
      detail: "Objective alignment score: #{Float.round(objective_alignment, 2)}"
    }
  end

  defp check_modularity(state) do
    coupling_violations = Map.get(state, :coupling_violations, 0)
    passed = coupling_violations == 0

    %{
      principle: "Prefer many specialized components cooperating through well-defined interfaces",
      passed: passed,
      severity: if(passed, do: :info, else: :medium),
      metric: coupling_violations,
      detail: "#{coupling_violations} modularity violations"
    }
  end

  defp check_evolution_validation_balance(state) do
    evolutions = Map.get(state, :evolutions_deployed, 0)
    validations = Map.get(state, :evolution_validations, 0)

    ratio = if evolutions > 0, do: validations / evolutions, else: 1.0
    passed = ratio >= 0.9

    %{
      principle: "Evolution without validation creates randomness. Validation without evolution creates stagnation.",
      passed: passed,
      severity: if(passed, do: :info, else: :high),
      metric: ratio,
      detail: "#{validations} validations for #{evolutions} evolutions (ratio: #{Float.round(ratio, 2)})"
    }
  end

  defp generate_recommendations(checks) do
    checks
    |> Enum.reject(& &1.passed)
    |> Enum.map(fn check ->
      %{
        principle: check.principle,
        severity: check.severity,
        action: recommend_action(check)
      }
    end)
  end

  defp recommend_action(%{principle: "Capability must never outpace verification"}) do
    "Halt new capability deployment until verification catches up"
  end

  defp recommend_action(%{principle: "Uncertainty should never be hidden"}) do
    "Audit all components for hidden uncertainty; add explicit uncertainty fields"
  end

  defp recommend_action(%{principle: "Humans remain the final authority for high-impact decisions"}) do
    "Block all high-impact decisions until mandatory human reviews are completed"
  end

  defp recommend_action(_) do
    "Investigate and remediate the violation"
  end
end
