defmodule Tiannara.Contradiction.EngineTest do
  use ExUnit.Case, async: true

  alias Tiannara.Contradiction.{Engine, Record}

  @moduletag :contradiction_engine

  defp seeded_claims do
    [
      %{subject: :x, value: 10, evidence: [:obs_a], timestamp: 1, source: :sensor_a},
      %{subject: :x, value: 20, evidence: [:obs_b], timestamp: 1, source: :sensor_b}
    ]
  end

  test "detects the seeded value contradiction" do
    contradictions = Engine.detect(seeded_claims())

    assert length(contradictions) == 1
    [c] = contradictions

    assert c.type == :value_conflict
    assert c.severity == :high
    assert c.claim_a.value == 10
    assert c.claim_b.value == 20
    assert c.resolution_status == :detected
    assert c.affected_knowledge == [:x]
  end

  test "does not report a contradiction when values agree" do
    claims = [
      %{subject: :y, value: 5, evidence: [:o1], timestamp: 1, source: :s1},
      %{subject: :y, value: 5, evidence: [:o2], timestamp: 1, source: :s2}
    ]

    assert Engine.detect(claims) == []
  end

  test "classifies temporal conflicts when timestamps differ" do
    claims = [
      %{subject: :z, value: 1, evidence: [:o1], timestamp: 1, source: :s1},
      %{subject: :z, value: 2, evidence: [:o2], timestamp: 9, source: :s2}
    ]

    [c] = Engine.detect(claims)
    assert c.type == :temporal_conflict
    assert c.severity == :medium
  end

  test "confidence grows with supporting evidence" do
    sparse = [
      %{subject: :x, value: 10, evidence: [], timestamp: 1, source: :a},
      %{subject: :x, value: 20, evidence: [], timestamp: 1, source: :b}
    ]

    rich = [
      %{subject: :x, value: 10, evidence: [:e1, :e2], timestamp: 1, source: :a},
      %{subject: :x, value: 20, evidence: [:e3, :e4], timestamp: 1, source: :b}
    ]

    [sparse_c] = Engine.detect(sparse)
    [rich_c] = Engine.detect(rich)

    assert rich_c.confidence > sparse_c.confidence
  end

  test "emits a contradiction_detected epistemic event" do
    [c] = Engine.detect(seeded_claims())
    event = Engine.to_epistemic_event(c)

    assert event.type == :contradiction_detected
    assert event.payload.contradiction_id == c.id
    assert event.evidence != []
  end

  test "full resolution lifecycle is legal and traced" do
    [c] = Engine.detect(seeded_claims())

    {:ok, c} = Engine.advance(c, :investigating)
    assert c.resolution_status == :investigating

    {:ok, c} = Engine.advance(c, :experiment_proposed)
    {:ok, c} = Engine.advance(c, :experiment_running)

    {:ok, c} =
      Engine.resolve(c, %{
        winning_claim: :claim_a,
        explanation: "sensor B had a systematic +10 offset"
      })

    assert c.resolution_status == :resolved
    assert c.resolution.winning_claim == :claim_a
    assert :resolved in c.lineage
  end

  test "rejects illegal lifecycle transitions" do
    [c] = Engine.detect(seeded_claims())

    assert {:error, {:illegal_transition, :detected, :resolved}} =
             Engine.advance(c, :resolved)

    assert {:error, {:cannot_resolve_from, :detected}} =
             Engine.resolve(c, %{winning_claim: :claim_a})
  end

  test "a contradiction can be dismissed without an experiment" do
    [c] = Engine.detect(seeded_claims())

    {:ok, c} = Engine.advance(c, :investigating)
    {:ok, c} = Engine.advance(c, :dismissed)

    assert c.resolution_status == :dismissed
  end
end