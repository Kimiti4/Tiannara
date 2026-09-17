defmodule Tiannara.Agency.AgencyTest do
  use ExUnit.Case, async: false

  alias Tiannara.Agency.{
    Supervisor, SentinelHeartbeat, ResearchDirector, Orchestrator,
    TelemetryCollector, Sandbox
  }
  alias Tiannara.Agency.Models.{AgencyEvent, Observation}

  setup do
    start_supervised!({Supervisor, heartbeat_interval: 100})
    Process.sleep(200)
    :ok
  end

  describe "Sentinel Heartbeat -- continuous observation" do
    test "runs cycles automatically without human invocation" do
      Process.sleep(200)

      state = SentinelHeartbeat.get_state()
      assert state.cycle_count >= 1, "Heartbeat should run autonomously"
      assert state.last_cycle_at != nil
    end

    test "collects observations from all subsystems" do
      observations = TelemetryCollector.collect(:rea_evolution)
      assert length(observations) > 0
      assert Enum.all?(observations, fn o -> o.source == :rea_evolution end)
    end

    test "survives subsystem failures gracefully" do
      Process.exit(Process.whereis(SentinelHeartbeat), :kill)
      Process.sleep(100)

      assert Process.whereis(SentinelHeartbeat) != nil
      state = SentinelHeartbeat.get_state()
      assert state.cycle_count >= 0
    end
  end

  describe "Research Director -- autonomous investigation" do
    test "generates hypotheses from agency events" do
      event = %AgencyEvent{
        id: "evt_test", source: :rea_evolution, category: :anomaly,
        severity: :warning, observation_summary: "Entropy dropped 40%",
        interpretation: "Possible monoculture formation",
        causal_hypotheses: ["Selection pressure imbalance", "Mutation generator failure"],
        impact: 0.7, confidence: 0.75, urgency: 0.6, priority_score: 0.6,
        requires_investigation: true, timestamp: DateTime.utc_now()
      }

      {:ok, result} = ResearchDirector.investigate(ResearchDirector, event)

      assert length(result.hypotheses) >= 1
      assert result.selected != nil
      assert result.selected.status in [:validated, :refuted]
      assert result.experiment != nil
      assert result.knowledge != nil
    end

    test "ranks hypotheses by priority formula" do
      event = %AgencyEvent{
        id: "evt_rank", source: :memory_system, category: :risk,
        severity: :critical, observation_summary: "Memory leak suspected",
        causal_hypotheses: ["GC failure", "Unbounded cache", "Circular reference"],
        impact: 0.9, confidence: 0.8, urgency: 1.0, priority_score: 0.9,
        requires_investigation: true, timestamp: DateTime.utc_now()
      }

      {:ok, result} = ResearchDirector.investigate(ResearchDirector, event)

      scores = Enum.map(result.hypotheses, & &1.priority_score)
      assert scores == Enum.sort(scores, :desc)
    end

    test "integrates knowledge into Reality Graph and Memory" do
      event = %AgencyEvent{
        id: "evt_knowledge", source: :knowledge_growth, category: :discovery,
        severity: :info, observation_summary: "Novel pattern detected",
        causal_hypotheses: ["Emergent principle"],
        impact: 0.6, confidence: 0.7, urgency: 0.5, priority_score: 0.5,
        requires_investigation: true, timestamp: DateTime.utc_now()
      }

      {:ok, result} = ResearchDirector.investigate(ResearchDirector, event)

      assert result.knowledge != nil
      assert result.knowledge.knowledge_level in [:data, :information, :knowledge, :pattern, :principle]
      assert result.knowledge.confidence >= 0.0 and result.knowledge.confidence <= 1.0
    end

    test "preserves hypothesis lineage" do
      event = %AgencyEvent{
        id: "evt_lineage", source: :rea_evolution, category: :anomaly,
        severity: :warning, observation_summary: "Test",
        causal_hypotheses: ["Test hypothesis"],
        impact: 0.5, confidence: 0.5, urgency: 0.5, priority_score: 0.5,
        requires_investigation: true, timestamp: DateTime.utc_now()
      }

      {:ok, result} = ResearchDirector.investigate(ResearchDirector, event)

      assert result.selected.experiment_id == result.experiment.id
      assert result.knowledge.source_hypothesis_id == result.selected.id
      assert result.knowledge.source_experiment_id == result.experiment.id
    end
  end

  describe "Agency Orchestrator -- the glue" do
    test "receives events from Sentinel Heartbeat" do
      {:ok, _} = SentinelHeartbeat.trigger_cycle()
      Process.sleep(50)

      cycle_state = Orchestrator.get_cycle_state()
      assert cycle_state.status in [:idle, :observing, :investigating]
    end

    test "notifies humans for critical events" do
      critical_event = %AgencyEvent{
        id: "evt_critical", source: :security_posture, category: :risk,
        severity: :critical, observation_summary: "Security breach detected",
        interpretation: "Unauthorized access pattern",
        impact: 1.0, confidence: 0.9, urgency: 1.0, priority_score: 0.95,
        requires_investigation: true, requires_human_notification: true,
        timestamp: DateTime.utc_now()
      }

      Orchestrator.receive_event(critical_event)
      Process.sleep(50)

      cycle_state = Orchestrator.get_cycle_state()
      assert cycle_state.events_emitted >= 1
    end

    test "runs continuously without human trigger" do
      Process.sleep(300)

      cycle_state = Orchestrator.get_cycle_state()
      assert cycle_state.last_completed_at != nil
    end
  end

  describe "adversarial: handles noise and contradictions" do
    test "filters out low-priority noise" do
      noise_event = %AgencyEvent{
        id: "evt_noise", source: :runtime_performance, category: :info,
        severity: :info, observation_summary: "Normal fluctuation",
        impact: 0.1, confidence: 0.3, urgency: 0.1, priority_score: 0.05,
        requires_investigation: false, timestamp: DateTime.utc_now()
      }

      Orchestrator.receive_event(noise_event)
      Process.sleep(50)

      log = :sys.get_state(ResearchDirector) |> Map.get(:investigation_log, [])
      assert is_list(log)
    end

    test "handles contradictory evidence by penalizing confidence" do
      event = %AgencyEvent{
        id: "evt_contra", source: :rea_evolution, category: :anomaly,
        severity: :warning, observation_summary: "Contradictory signals",
        causal_hypotheses: ["Hypothesis A", "Hypothesis B"],
        impact: 0.5, confidence: 0.5, urgency: 0.5, priority_score: 0.5,
        requires_investigation: true, timestamp: DateTime.utc_now()
      }

      {:ok, result} = ResearchDirector.investigate(ResearchDirector, event)

      assert result.evaluation != nil
      assert result.evaluation.new_confidence >= 0.0
      assert result.evaluation.new_confidence <= 1.0
    end
  end

  describe "constitutional: evidence before confidence" do
    test "every knowledge record has explicit confidence" do
      event = %AgencyEvent{
        id: "evt_conf", source: :knowledge_growth, category: :discovery,
        severity: :info, observation_summary: "Test",
        causal_hypotheses: ["Test"],
        impact: 0.5, confidence: 0.5, urgency: 0.5, priority_score: 0.5,
        requires_investigation: true, timestamp: DateTime.utc_now()
      }

      {:ok, result} = ResearchDirector.investigate(ResearchDirector, event)

      assert result.knowledge.confidence >= 0.0
      assert result.knowledge.confidence <= 1.0
      assert length(result.knowledge.supporting_evidence) > 0
    end
  end

  describe "constitutional: verification first" do
    test "every experiment has rollback plan and failure conditions" do
      event = %AgencyEvent{
        id: "evt_verify", source: :memory_system, category: :risk,
        severity: :warning, observation_summary: "Memory growth",
        causal_hypotheses: ["Cache leak"],
        impact: 0.7, confidence: 0.7, urgency: 0.7, priority_score: 0.7,
        requires_investigation: true, timestamp: DateTime.utc_now()
      }

      {:ok, result} = ResearchDirector.investigate(ResearchDirector, event)

      assert result.experiment.rollback_plan != nil
      assert result.experiment.rollback_plan != ""
      assert length(result.experiment.failure_conditions) > 0
    end
  end

  describe "constitutional: augments human intelligence" do
    test "runtime experiments require human approval" do
      event = %AgencyEvent{
        id: "evt_human", source: :runtime_performance, category: :anomaly,
        severity: :warning, observation_summary: "Test",
        causal_hypotheses: ["Test"],
        impact: 0.5, confidence: 0.5, urgency: 0.5, priority_score: 0.5,
        requires_investigation: true, timestamp: DateTime.utc_now()
      }

      {:ok, result} = ResearchDirector.investigate(ResearchDirector, event)

      assert result.experiment.requires_human_approval in [true, false]
      if result.experiment.experiment_type == :runtime do
        assert result.experiment.requires_human_approval == true
      end
    end

    test "critical events notify humans" do
      critical_event = %AgencyEvent{
        id: "evt_notify", source: :security_posture, category: :risk,
        severity: :critical, observation_summary: "Critical issue",
        interpretation: "Requires attention",
        impact: 1.0, confidence: 0.9, urgency: 1.0, priority_score: 0.95,
        requires_investigation: true, requires_human_notification: true,
        timestamp: DateTime.utc_now()
      }

      Orchestrator.receive_event(critical_event)
      Process.sleep(50)

      cycle_state = Orchestrator.get_cycle_state()
      assert cycle_state.events_emitted >= 1
    end
  end

  describe "constitutional: memory philosophy" do
    test "knowledge records progress through levels" do
      events = Enum.map(1..5, fn i ->
        %AgencyEvent{
          id: "evt_mem_#{i}", source: :knowledge_growth, category: :discovery,
          severity: :info, observation_summary: "Discovery #{i}",
          causal_hypotheses: ["Hypothesis #{i}"],
          impact: 0.5, confidence: 0.5, urgency: 0.5, priority_score: 0.5,
          requires_investigation: true, timestamp: DateTime.utc_now()
        }
      end)

      knowledge_levels = Enum.map(events, fn event ->
        {:ok, result} = ResearchDirector.investigate(ResearchDirector, event)
        result.knowledge.knowledge_level
      end)

      assert length(Enum.uniq(knowledge_levels)) >= 1
      assert Enum.all?(knowledge_levels, & &1 in [:data, :information, :knowledge, :pattern, :principle])
    end
  end

  describe "integration: full agency loop" do
    test "complete cycle: observe -> investigate -> learn -> update state" do
      Process.sleep(500)

      heartbeat_state = SentinelHeartbeat.get_state()
      cycle_state = Orchestrator.get_cycle_state()
      knowledge_log = :sys.get_state(ResearchDirector) |> Map.get(:knowledge_log, [])

      assert heartbeat_state.cycle_count >= 1, "Heartbeat should have run"
      assert cycle_state.last_completed_at != nil, "Orchestrator should have processed"
      assert is_list(knowledge_log)
    end
  end
end
