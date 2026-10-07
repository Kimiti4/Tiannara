defmodule Tiannara.HAI.ReviewRouterTest do
  use ExUnit.Case, async: false

  alias Tiannara.HAI.ReviewRouter
  alias Tiannara.HAI.Domain.ReviewRequest

  setup do
    pid = Process.whereis(ReviewRouter)
    assert is_pid(pid), "ReviewRouter must be started by the application"
    :ok
  end

  describe "submit_review/1" do
    test "accepts a low-impact review and auto-approves" do
      {:ok, request} = ReviewRouter.submit_review(%{
        source_subsystem: :discovery_engine, decision_type: :hypothesis_ranking,
        summary: "Test low impact", impact_level: :low, confidence: 0.9,
        uncertainty: 0.1, evidence_summary: "None needed", alternatives: [],
        recommendation: :proceed
      })

      assert request.status == :approved
      refute ReviewRequest.mandatory_review?(request)
    end

    test "routes high-impact review to pending" do
      {:ok, request} = ReviewRouter.submit_review(%{
        source_subsystem: :discovery_engine, decision_type: :experiment_design,
        summary: "Test high impact", impact_level: :high, confidence: 0.7,
        uncertainty: 0.3, evidence_summary: "Requires review", alternatives: [],
        recommendation: :proceed
      })

      assert request.status == :pending
      assert ReviewRequest.mandatory_review?(request)
    end

    test "routes critical-impact review to pending" do
      {:ok, request} = ReviewRouter.submit_review(%{
        source_subsystem: :engineering_synthesis, decision_type: :design_approval,
        summary: "Test critical impact", impact_level: :critical, confidence: 0.6,
        uncertainty: 0.4, evidence_summary: "Critical review required",
        alternatives: [], recommendation: :proceed_with_caution
      })

      assert request.status == :pending
      assert ReviewRequest.mandatory_review?(request)
    end

    test "routes civilizational-impact review to pending" do
      {:ok, request} = ReviewRouter.submit_review(%{
        source_subsystem: :simulation_engine, decision_type: :deployment_decision,
        summary: "Test civilizational impact", impact_level: :civilizational,
        confidence: 0.5, uncertainty: 0.5, evidence_summary: "Highest scrutiny",
        alternatives: [], recommendation: :require_human_decision
      })

      assert request.status == :pending
      assert ReviewRequest.mandatory_review?(request)
    end
  end

  describe "record_decision/3" do
    test "records human approval decision" do
      {:ok, request} = ReviewRouter.submit_review(%{
        source_subsystem: :test, decision_type: :test, summary: "Test",
        impact_level: :high, confidence: 0.7, uncertainty: 0.3,
        evidence_summary: "Test", alternatives: [], recommendation: :proceed
      })

      assert :ok = ReviewRouter.record_decision(request.id, :approved, "Looks good")
      [updated] = ReviewRouter.reviews_by_status(:approved)
      assert updated.id == request.id
      assert updated.human_decision == :approved
      assert updated.human_rationale == "Looks good"
    end

    test "records human rejection decision" do
      {:ok, request} = ReviewRouter.submit_review(%{
        source_subsystem: :test, decision_type: :test, summary: "Test",
        impact_level: :high, confidence: 0.7, uncertainty: 0.3,
        evidence_summary: "Test", alternatives: [], recommendation: :proceed
      })

      assert :ok = ReviewRouter.record_decision(request.id, :rejected, "Insufficient evidence")
      [updated] = ReviewRouter.reviews_by_status(:rejected)
      assert updated.human_decision == :rejected
      assert updated.human_rationale == "Insufficient evidence"
    end

    test "returns error for unknown review id" do
      assert {:error, :not_found} = ReviewRouter.record_decision("nonexistent", :approved, "N/A")
    end
  end

  describe "pending_reviews/0" do
    test "returns only pending reviews" do
      ReviewRouter.submit_review(%{source_subsystem: :a, decision_type: :a,
        summary: "A", impact_level: :low, confidence: 0.9, uncertainty: 0.1,
        evidence_summary: "A", alternatives: [], recommendation: :proceed})

      {:ok, req} = ReviewRouter.submit_review(%{source_subsystem: :b, decision_type: :b,
        summary: "B", impact_level: :high, confidence: 0.7, uncertainty: 0.3,
        evidence_summary: "B", alternatives: [], recommendation: :proceed})

      ReviewRouter.record_decision(req.id, :approved, "OK")
      pending = ReviewRouter.pending_reviews()
      assert Enum.all?(pending, &(&1.status == :pending))
    end
  end

  describe "stats/0" do
    test "returns accurate statistics" do
      {:ok, r1} = ReviewRouter.submit_review(%{source_subsystem: :a, decision_type: :a,
        summary: "A", impact_level: :high, confidence: 0.7, uncertainty: 0.3,
        evidence_summary: "A", alternatives: [], recommendation: :proceed})
      {:ok, r2} = ReviewRouter.submit_review(%{source_subsystem: :b, decision_type: :b,
        summary: "B", impact_level: :low, confidence: 0.9, uncertainty: 0.1,
        evidence_summary: "B", alternatives: [], recommendation: :proceed})

      ReviewRouter.record_decision(r1.id, :approved, "OK")

      stats = ReviewRouter.stats()
      assert stats.healthy == true
      assert stats.total_submitted == 2
      assert stats.total_approved == 1
      assert stats.mandatory_count == 1
      assert stats.pending_count == 0
    end
  end
end
