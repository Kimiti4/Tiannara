defmodule Tiannara.Council.HumanApprovalResumeTest do
  @moduledoc """
  R1/Batch 1 step 4 (F-GOV-004, F-GOV-017): a human approval must actually
  authorise the decision it approved.

  Before this change the approval queue recorded the approval and nothing
  else: the parked decision was never re-evaluated, so every decision that
  required human review stayed parked forever, and the privileged operations
  that depend on it (`CEL.Kernel.restart_service/2`, `CEL.Kernel.halt/2`)
  were unreachable.

  The suite pins three properties:
  1. a decision that requires human review is parked and identifies its
     request;
  2. after a human approves that exact decision, the decision is re-evaluated
     and the result is an authorised one - the approval record alone is never
     treated as the authorisation;
  3. an approval for one decision does not authorise a different decision.
  """

  use ExUnit.Case, async: false

  alias Tiannara.Council
  alias Tiannara.Council.{Authorization, HumanApprovalQueue}

  @decision_type :architectural_change

  # A payload the architectural_change policy matches (it applies to
  # :architectural_change) and that is compliant enough to be approved once a
  # human has granted it.
  #
  # The queue is a long-lived process, so each test uses its own payload: an
  # approval is bound to the exact decision the human saw, and a shared
  # payload would let one test's approval leak into the next.
  defp decision_payload(tag) do
    %{
      actor: :r1_batch1_operator,
      case_tag: tag,
      evidence: [%{source: :r1_batch1}, %{source: :r1_batch1_2}, %{source: :r1_batch1_3}],
      evidence_count: 3,
      confidence: 0.8,
      transparency_level: :full,
      explanation_provided: :detailed,
      risk_assessment: 0.1,
      preserves_human_authority: true,
      coherent_with_mission: true,
      degradation_handled: true,
      fairness_assessed: true,
      includes_feedback_loop: true
    }
  end

  defp await_resume(request_id, retries \\ 50) do
    Enum.reduce_while(1..retries, nil, fn _attempt, _acc ->
      case HumanApprovalQueue.get(request_id) do
        %{resumed_decision: %Authorization{} = auth} -> {:halt, auth}
        _ -> Process.sleep(20) && {:cont, nil}
      end
    end)
  end

  describe "F-GOV-004 — the approval effect exists" do
    test "a decision that requires human review is parked and names its request" do
      auth = Council.authorize(@decision_type, decision_payload(:park), nil)

      assert auth.decision == :requires_human
      assert auth.required_human_review
      assert is_binary(auth.metadata.request_id)
      refute Authorization.permitted?(auth)
    end

    test "an approval re-evaluates the parked decision into an authorised one" do
      parked = Council.authorize(@decision_type, decision_payload(:resume), nil)
      request_id = parked.metadata.request_id

      assert :ok = HumanApprovalQueue.approve(request_id, :r1_batch1_operator, "approved under test")

      resumed = await_resume(request_id)

      assert %Authorization{} = resumed,
             "the approval must produce a re-evaluated decision, not just a record"

      assert resumed.decision == :approved
      assert Authorization.permitted?(resumed)
    end

    test "the recorded decision is bound to the approved request" do
      parked = Council.authorize(@decision_type, decision_payload(:bound), nil)
      request_id = parked.metadata.request_id

      :ok = HumanApprovalQueue.approve(request_id, :r1_batch1_operator, "approved under test")

      resumed = await_resume(request_id)
      request = HumanApprovalQueue.get(request_id)

      assert request.status == :approved
      assert request.decided_by == :r1_batch1_operator
      assert request.resumed_decision.decision == resumed.decision
    end

    test "after the approval, the same decision is authorised directly" do
      parked = Council.authorize(@decision_type, decision_payload(:after_approval), nil)
      request_id = parked.metadata.request_id

      :ok = HumanApprovalQueue.approve(request_id, :r1_batch1_operator, "approved under test")
      assert %Authorization{} = await_resume(request_id)

      # The grant applies to the decision the human saw, so the same decision
      # is now authorised without a second approval.
      after_approval = Council.authorize(@decision_type, decision_payload(:after_approval), nil)

      assert after_approval.decision == :approved
      assert Authorization.permitted?(after_approval)
    end

    test "an approval does not authorise a different decision" do
      parked = Council.authorize(@decision_type, decision_payload(:different_park), nil)
      request_id = parked.metadata.request_id

      :ok = HumanApprovalQueue.approve(request_id, :r1_batch1_operator, "approved under test")
      assert %Authorization{} = await_resume(request_id)

      # A different payload for the same decision type is a different
      # decision and must still be parked.
      other = Council.authorize(@decision_type, Map.put(decision_payload(:different), :service, :other_service), nil)

      assert other.decision == :requires_human
      refute Authorization.permitted?(other)
    end

    test "a rejection leaves the decision parked and unauthorised" do
      parked = Council.authorize(@decision_type, decision_payload(:rejection), nil)
      request_id = parked.metadata.request_id

      assert :ok = HumanApprovalQueue.reject(request_id, :r1_batch1_operator, "refused under test")

      after_rejection = Council.authorize(@decision_type, decision_payload(:rejection), nil)

      assert after_rejection.decision == :requires_human
      refute Authorization.permitted?(after_rejection)
    end
  end
end
