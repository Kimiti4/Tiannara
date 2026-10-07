defmodule Tiannara.Sentinel.Cognition.OrchestratorTest do
  use ExUnit.Case, async: false

  alias Tiannara.Sentinel.Cognition.{
    State, Hypothesis, Experiment, WorldModel,
    ContextEngine, CausalReasoner, HypothesisEngine,
    PredictiveEngine, PriorityEngine, ExperimentPlanner,
    ConfidenceEngine, Orchestrator, Interface
  }

  setup do
    pid = Process.whereis(Tiannara.Sentinel.Cognition.Supervisor)
    assert is_pid(pid), "Cognition.Supervisor must be started by the application"
    :ok
  end

  describe "functional: builds complete cognitive state" do
    test "builds full cognitive state from event" do
      event = %{id: "evt_1", source: :Memory, observation: "Usage increased 45%"}
      state = Orchestrator.investigate(event)

      assert state.context.synthesized_context != nil
      assert state.causal.root_cause != nil
      assert state.hypothesis.status == :proposed
      assert state.experiment.rollback_plan != nil
      assert state.confidence.confidence >= 0.0 and state.confidence.confidence <= 1.0
    end

    test "populates all cognitive state fields" do
      event = %{id: "evt_2", source: :REA, observation: "Discovery rate declined"}
      state = Orchestrator.investigate(event)

      assert state.event != nil
      assert state.context != nil
      assert state.world_model != nil
      assert state.causal != nil
      assert state.hypothesis != nil
      assert state.prediction != nil
      assert state.priority != nil
      assert state.experiment != nil
      assert state.confidence != nil
      assert is_integer(state.uncertainty)
    end
  end

  describe "context reconstruction" do
    test "reconstructs temporal context" do
      event = %{id: "evt_3", source: :Memory, observation: "Usage spike"}
      context = ContextEngine.reconstruct(:context_engine, event)
      assert context.temporal.trend == :increasing
      assert context.temporal.baseline == 100
      assert context.temporal.current == 145
    end

    test "reconstructs spatial context" do
      event = %{id: "evt_4", source: :Memory, observation: "Usage spike"}
      context = ContextEngine.reconstruct(:context_engine, event)
      assert context.spatial.subsystem == :ArchaeologyRegistry
      assert :Memory in context.spatial.dependencies
    end

    test "reconstructs historical context" do
      event = %{id: "evt_5", source: :Memory, observation: "Usage spike"}
      context = ContextEngine.reconstruct(:context_engine, event)
      assert context.historical.similar_incidents >= 0
      assert context.historical.success_rate > 0
    end
  end

  describe "causal reasoning" do
    test "identifies multiple possible causes" do
      event = %{id: "evt_6", source: :Memory, observation: "Growth anomaly"}
      causal = CausalReasoner.analyze(:causal_reasoner, event, %{})
      assert length(causal.causal_graph) > 0
      assert causal.root_cause != nil
    end

    test "generates counterfactual analyses" do
      event = %{id: "evt_7", source: :Memory, observation: "Growth anomaly"}
      causal = CausalReasoner.analyze(:causal_reasoner, event, %{})
      assert length(causal.counterfactuals) > 0
      assert Enum.all?(causal.counterfactuals, fn c -> c.intervention != nil end)
    end
  end

  describe "hypothesis generation" do
    test "formulates testable hypothesis from event and causal" do
      event = %{id: "evt_8", source: :REA, observation: "Diversity collapse"}
      causal = %{root_cause: "Selection pressure too strong", confidence: 0.84}
      hyp = HypothesisEngine.formulate(:hypothesis_engine, event, causal)

      assert hyp.question != nil
      assert hyp.question |> String.contains?("Why")
      assert hyp.prediction != nil
      assert hyp.status == :proposed
    end
  end

  describe "predictive analysis" do
    test "produces forecast with confidence" do
      event = %{id: "evt_9", source: :Memory, observation: "Growth trend"}
      pred = PredictiveEngine.forecast(:predictive_engine, event, %{})
      assert pred.forecast != nil
      assert pred.confidence > 0
      assert pred.risk_level in [:low, :medium, :high]
    end
  end

  describe "research prioritization" do
    test "calculates priority score from hypothesis and prediction" do
      hyp = %Hypothesis{id: "h1", confidence: 0.8}
      pred = %{risk_level: :high}
      priority = PriorityEngine.calculate(:priority_engine, hyp, pred)

      assert priority.score > 0
      assert priority.tier in [:normal, :critical]
      assert priority.breakdown.impact > 0
    end
  end

  describe "experiment planning" do
    test "creates structured experiment with all required fields" do
      hyp = %Hypothesis{id: "h1", observation: "Memory growth", question: "Why?", hypothesis: "Pruning insufficient"}
      experiment = ExperimentPlanner.design(:experiment_planner, hyp)

      assert experiment.research_question != nil
      assert length(experiment.failure_conditions) > 0
      assert experiment.rollback_plan != nil
      assert experiment.rollback_plan != ""
      assert experiment.validation_metrics != []
    end
  end

  describe "confidence calibration" do
    test "calculates confidence from evidence quality and quantity" do
      hyp = %Hypothesis{id: "h1", evidence: ["e1", "e2", "e3"]}
      result = ConfidenceEngine.evaluate(:confidence_engine, hyp)
      assert result.confidence >= 0.0 and result.confidence <= 1.0
      assert result.evidence_quality > 0
    end

    test "penalizes confidence for contradictions" do
      hyp = %Hypothesis{
        id: "h2", evidence: ["e1", "e2", "e3"],
        contradictions: ["c1", "c2"],
        unknown_variables: []
      }
      result = ConfidenceEngine.evaluate(:confidence_engine, hyp)
      assert result.confidence < 0.6
      assert result.contradictions == 2
    end

    test "penalizes confidence for unknown variables" do
      hyp = %Hypothesis{
        id: "h3", evidence: ["e1"],
        contradictions: [],
        unknown_variables: ["x1", "x2", "x3"]
      }
      result = ConfidenceEngine.evaluate(:confidence_engine, hyp)
      assert result.confidence < 0.4
      assert result.unknowns == 3
    end
  end

  describe "report generation" do
    test "generates human-readable investigation report" do
      event = %{id: "evt_10", source: :Memory, observation: "Usage increased 45%"}
      state = Orchestrator.investigate(event)

      report = Interface.generate_report(state)
      assert report |> String.contains?("SENTINEL INVESTIGATION REPORT")
      assert report |> String.contains?("HUMAN DECISION REQUIRED")
      assert report |> String.contains?(state.causal.root_cause)
    end
  end

  describe "constitutional: verification first" do
    test "experiment always includes failure conditions and rollback" do
      event = %{id: "evt_11", source: :SOPL, observation: "Law monoculture detected"}
      state = Orchestrator.investigate(event)

      assert length(state.experiment.failure_conditions) > 0
      assert state.experiment.rollback_plan != nil
      assert state.experiment.rollback_plan != ""
    end

    test "confidence never exceeds 1.0 or falls below 0.0" do
      event = %{id: "evt_12", source: :REA, observation: "Test event"}
      state = Orchestrator.investigate(event)
      assert state.confidence.confidence >= 0.0
      assert state.confidence.confidence <= 1.0
    end
  end
end
