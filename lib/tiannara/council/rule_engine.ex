defmodule Tiannara.Council.RuleEngine do
  @moduledoc """
  Constitutional Rule Engine — pure functional orchestrator of principle plugins.

  Delegates principle evaluation to the dynamic PrincipleRegistry when available,
  falling back to hardcoded assessments for backward compatibility.
  Always checks 3 hard invariants autonomously.
  """

  alias Tiannara.Council.{Authorization, PrincipleRegistry, ExecutionContext}

  @hard_invariants [:human_final_authority, :no_self_amendment, :audit_log_immutability]

  # Verdict thresholds for the built-in assessment.
  #
  # The built-in scorer used to report only :neutral and :violated, so the
  # compliance score could never exceed 0.70 and the :approved verdict was
  # unreachable for any real caller decision type (F-GOV-006). A principle
  # that is scored highly is now reported as :strengthened, which is the
  # information the raw score already carried.
  @strengthened_threshold 0.9
  @neutral_threshold 0.5

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

    compliance = compute_compliance_score(all_results, violated != [])
    confidence = compute_confidence(all_results, payload, plugin_results)

    decision = determine_decision(violated, all_results, confidence, compliance)

    evidence =
      Enum.map(all_results, fn r ->
        %{
          principle: r.principle_id,
          verdict: r.verdict,
          reasoning: r.reasoning,
          weight: r.weight,
          evidence: r.evidence
        }
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
      conditions: build_conditions(decision, all_results),
      metadata: %{
        assessments_count: length(all_results),
        violations_count: length(violated),
        hard_violations_count: length(hard_violations),
        strengthened_count: length(strengthened),
        decision_type: decision_type
      }
    }
  end

  @doc """
  Returns the hard invariants this decision would violate.

  Hard invariants are the constitutional checks that no policy, plugin or
  payload may override. Callers that must not be overruled by a policy action
  (for example the Council authorization path) consult this before trusting an
  approval.
  """
  @spec hard_invariant_violations(atom(), map()) :: [atom()]
  def hard_invariant_violations(decision_type, payload \\ %{}) do
    check_hard_invariants(decision_type, payload)
    |> Enum.map(& &1.principle_id)
  end

  defp build_conditions(:conditional, results) do
    Enum.map(results, fn r ->
      %{concern: r.principle_id, evidence_check: r.principle_id}
    end)
  end

  defp build_conditions(_decision, _results), do: []

  defp safe_plugin_evaluate(decision_type, payload, context) do
    case Process.whereis(PrincipleRegistry) do
      nil ->
        assess_principles(decision_type, payload)

      _pid ->
        case PrincipleRegistry.evaluate_all(decision_type, payload, context) do
          # Fail closed: an empty plugin set is not evidence that every
          # principle is satisfied. Without this guard, starting the registry
          # without registering any principle would score every decision 1.0
          # and approve it - the misleading success the authority decision
          # (D-ARC-011) warns about.
          [] ->
            assess_principles(decision_type, payload)

          results when is_list(results) ->
            # The plugin results AUGMENT the built-in assessment; they never
            # replace it. The registry pre-registers two plugin principles
            # whose declared weight is 1.0 each, so a replacement semantics
            # would drop the eleven built-in constitutional checks - including
            # :evidence_based - and a decision with no evidence would report
            # no violated principle at all. Augmentation keeps the coverage
            # intact. How the plugin weights should be scaled against the
            # built-in weights is an open decision (D-ARC-012).
            assess_principles(decision_type, payload) ++ results

          _ ->
            assess_principles(decision_type, payload)
        end
    end
  rescue
    _ -> assess_principles(decision_type, payload)
  end

  defp assess_principles(decision_type, payload) do
    [
      score_plugin_principle(
        :human_final_authority,
        "Human Final Authority",
        decision_type,
        payload
      ),
      score_plugin_principle(:transparency, "Transparency", decision_type, payload),
      score_plugin_principle(:explainability, "Explainability", decision_type, payload),
      score_plugin_principle(:evidence_based, "Evidence Based", decision_type, payload),
      score_plugin_principle(:fairness, "Fairness", decision_type, payload),
      score_plugin_principle(:accountability, "Accountability", decision_type, payload),
      score_plugin_principle(:safety, "Safety", decision_type, payload),
      score_plugin_principle(:sustainability, "Sustainability", decision_type, payload),
      score_plugin_principle(
        :continuous_improvement,
        "Continuous Improvement",
        decision_type,
        payload
      ),
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
      verdict:
        cond do
          score >= @strengthened_threshold -> :strengthened
          score >= @neutral_threshold -> :neutral
          true -> :violated
        end,
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
      :full -> 1.0
      :partial -> 0.6
      :none -> 0.0
      nil -> 0.8
    end
  end

  defp score_principle(:explainability, _type, payload) do
    case Map.get(payload, :explanation_provided) do
      :detailed -> 1.0
      :summary -> 0.6
      :none -> 0.0
      nil -> 0.7
    end
  end

  defp score_principle(:evidence_based, _type, payload) do
    ev = Map.get(payload, :evidence, [])

    cond do
      length(ev) >= 3 -> 1.0
      length(ev) >= 1 -> 0.6
      true -> 0.2
    end
  end

  defp score_principle(:fairness, _type, payload),
    do: if(Map.get(payload, :fairness_assessed, false), do: 1.0, else: 0.5)

  defp score_principle(:accountability, _type, payload),
    do: if(Map.get(payload, :actor) != nil, do: 1.0, else: 0.3)

  defp score_principle(:safety, _type, payload), do: 1.0 - Map.get(payload, :risk_assessment, 0.0)

  defp score_principle(:sustainability, _type, payload),
    do: max(0.0, 1.0 - Map.get(payload, :resource_cost, 0.0) / 100_000)

  defp score_principle(:continuous_improvement, _type, payload),
    do: if(Map.get(payload, :includes_feedback_loop, false), do: 1.0, else: 0.5)

  defp score_principle(:coherence, _type, payload),
    do: if(Map.get(payload, :coherent_with_mission, true), do: 1.0, else: 0.3)

  defp score_principle(:resilience, _type, payload),
    do: if(Map.get(payload, :degradation_handled, true), do: 1.0, else: 0.4)

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
    [
      if(Map.get(payload, :preserves_human_authority, true),
        do: "Human authority preserved",
        else: "WARNING: Human authority bypassed"
      )
    ]
  end

  defp build_evidence_simple(:transparency, _type, payload) do
    case Map.get(payload, :transparency_level) do
      :full -> ["Full transparency"]
      :partial -> ["Partial transparency"]
      :none -> ["No transparency"]
      nil -> ["Transparency not specified"]
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

  defp invariant_violated?(:human_final_authority, _type, payload),
    do: Map.get(payload, :bypasses_human_authority, false)

  defp invariant_violated?(:no_self_amendment, type, _payload),
    do: type == :constitutional_amendment

  defp invariant_violated?(:audit_log_immutability, _type, payload),
    do: Map.get(payload, :modifies_audit_log, false)

  defp has_hard_violation?(violations), do: length(violations) > 0

  # The compliance score.
  #
  # When a principle was violated, the score is computed on the baseline
  # reading (a satisfied-but-not-strong principle counts as 0.7), which is the
  # score the scorer produced before the :strengthened verdict existed. A
  # decision that broke a principle therefore keeps exactly the verdict it had
  # before, and the strengthened reading only ever applies to a decision with
  # no violation at all. Without this, a decision that violates a principle
  # would be lifted across the :conditional threshold by the uplift of the
  # principles it did satisfy.
  defp compute_compliance_score(results, baseline_only? \\ false) do
    total_w = Enum.reduce(results, 0.0, &(&1.weight + &2))

    weighted =
      Enum.reduce(results, 0.0, fn r, acc ->
        score =
          case r.verdict do
            :strengthened -> if baseline_only?, do: 0.7, else: 1.0
            :neutral -> 0.7
            :violated -> 0.0
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
    has_hard =
      Enum.any?(results, fn r -> r.principle_id in @hard_invariants and r.verdict == :violated end)

    cond do
      has_hard ->
        :rejected

      # An approval requires that no principle was violated: a decision that
      # broke a principle may not be approved, whatever the score says.
      #
      # The verdict taxonomy below is deliberately unchanged. Routing a
      # violated decision to :requires_human is tempting, but until the
      # human-approval resume path exists (F-GOV-004) such a decision would be
      # parked with no way to resume - the same dead end the backlog records.
      # A violating decision is refused by both authorisation gates instead:
      # the structural precondition (no violated principles) fails, so it can
      # never become a machine grant.
      violated == [] and compliance >= 0.8 and confidence >= 0.7 ->
        :approved

      compliance >= 0.6 ->
        :conditional

      compliance >= 0.4 ->
        :requires_human

      true ->
        :rejected
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
