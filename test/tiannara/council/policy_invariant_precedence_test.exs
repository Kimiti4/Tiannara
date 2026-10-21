defmodule Tiannara.Council.PolicyInvariantPrecedenceTest do
  @moduledoc """
  Batch 1 step 1 (F-GOV-007): a policy action must never override a hard
  constitutional invariant.

  Before this suite, a policy with `action: :approve` minted an `:approved`
  decision and `score_auth/3` only decorated it, so a decision that violated a
  hard invariant was returned as approved with the violation merely listed in
  `violated_principles`. The rule engine is now authoritative: an approval that
  rests on a violated hard invariant is withdrawn and the decision is rejected.

  The suite is deliberately written as denial-path tests first: the negative
  cases assert the defect cannot happen, and the positive control asserts that
  a legitimate policy approval is unaffected (so the fix cannot pass by simply
  refusing everything).
  """

  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.{Authorization, PolicyRegistry, RuleEngine}

  @decision_type :r1_batch1_policy_approval

  setup do
    policy_id = :"r1_batch1_approve_policy_#{System.unique_integer([:positive])}"
    amendment_policy_id = :"r1_batch1_amend_policy_#{System.unique_integer([:positive])}"

    :ok =
      PolicyRegistry.register_policy(%{
        id: policy_id,
        description: "Batch 1 probe: approves a decision type under test",
        applies_to: [@decision_type],
        conditions: [{:always}],
        action: :approve,
        priority: 1000,
        enabled: true
      })

    # :no_self_amendment is keyed on the decision type, so the bypassing policy
    # has to cover :constitutional_amendment itself. Priority 1000 outranks the
    # built-in :self_modification policy (110) so the :approve branch is the
    # one under test.
    :ok =
      PolicyRegistry.register_policy(%{
        id: amendment_policy_id,
        description: "Batch 1 probe: approves a constitutional amendment under test",
        applies_to: [:constitutional_amendment],
        conditions: [{:always}],
        action: :approve,
        priority: 1000,
        enabled: true
      })

    on_exit(fn ->
      PolicyRegistry.disable_policy(policy_id)
      PolicyRegistry.disable_policy(amendment_policy_id)
    end)

    %{policy_id: policy_id, amendment_policy_id: amendment_policy_id}
  end

  defp authorize(payload) do
    Council.authorize(@decision_type, payload, nil)
  end

  describe "F-GOV-007 — a policy approval cannot override a hard invariant" do
    test "bypassing human authority is rejected even when a policy approves" do
      auth = authorize(%{bypasses_human_authority: true, actor: :r1_batch1})

      refute auth.decision == :approved,
             "a policy action must not approve a decision that violates :human_final_authority"

      assert auth.decision == :rejected
      assert :human_final_authority in auth.violated_principles
      refute Authorization.permitted?(auth)
    end

    test "modifying the audit log is rejected even when a policy approves" do
      auth = authorize(%{modifies_audit_log: true, actor: :r1_batch1})

      refute auth.decision == :approved,
             "a policy action must not approve a decision that violates :audit_log_immutability"

      assert auth.decision == :rejected
      assert :audit_log_immutability in auth.violated_principles
      refute Authorization.permitted?(auth)
    end

    test "a constitutional amendment is rejected even when a policy approves" do
      auth = Council.authorize(:constitutional_amendment, %{actor: :r1_batch1}, nil)

      refute auth.decision == :approved,
             "a policy action must not approve a decision that violates :no_self_amendment"

      assert auth.decision == :rejected
      assert :no_self_amendment in auth.violated_principles
    end

    test "the withdrawn approval is recorded with the violating invariants" do
      auth = authorize(%{bypasses_human_authority: true, actor: :r1_batch1})

      assert auth.metadata[:overridden_by] == :hard_invariant
      assert auth.explanation =~ "Approval withdrawn by the constitutional rule engine"
      assert auth.explanation =~ "human_final_authority"
    end
  end

  describe "positive control — a legitimate policy approval is unaffected" do
    test "a compliant decision under an approving policy is still approved" do
      auth = authorize(%{actor: :r1_batch1, evidence: [%{source: :r1_batch1}]})

      assert auth.decision == :approved
      assert Authorization.permitted?(auth)
      refute auth.metadata[:overridden_by]
    end
  end

  describe "RuleEngine.hard_invariant_violations/2" do
    test "reports only the invariants the decision actually violates" do
      assert RuleEngine.hard_invariant_violations(:r1_batch1_probe, %{}) == []

      assert :human_final_authority in
               RuleEngine.hard_invariant_violations(:r1_batch1_probe, %{
                 bypasses_human_authority: true
               })

      assert :audit_log_immutability in
               RuleEngine.hard_invariant_violations(:r1_batch1_probe, %{
                 modifies_audit_log: true
               })

      assert :no_self_amendment in
               RuleEngine.hard_invariant_violations(:constitutional_amendment, %{})
    end
  end
end
