defmodule Tiannara.Autonomy.ProposalGeneratorTest do
  use ExUnit.Case, async: false

  alias Tiannara.Autonomy.ProposalGenerator

  defp sample_opportunity(opts \\ []) do
    %{
      id: "opp_#{System.unique_integer([:positive])}",
      category: opts[:category] || :performance,
      target: opts[:target] || :scheduler,
      description: "Test opportunity",
      evidence: [%{metric: "cpu"}],
      estimated_impact: opts[:impact] || 0.5,
      confidence: opts[:confidence] || 0.8,
      urgency: 0.5,
      identified_at: DateTime.utc_now()
    }
  end

  describe "generate" do
    test "transforms opportunities into proposals" do
      proposals = ProposalGenerator.generate([sample_opportunity()])
      assert length(proposals) == 1
      proposal = hd(proposals)
      assert proposal.id != nil
      assert proposal.title != nil
      assert proposal.objective != nil
      assert proposal.rationale != nil
      assert proposal.category == :performance
      assert proposal.target == :scheduler
      assert proposal.status == :draft
    end

    test "sets human_approval_required for high-risk proposals" do
      opp = sample_opportunity(impact: 0.95, category: :scalability)
      proposals = ProposalGenerator.generate([opp])
      assert hd(proposals).human_approval_required == true
    end

    test "low-risk proposals may not require human approval" do
      opp = sample_opportunity(impact: 0.3, confidence: 0.9, category: :performance)
      proposals = ProposalGenerator.generate([opp])
      assert hd(proposals).human_approval_required == false
    end

    test "handles multiple opportunities" do
      opps = for i <- 1..3, do: sample_opportunity(category: :"type_#{i}")
      proposals = ProposalGenerator.generate(opps)
      assert length(proposals) == 3
    end
  end

  describe "submit_manual" do
    test "creates proposal from manual input" do
      assert {:ok, id} = ProposalGenerator.submit_manual(%{
        title: "Manual optimization",
        objective: "Improve throughput",
        rationale: "Observed bottleneck",
        category: :performance, target: :scheduler
      })
      assert is_binary(id)
    end

    test "provides defaults for missing fields" do
      assert {:ok, _id} = ProposalGenerator.submit_manual(%{})
    end
  end

  describe "active_count" do
    test "counts draft/submitted/approved proposals" do
      before = ProposalGenerator.active_count()
      opp = sample_opportunity()
      ProposalGenerator.generate([opp])
      assert ProposalGenerator.active_count() == before + 1
    end
  end

  describe "status" do
    test "returns metrics" do
      status = ProposalGenerator.status()
      assert is_integer(status.total_proposals)
      assert is_integer(status.total_generated)
      assert is_integer(status.total_manual)
    end
  end
end
