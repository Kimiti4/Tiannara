defmodule TiannaraRuntime.WorldModel.AutonomousResearch.TheoryEvolutionRecordTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.WorldModel.AutonomousResearch.TheoryEvolutionRecord

  test "rejects a rejected theory update without a rejection reason" do
    assert {:error, reason} =
             TheoryEvolutionRecord.new(
               config_id: "cfg_1",
               theory_id: "theory_1",
               evidence_id: "evidence_1",
               pre_confidence: 0.7,
               post_confidence: 0.1,
               action: :rejected,
               rejection_reason: nil,
               evidence_support: 0.2,
               evidence_strength: 0.4,
               contradiction_detected: false,
               timestamp: "2026-09-22T00:00:00Z"
             )

    assert reason =~ "rejection_reason"
  end

  test "accepts a rejected theory update when the reason is explicit" do
    assert {:ok, record} =
             TheoryEvolutionRecord.new(
               config_id: "cfg_1",
               theory_id: "theory_1",
               evidence_id: "evidence_1",
               pre_confidence: 0.7,
               post_confidence: 0.1,
               action: :rejected,
               rejection_reason: "contradiction_detected",
               evidence_support: 0.2,
               evidence_strength: 0.4,
               contradiction_detected: true,
               timestamp: "2026-09-22T00:00:00Z"
             )

    assert record.record_id =~ "terc_"
    assert :ok = TheoryEvolutionRecord.verify_id(record)
  end

  test "rejects contradiction signals when the contradiction flag is false" do
    assert {:error, reason} =
             TheoryEvolutionRecord.new(
               config_id: "cfg_1",
               theory_id: "theory_1",
               evidence_id: "evidence_1",
               pre_confidence: 0.7,
               post_confidence: 0.1,
               action: :rejected,
               rejection_reason: "Evidence contradicts theory beyond recovery threshold",
               evidence_support: 0.2,
               evidence_strength: 0.4,
               contradiction_detected: false,
               timestamp: "2026-09-22T00:00:00Z"
             )

    assert reason =~ "contradiction_detected"
  end
end
