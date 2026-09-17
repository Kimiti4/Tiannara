defmodule Tiannara.Communication.CommunicationTest do
  use ExUnit.Case, async: true

  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Communication.{Director, DedupLedger}

  @moduletag :omega3_communication

  test "constitutional concern always reaches human awareness" do
    e = EpistemicEvent.new(:constitutional_concern, severity: :low, payload: %{x: 1}, confidence: 0.1)
    d = Director.decide(e, %{significance_threshold: 0.99})
    assert d.notify
    assert d.urgency == :critical
  end

  test "low-significance informational event is suppressed" do
    e = EpistemicEvent.new(:knowledge_updated, severity: :low, payload: %{y: 2}, confidence: 0.2)
    d = Director.decide(e, %{significance_threshold: 0.4})
    refute d.notify
    assert d.suppress_reason == :below_significance_threshold
  end

  test "duplicate notification is suppressed (anti-spam)" do
    e = EpistemicEvent.new(:anomaly_detected, severity: :high, payload: %{z: 3}, confidence: 0.8)
    d1 = Director.decide(e, %{significance_threshold: 0.4})
    assert d1.notify

    ledger = DedupLedger.record(DedupLedger.new(), d1.dedup_key)
    d2 = Director.decide(e, %{significance_threshold: 0.4, ledger: ledger})
    refute d2.notify
    assert d2.suppress_reason == :already_notified
    assert d2.already_notified
  end

  test "decision carries evidence, uncertainty, and recommended action" do
    e =
      EpistemicEvent.new(:system_degradation,
        severity: :critical, payload: %{sub: :memory}, confidence: 0.9,
        evidence: [:m1], uncertainty: "sensor may drift")

    d = Director.decide(e, %{})
    assert d.evidence == [:m1]
    assert d.uncertainty == "sensor may drift"
    assert d.recommended_action != nil
    assert d.category == :actionable
  end
end