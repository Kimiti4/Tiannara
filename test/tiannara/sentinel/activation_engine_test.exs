defmodule Tiannara.Sentinel.ActivationEngineTest do
  use ExUnit.Case, async: false

  alias Tiannara.Sentinel.Activation.{
    Event, Intelligence, Causal, Recommendation,
    Dialogue, CRAVController, Approval, Memory, Engine
  }

  describe "Event creation" do
    test "creates event from raw observation" do
      event = Event.new(%{
        source: :rea,
        category: :scientific,
        severity: :warning,
        observation: "Genome diversity decreased 40%",
        confidence: 0.82
      })

      assert event.id != nil
      assert event.source == :rea
      assert event.category == :scientific
      assert event.severity == :warning
      assert event.observation == "Genome diversity decreased 40%"
      assert event.confidence == 0.82
      assert event.requires_human == false
    end

    test "critical events require human by default" do
      event = Event.new(%{
        source: :constitution,
        category: :constitutional,
        severity: :critical,
        observation: "Constitutional integrity check failed"
      })

      assert event.requires_human == true
    end
  end

  describe "Intelligence scoring" do
    test "filters low-confidence runtime info as noise" do
      event = Event.new(%{
        source: :runtime,
        category: :runtime,
        severity: :info,
        observation: "CPU fluctuation 5%",
        confidence: 0.3
      })

      result = Intelligence.evaluate(event)
      assert result.importance == 0.0
      assert result.priority == :ignore
    end

    test "high-severity events get high priority" do
      event = Event.new(%{
        source: :rea,
        category: :scientific,
        severity: :critical,
        observation: "Critical diversity collapse",
        confidence: 0.9
      })

      result = Intelligence.evaluate(event)
      assert result.priority == :high
      assert result.importance > 0.5
    end
  end

  describe "Causal interpretation" do
    test "returns interpretation even with minimal data" do
      event = Event.new(%{
        source: :rea,
        category: :scientific,
        severity: :warning,
        observation: "Genome convergence detected"
      })

      interpreted = Causal.interpret(event)
      assert interpreted.interpretation != nil
      assert interpreted.confidence != nil
    end
  end

  describe "Recommendation generation" do
    test "generates recommendations for scientific events" do
      event = Event.new(%{
        source: :rea,
        category: :scientific,
        severity: :warning,
        observation: "Diversity decline",
        confidence: 0.82
      })

      recs = Recommendation.generate(event)
      assert length(recs) > 0
      assert Enum.all?(recs, fn r -> r.action != nil end)
      assert Enum.all?(recs, fn r -> r.rollback_plan != nil end)
      assert Enum.all?(recs, fn r -> r.validation_method != nil end)
    end

    test "all recommendations have risk, gain, confidence" do
      event = Event.new(%{
        source: :rea,
        category: :scientific,
        severity: :info,
        observation: "Routine observation"
      })

      recs = Recommendation.generate(event)
      Enum.each(recs, fn r ->
        assert is_number(r.expected_gain)
        assert is_number(r.risk)
        assert is_number(r.confidence)
      end)
    end
  end

  describe "CRAV triggering" do
    test "constitutional critical triggers full suite" do
      event = Event.new(%{
        source: :constitution,
        category: :constitutional,
        severity: :critical,
        observation: "Constitutional violation"
      })

      assert {:triggered, "full_constitutional"} = CRAVController.maybe_trigger(event)
    end

    test "scientific novel discovery triggers certification" do
      event = Event.new(%{
        source: :rea,
        category: :scientific,
        severity: :info,
        observation: "Novel architecture found",
        metadata: %{novel_discovery: true}
      })

      assert {:triggered, "discovery_certification"} = CRAVController.maybe_trigger(event)
    end

    test "routine events do not trigger CRAV" do
      event = Event.new(%{
        source: :runtime,
        category: :runtime,
        severity: :info,
        observation: "Normal operation"
      })

      assert :ok = CRAVController.maybe_trigger(event)
    end
  end

  describe "Approval gateway" do
    test "creates proposal with risk assessment" do
      event = Event.new(%{
        source: :rea,
        category: :scientific,
        severity: :warning,
        observation: "Diversity decline"
      })

      recommendation = %{
        action: "Run diversity simulation",
        expected_gain: 0.18,
        risk: 0.05,
        confidence: 0.8,
        rollback_plan: "Revert simulation",
        validation_method: "Compare metrics"
      }

      proposal = Approval.propose(event, recommendation)
      assert proposal.proposal_id != nil
      assert proposal.risk_score == 0.05
      assert proposal.expected_benefit == 0.18
      assert proposal.status == :pending
    end
  end

  describe "Engine process" do
    setup do
      pid = Process.whereis(Engine)
      assert is_pid(pid), "Activation.Engine must be started by the application"
      :ok
    end

    test "processes observation through full pipeline" do
      result = Engine.process(%{
        source: :rea,
        category: :scientific,
        severity: :warning,
        observation: "Diversity decline detected",
        confidence: 0.82
      })

      assert result.event != nil
      assert result.event.interpretation != nil
      assert result.importance > 0
      assert result.priority != :ignore
      assert length(result.recommendations) > 0
      assert result.proposal != nil
    end

    test "filters noise observations" do
      result = Engine.process(%{
        source: :runtime,
        category: :runtime,
        severity: :info,
        observation: "Minor fluctuation",
        confidence: 0.2
      })

      assert result.priority == :ignore
      assert result.importance == 0.0
      assert result.recommendations == []
    end
  end

  describe "Dialogue formatting" do
    test "generates readable message from event" do
      event = Event.new(%{
        source: :rea,
        category: :scientific,
        severity: :warning,
        observation: "Genome diversity decreased 40%",
        interpretation: "Possible evolutionary monoculture",
        confidence: 0.82
      })

      recs = [%{
        action: "Run diversity recovery simulation",
        expected_gain: 0.18,
        risk: 0.05
      }]

      assert :ok = Dialogue.initiate(event, recs)
    end
  end

  describe "Memory integration" do
    test "records outcome without error" do
      event = Event.new(%{
        id: "test-event-1",
        timestamp: DateTime.utc_now(),
        source: :rea,
        category: :scientific,
        severity: :info,
        observation: "Test observation",
        interpretation: "Test interpretation",
        confidence: 0.8
      })

      outcome = %{action: "Test action", result: :success}
      assert :ok = Memory.record_outcome(event, outcome, :success)
    end
  end
end
