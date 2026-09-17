defmodule Tiannara.World.BeliefStateTest do
  use ExUnit.Case, async: true

  alias Tiannara.World.BeliefState

  describe "new/3" do
    test "creates a valid belief state with confidence + uncertainty = 1.0" do
      bs = BeliefState.new(0.5, 0.8, 0.9)
      assert abs(bs.confidence + bs.uncertainty - 1.0) < 0.001
      assert bs.evidence_count == 1
    end

    test "clamps values to [0.0, 1.0]" do
      bs = BeliefState.new(1.5, 1.2, 1.1)
      assert bs.confidence <= 1.0
      assert bs.uncertainty >= 0.0
    end
  end

  describe "update/3" do
    test "fuses new evidence and increases evidence count" do
      bs = BeliefState.new(0.5, 0.8, 0.9)
      bs2 = BeliefState.update(bs, 0.7, 0.8)
      assert bs2.evidence_count == 2
      assert length(bs2.revision_history) == 2
    end
  end

  describe "decay/2" do
    test "reduces confidence over time" do
      bs = BeliefState.new(0.9, 0.9, 0.9)
      bs2 = BeliefState.decay(bs, 30)
      assert bs2.confidence < bs.confidence
    end
  end

  describe "promotion_ready?/3" do
    test "returns true when thresholds are met" do
      bs = BeliefState.new(0.9, 0.9, 0.9)
      updated = BeliefState.update(bs, 0.9, 0.9)
      updated2 = BeliefState.update(updated, 0.9, 0.9)
      assert BeliefState.promotion_ready?(updated2, 0.8, 3)
    end

    test "returns false when confidence is too low" do
      bs = BeliefState.new(0.3, 0.3, 0.3)
      refute BeliefState.promotion_ready?(bs)
    end
  end

  describe "explain/1" do
    test "returns a formatted explanation" do
      bs = BeliefState.new(0.5, 0.8, 0.9)
      explanation = BeliefState.explain(bs)
      assert String.contains?(explanation, "Confidence:")
      assert String.contains?(explanation, "Evidence Count:")
    end
  end
end
