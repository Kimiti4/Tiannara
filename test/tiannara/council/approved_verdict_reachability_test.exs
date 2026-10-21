defmodule Tiannara.Council.ApprovedVerdictReachabilityTest do
  @moduledoc """
  R1/Batch 1 step 2 (F-GOV-006 / F-GOV-023): a compliant decision must be able
  to reach an approved verdict through the production path, and the dormant
  plugin path must not be able to manufacture an approval.

  Before this change the built-in assessment could only report :neutral and
  :violated, so the compliance score was capped at 0.70, the approval
  threshold of 0.80 was unreachable, and every decision the Council produced
  was :conditional, :requires_human or :rejected.

  The authority determination (HC-2) this suite relies on:
  - the Council path exists only in the root Elixir project, so the root
    application owns the constitutional authorization path;
  - `Tiannara.Council.PrincipleRegistry` is the registry the rule engine
    aliases, and it is started by no supervisor;
  - `TiannaraOS.PrincipleRegistry` is a different module in a different
    namespace with no Council consumer, so it is not part of this path.

  The suite also pins the fail-closed guard: with the registry started but
  holding no principles, the rule engine must keep using the built-in
  assessment instead of treating "no plugin evidence" as "all satisfied".
  """

  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.{Authorization, PrincipleRegistry, RuleEngine}

  @decision_type :r1_batch1_approval_probe

  # A decision that is compliant on every built-in principle: human authority
  # preserved, full transparency, a detailed explanation, three pieces of
  # evidence, an accountable actor, low risk, and calibrated confidence.
  defp compliant_payload do
    %{
      actor: :r1_batch1,
      evidence: [%{source: :r1_batch1}, %{source: :r1_batch1_2}, %{source: :r1_batch1_3}],
      evidence_count: 3,
      confidence: 0.8,
      transparency_level: :full,
      explanation_provided: :detailed,
      risk_assessment: 0.1,
      resource_cost: 100,
      preserves_human_authority: true,
      coherent_with_mission: true,
      degradation_handled: true,
      includes_feedback_loop: true,
      fairness_assessed: true
    }
  end

  describe "F-GOV-006 — an approved verdict is reachable" do
    test "a compliant decision is approved through the Council production path" do
      auth = Council.authorize(@decision_type, compliant_payload(), nil)

      assert auth.decision == :approved,
             "a compliant decision must be able to reach an approved verdict, got #{inspect(auth.decision)}"

      assert auth.constitutional_score >= 0.8
      assert auth.confidence >= 0.7
      assert auth.violated_principles == []
      assert Authorization.permitted?(auth)
    end

    test "the rule engine reports satisfied principles as strengthened" do
      decision = RuleEngine.evaluate(@decision_type, compliant_payload(), nil)

      assert decision.decision == :approved
      assert decision.metadata.assessments_count > 0

      strengthened =
        decision.evidence
        |> Enum.filter(&(&1.verdict == :strengthened))
        |> Enum.map(& &1.principle)

      assert :human_final_authority in strengthened
      assert :transparency in strengthened
    end
  end

  describe "the approval is not granted indiscriminately" do
    test "a decision with a violated principle is never approved" do
      decision = RuleEngine.evaluate(@decision_type, %{actor: :r1_batch1}, nil)

      refute decision.decision == :approved
      assert :evidence_based in decision.violated_principles

      # A decision that broke a principle must not become a grant either: the
      # structural precondition (no violated principles) fails, so neither
      # predicate authorises it.
      refute Authorization.permitted?(decision)
      refute Authorization.conditional_grant?(decision)
    end

    test "a decision awaiting human review is never approved" do
      auth = Council.authorize(:architectural_change, compliant_payload(), nil)

      refute auth.decision == :approved
      assert auth.decision == :requires_human
    end

    test "a decision that violates a hard invariant is rejected" do
      auth = Council.authorize(@decision_type, Map.put(compliant_payload(), :bypasses_human_authority, true), nil)

      assert auth.decision == :rejected
      refute Authorization.permitted?(auth)
    end
  end

  describe "F-GOV-023 — the dormant plugin path cannot manufacture an approval" do
    test "an empty principle registry falls back to the built-in assessment" do
      start_supervised!(PrincipleRegistry)

      decision = RuleEngine.evaluate(@decision_type, %{actor: :r1_batch1}, nil)

      refute decision.decision == :approved,
             "an empty plugin set must not be treated as 'every principle satisfied'"

      assert decision.constitutional_score < 1.0
      assert decision.metadata.assessments_count > 0
      assert :evidence_based in decision.violated_principles
    end

    test "a started but empty registry does not turn a weak decision into an approval" do
      start_supervised!(PrincipleRegistry)

      decision = RuleEngine.evaluate(@decision_type, %{actor: :r1_batch1}, nil)

      refute Authorization.permitted?(decision)
    end
  end
end
