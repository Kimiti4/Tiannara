defmodule Tiannara.Council.PolicyWildcardMatchingTest do
  @moduledoc """
  F-GOV-003: a policy that declares `applies_to: [:any]` must apply to every
  decision type.

  Before this suite the matcher tested `decision_type in policy.applies_to`
  literally, so the two wildcard policies - `high_risk` (risk above 0.8) and
  `invariant_protection` (touches an invariant) - never matched anything and
  were permanently dead: a high-risk decision reached the rule engine instead
  of the human review its policy description promises.

  This suite is a prerequisite for making an approval verdict reachable: if a
  high-risk decision can be auto-approved, the human-review policy that is
  supposed to intercept it has to be live first.
  """

  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.PolicyRegistry

  @decision_type :r1_batch1_wildcard_probe

  defp authorize(payload) do
    Council.authorize(@decision_type, payload, nil)
  end

  describe "F-GOV-003 — the :any wildcard is honoured" do
    test "a high-risk decision reaches the high_risk policy and is parked for human review" do
      auth = authorize(%{risk_assessment: 0.95, actor: :r1_batch1})

      refute auth.decision == :approved,
             "a high-risk decision must not be auto-approved while the high_risk policy is live"

      assert auth.decision == :requires_human
      assert auth.required_human_review
      assert auth.policy_applied == :high_risk
    end

    test "a decision that touches an invariant reaches the invariant_protection policy" do
      auth = authorize(%{touches_invariant: true, actor: :r1_batch1})

      assert auth.decision == :requires_human
      assert auth.required_human_review
      assert auth.policy_applied == :invariant_protection
    end

    test "a low-risk decision does not trigger the high_risk policy" do
      auth = authorize(%{risk_assessment: 0.2, actor: :r1_batch1})

      refute auth.policy_applied == :high_risk
      refute auth.policy_applied == :invariant_protection

      # The rule engine may still ask for human review on its own terms (this
      # payload carries no evidence, so its compliance score is low). What must
      # not happen is the *policy* path parking the decision: the policy-driven
      # park is what sets required_human_review, and no policy matched here.
      refute auth.required_human_review
    end

    test "a decision with no risk signal does not trigger the high_risk policy" do
      auth = authorize(%{actor: :r1_batch1})

      refute auth.policy_applied == :high_risk
    end
  end

  describe "the wildcard policies are no longer dead" do
    test "both wildcard policies are registered and enabled" do
      policies =
        PolicyRegistry.active_policies()
        |> Map.new(&{&1.id, &1})

      for id <- [:high_risk, :invariant_protection] do
        assert Map.has_key?(policies, id), "expected the #{id} policy to be registered"
        assert policies[id].enabled
        assert :any in policies[id].applies_to
      end
    end
  end
end
