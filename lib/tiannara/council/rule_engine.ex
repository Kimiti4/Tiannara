defmodule Tiannara.Council.RuleEngine do
  @moduledoc """
  Constitutional Rule Engine — pure functional orchestrator of principle plugins.

  Delegates principle evaluation to the dynamic PrincipleRegistry when available,
  falling back to hardcoded assessments for backward compatibility.
  Always checks 3 hard invariants autonomously.
  """

  alias Tiannara.Council.{Authorization, PrincipleRegistry, ExecutionContext}

  @hard_invariants [:human_final_authority, :no_self_amendment, :audit_log_immutability]

  @doc """
  Evaluate a decision against constitutional principles.

  1. If PrincipleRegistry is running, delegates to plugin evaluations.
  2. Checks 3 hard invariants autonomously.
  3. Aggregates results into an Authorization struct.
  """
  @spec evaluate(atom(), map(), ExecutionContext.t() | nil) :: Authorization.t()
  def evaluate(decision_type, payload, context \\ nil) do
    plugin_results = safe_plugin_evaluate(decision_type, payload, context)
    hard_violations = check_hard_invariants(decision_type, payload)

    all_results = plugin_results ++ hard_violations

    violated =
      all_results
      |> Enum.filter(fn r -> r.verdict == :violated end)
      |> Enum.map(& &1.principle_id)

    strengthened =
      all_results
      |> Enum.filter(fn r -> r.verdict == :strengthened end)
      |> Enum.map(& &1.principle_id)

    compliance = compute_compliance_score(all_results)
    confidence = compute_confidence(all_results, payload, plugin_results)

    decision = determine_decision(violated, all_results, confidence, compliance)

    evidence =
      Enum.map(all_results, fn r ->
        %{principle: r.principle_id, verdict: r.verdict, reasoning: r.reasoning,
          weight: r.weight, evidence: r.evidence}
      end)

    %Authorization{
      decision: decision,
      confidence: confidence,
      constitutional_score: compliance,
      violated_principles: violated,
      required_human_review: has_hard_violation?(hard_violations),
      explanation: build_explanation(decision, violated, compliance),
      evidence: evidence,
      context: context,
      decided_at: DateTime.utc_now(),
      policy_applied: :rule_engine,
      metadata: %{
        assessments_count: length(all_results),
        violations_count: length(violated),
        hard_violations_count: length(hard_violations),
        strengthened_count: length(strengthened),
        decision_type: decision_type
      }
    }
  end

  defp safe_plugin_evaluate(decision_type, payload, context) do
    case Process.whereis(PrincipleRegistry) do
      nil ->
        assess_principles(decision_type, payload)

      _pid ->
        case PrincipleRegistry.evaluate_all(decision_type, payload, context) do
          results when is_list(results) -> results
          _ -> assess_principles(decision_type, payload)
        end
    end
  rescue
    _ -> assess_principles(decision_type, payload)
  end

  defp assess_principles(decision_type, payload) do
    [
      score_plugin_principle(:human_final_authority, "Human Final Authority", decision_type, payload),
      score_plugin_principle(:transparency, "Transparency", decision_type, payload),
      score_plugin_principle(:explainability, "Explainability", decision_type, payload),
      score_plugin_principle(:evidence_based, "Evidence Based", decision_type, payload),
      score_plugin_principle(:fairness, "Fairness", decision_type, payload),
      score_plugin_principle(:accountability, "Accountability", decision_type, payload),
      score_plugin_principle(:safety, "Safety", decision_type, payload),
      score_plugin_principle(:sustainability, "Sustainability", decision_type, payload),
      score_plugin_principle(:continuous_improvement, "Continuous Improvement", decision_type, payload),
      score_plugin_principle(:coherence, "Coherence", decision_type, payload),
      score_plugin_principle(:resilience, "Resilience", decision_type, payload)
    ]
  end

  defp score_plugin_principle(id, name, decision_type, payload) do
    score = score_principle(id, decision_type, payload)
    %{
      principle_id: id,
      principle_name: name,
      version: "built-in",
      verdict: if(score >= 0.5, do: :neutral, else: :violated),
      reasoning: "#{name} score: #{Float.round(score, 3)}",
      evidence: build_evidence_simple(id, decision_type, payload),
      weight: principle_weight(id)
    }
  end

  defp score_principle(:human_final_authority, _type, payload) do
    if Map.get(payload, :preserves_human_authority, true), do: 1.0, else: 0.0
  end

  defp score_principle(:transparency, _type, payload) do
    case Map.get(payload, :transparency_level) do
      :full -> 1.0; :partial -> 0.6; :none -> 0.0; nil -> 0.8
    end
  end

  defp score_principle(:explainability, _type, payload) do
    case Map.get(payload, :explanation_provided) do
      :detailed -> 1.0; :summary -> 0.6; :none -> 0.0; nil -> 0.7
    end
  end

  defp score_principle(:evidence_based, _type, payload) do
    ev = Map.get(payload, :evidence, [])
    cond do length(ev) >= 3 -> 1.0; length(ev) >= 1 -> 0.6; true -> 0.2 end
  end

  defp score_principle(:fairness, _type, payload), do: if(Map.get(payload, :fairness_assessed, false), do: 1.0, else: 0.5)
  defp score_principle(:accountability, _type, payload), do: if(Map.get(payload, :actor) != nil, do: 1.0, else: 0.3)
  defp score_principle(:safety, _type, payload), do: 1.0 - Map.get(payload, :risk_assessment, 0.0)
  defp score_principle(:sustainability, _type, payload), do: max(0.0, 1.0 - Map.get(payload, :resource_cost, 0.0) / 100_000)
  defp score_principle(:continuous_improvement, _type, payload), do: if(Map.get(payload, :includes_feedback_loop, false), do: 1.0, else: 0.5)
  defp score_principle(:coherence, _type, payload), do: if(Map.get(payload, :coherent_with_mission, true), do: 1.0, else: 0.3)
  defp score_principle(:resilience, _type, payload), do: if(Map.get(payload, :degradation_handled, true), do: 1.0, else: 0.4)

  defp principle_weight(:human_final_authority), do: 0.20
  defp principle_weight(:transparency), do: 0.10
  defp principle_weight(:explainability), do: 0.10
  defp principle_weight(:evidence_based), do: 0.15
  defp principle_weight(:fairness), do: 0.10
  defp principle_weight(:accountability), do: 0.10
  defp principle_weight(:safety), do: 0.10
  defp principle_weight(:sustainability), do: 0.05
  defp principle_weight(:continuous_improvement), do: 0.05
  defp principle_weight(:coherence), do: 0.03
  defp principle_weight(:resilience), do: 0.02

  defp build_evidence_simple(:human_final_authority, _type, payload) do
    [if(Map.get(payload, :preserves_human_authority, true), do: "Human authority preserved", else: "WARNING: Human authority bypassed")]
  end

  defp build_evidence_simple(:transparency, _type, payload) do
    case Map.get(payload, :transparency_level) do
      :full -> ["Full transparency"]; :partial -> ["Partial transparency"]; :none -> ["No transparency"]; nil -> ["Transparency not specified"]
    end
  end

  defp build_evidence_simple(principle, _type, payload) do
    key = String.to_atom("evidence_#{principle}")
    Map.get(payload, key, ["No specific evidence for #{principle}"])
  end

  defp check_hard_invariants(decision_type, payload) do
    @hard_invariants
    |> Enum.filter(fn inv -> invariant_violated?(inv, decision_type, payload) end)
    |> Enum.map(fn inv ->
      %{
        principle_id: inv,
        principle_name: Atom.to_string(inv),
        version: "hard-invariant",
        verdict: :violated,
        reasoning: "Hard invariant #{inv} would be violated",
        evidence: [%{type: :hard_invariant, value: inv}],
        weight: 1.0
      }
    end)
  end

  defp invariant_violated?(:human_final_authority, _type, payload), do: Map.get(payload, :bypasses_human_authority, false)
  defp invariant_violated?(:no_self_amendment, type, _payload), do: type == :constitutional_amendment
  defp invariant_violated?(:audit_log_immutability, _type, payload), do: Map.get(payload, :modifies_audit_log, false)

  defp has_hard_violation?(violations), do: length(violations) > 0

  defp compute_compliance_score(results) do
    total_w = Enum.reduce(results, 0.0, &(&1.weight + &2))
    weighted =
      Enum.reduce(results, 0.0, fn r, acc ->
        score = case r.verdict do
          :strengthened -> 1.0; :neutral -> 0.7; :violated -> 0.0
        end
        acc + score * r.weight
      end)
    if total_w > 0, do: weighted / total_w, else: 1.0
  end

  defp compute_confidence(plugin_results, payload, _all_results) do
    evidence_count = Map.get(payload, :evidence_count, 0)
    neutral_count = Enum.count(plugin_results, &(&1.verdict == :neutral))
    total = max(length(plugin_results), 1)
    assessed_ratio = (total - neutral_count) / total

    base = min(1.0, evidence_count / 5.0)
    min(1.0, 0.5 + 0.5 * (base * 0.6 + assessed_ratio * 0.4))
  end

  defp determine_decision(violated, results, confidence, compliance) do
    has_hard = Enum.any?(results, fn r -> r.principle_id in @hard_invariants and r.verdict == :violated end)
    cond do
      has_hard -> :rejected
      compliance >= 0.8 and confidence >= 0.7 -> :approved
      compliance >= 0.6 -> :conditional
      compliance >= 0.4 -> :requires_human
      true -> :rejected
    end
  end

  defp build_explanation(:approved, _violated, score) do
    "Constitutional compliance score #{Float.round(score, 3)}. All principles satisfied."
  end

  defp build_explanation(:conditional, violated, score) do
    "Compliance #{Float.round(score, 3)}. Conditional with concerns: #{Enum.join(violated, ", ")}"
  end

  defp build_explanation(:requires_human, violated, score) do
    "Compliance #{Float.round(score, 3)}. Human review required. Issues: #{Enum.join(violated, ", ")}"
  end

  defp build_explanation(:rejected, violated, score) do
    "REJECTED — compliance #{Float.round(score, 3)}. Violations: #{Enum.join(violated, ", ")}"
  end
end
