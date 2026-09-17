defmodule Tiannara.Discovery.DiscoveryTest do
  use ExUnit.Case, async: true
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Domain.KnowledgeGap
  alias Tiannara.Discovery.Domain.HypothesisSpec

  describe "from_gap/1" do
    test "creates discovery from gap" do
      gap = KnowledgeGap.new(domain: :test, description: "a test gap")
      disc = Discovery.from_gap(gap)
      assert disc.question == "What explains a test gap in the test domain?"
      assert disc.status == :question_formulated
      assert disc.confidence == 0.0
      assert disc.uncertainty == 1.0
    end
  end

  describe "transition/2" do
    test "valid transitions succeed" do
      gap = KnowledgeGap.new(domain: :test, description: "test")
      disc = Discovery.from_gap(gap)
      {:ok, disc} = Discovery.transition(disc, :gap_identified)
      assert disc.status == :gap_identified
      {:ok, disc} = Discovery.transition(disc, :hypotheses_generated)
      assert disc.status == :hypotheses_generated
    end

    test "invalid transition returns error" do
      gap = KnowledgeGap.new(domain: :test, description: "test")
      disc = Discovery.from_gap(gap)
      {:error, reason} = Discovery.transition(disc, :completed)
      assert reason == {:invalid_transition, :question_formulated, :completed}
    end
  end

  describe "add_hypotheses/2" do
    test "adds hypotheses and appends lineage" do
      gap = KnowledgeGap.new(domain: :test, description: "test")
      disc = Discovery.from_gap(gap)
      h1 = HypothesisSpec.new(gap_id: gap.id, description: "test hypothesis")
      disc = Discovery.add_hypotheses(disc, [h1])
      assert length(disc.hypotheses) == 1
    end
  end

  describe "complete/1" do
    test "marks discovery as completed" do
      gap = KnowledgeGap.new(domain: :test, description: "test")
      disc = Discovery.from_gap(gap)
      disc = Discovery.complete(disc)
      assert disc.status == :completed
      assert disc.completed_at != nil
    end
  end
end
