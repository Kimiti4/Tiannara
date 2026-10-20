defmodule TiannaraRuntime.Cognitive.Reflection.ReflectionValidationTest do
  use ExUnit.Case, async: false
  @moduletag :reflection_validation

  alias TiannaraRuntime.Cognitive.Reflection.{
    ReflectionController, OutcomeAnalyzer, PatternDetector,
    BiasDetector, LessonExtractor, MetaCognitionController,
    ReflectionMetrics, Outcome, ReflectionReplay, ReflectionArchaeology
  }

  defp sample_decision do
    %{id: :erlang.unique_integer([:positive]), session_id: :erlang.unique_integer([:positive])}
  end

  defp sample_plan do
    %{id: :erlang.unique_integer([:positive])}
  end

  defp sample_mission do
    %{id: :erlang.unique_integer([:positive]), goals: [:g1, :g2, :g3], completed_goals: [:g1, :g2]}
  end

  defp sample_outcome(overrides \\ %{}) do
    %Outcome{
      id: Map.get(overrides, :id, :erlang.unique_integer([:positive])),
      session_id: Map.get(overrides, :session_id, :erlang.unique_integer([:positive])),
      decision_id: Map.get(overrides, :decision_id, :erlang.unique_integer([:positive])),
      plan_id: Map.get(overrides, :plan_id, :erlang.unique_integer([:positive])),
      mission_id: Map.get(overrides, :mission_id, :erlang.unique_integer([:positive])),
      status: :success,
      success_score: Map.get(overrides, :success_score, 0.85),
      dimensions: %{
        mission: 0.9, scientific: 0.8,
        operational: 0.85, temporal: 0.7, resource: 0.75
      },
      occurred_at: Map.get(overrides, :occurred_at, :erlang.unique_integer([:positive])),
      evidence_hash: "abc123"
    }
  end

  defp sample_session(overrides \\ %{}) do
    decision = sample_decision()
    {:ok, session} = ReflectionController.start_session(%{}, decision.id, decision.id)
    outcome = sample_outcome(%{session_id: decision.id, decision_id: decision.id})
    pattern = %{id: :erlang.unique_integer([:positive]), type: :frequency, data: %{low: 1, medium: 2, high: 3}, confidence: 0.7}
    bias = %{id: :erlang.unique_integer([:positive]), type: :confirmation, severity: 0.3, confidence: 0.6, dimensions: %{selective_attention: 0.4, interpretation_bias: 0.24}, evidence: [], recommendation: "test"}
    lesson = %{id: :erlang.unique_integer([:positive]), type: :actionable, description: "test lesson", applicability: 0.8, success_rate: 0.85, source_pattern_id: nil, source_outcome_id: outcome.id}
    {:ok, s1} = ReflectionController.add_outcome(session, outcome)
    {:ok, s2} = ReflectionController.add_pattern(s1, pattern)
    {:ok, s3} = ReflectionController.add_bias(s2, bias)
    {:ok, s4} = ReflectionController.add_lesson(s3, lesson)
    Map.merge(s4, overrides)
  end

  describe "Tier 1 — Reflection Session Creation" do
    test "start_session creates session with initiated status" do
      decision = sample_decision()
      assert {:ok, session} = ReflectionController.start_session(%{}, decision.id, decision.id)
      assert Map.get(session, :status) == :initiated
      assert Map.get(session, :mission_id) == decision.id
      assert is_integer(Map.get(session, :id))
    end

    test "add_outcome appends outcome to session" do
      decision = sample_decision()
      {:ok, session} = ReflectionController.start_session(%{}, decision.id, decision.id)
      outcome = sample_outcome()
      assert {:ok, updated} = ReflectionController.add_outcome(session, outcome)
      assert length(Map.get(updated, :outcomes, [])) == 1
    end

    test "finalize completes session and increments version" do
      decision = sample_decision()
      {:ok, session} = ReflectionController.start_session(%{}, decision.id, decision.id)
      session = Map.put(session, :meta_state, %{})
      assert {:ok, finalized} = ReflectionController.finalize(session)
      assert Map.get(finalized, :status) == :completed
      assert get_in(finalized, [:meta_state, :version]) == 1
    end
  end

  describe "Tier 2 — Outcome Analysis" do
    test "analyze returns outcome with status and score" do
      assert {:ok, outcome} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      assert is_float(Map.get(outcome, :success_score))
      assert Map.get(outcome, :status) in [:success, :partial, :failure]
    end

    test "score returns 7 dimensions" do
      {:ok, outcome} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      assert {:ok, scores} = OutcomeAnalyzer.score(outcome)
      assert is_float(Map.get(scores, :mission))
      assert is_float(Map.get(scores, :scientific))
      assert is_float(Map.get(scores, :operational))
      assert is_float(Map.get(scores, :temporal))
      assert is_float(Map.get(scores, :resource))
      assert is_float(Map.get(scores, :overall))
      assert is_float(Map.get(scores, :success_score))
      assert map_size(scores) == 7
    end

    test "compare works on multiple outcomes" do
      {:ok, o1} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      {:ok, o2} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), %{sample_mission() | goals: [:g1], completed_goals: [:g1]})
      assert {:ok, comparison} = OutcomeAnalyzer.compare([o1, o2])
      assert Map.get(comparison, :count) == 2
      assert is_float(Map.get(comparison, :best))
    end
  end

  describe "Tier 3 — Pattern Detection" do
    test "detect returns list of patterns" do
      {:ok, o1} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      {:ok, o2} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), %{sample_mission() | goals: [:g1], completed_goals: []})
      assert {:ok, patterns} = PatternDetector.detect([o1, o2])
      assert is_list(patterns)
    end

    test "frequency_pattern returns pattern with bands" do
      {:ok, o1} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      assert {:ok, pattern} = PatternDetector.frequency_pattern([o1, o1, o1])
      assert Map.get(pattern, :type) == :frequency
      assert is_map(Map.get(pattern, :data))
    end

    test "anomaly_pattern returns pattern with anomaly count" do
      {:ok, o1} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      {:ok, o2} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), %{sample_mission() | goals: [:g1], completed_goals: []})
      assert {:ok, pattern} = PatternDetector.anomaly_pattern([o1, o1, o1, o2])
      assert Map.get(pattern, :type) == :anomaly
      assert is_integer(pattern[:data][:anomaly_count])
    end
  end

  describe "Tier 4 — Bias Detection" do
    test "assess returns 4 biases" do
      session = sample_session()
      assert {:ok, biases} = BiasDetector.assess(session)
      assert length(biases) == 4
    end

    test "confirmation_bias returns bias with type" do
      {:ok, o1} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      pattern = %{id: 1, type: :sequence, data: %{direction: :improving, slope: 0.1}, confidence: 0.6}
      assert {:ok, bias} = BiasDetector.confirmation_bias([o1], [pattern])
      assert Map.get(bias, :type) == :confirmation
      assert is_float(Map.get(bias, :severity))
    end

    test "overconfidence_bias returns bias with type" do
      assert {:ok, bias} = BiasDetector.overconfidence_bias(3, 2)
      assert Map.get(bias, :type) == :overconfidence
      assert Map.get(bias, :recommendation) != nil
    end
  end

  describe "Tier 5 — Lesson Extraction" do
    test "extract returns list of lessons" do
      {:ok, o1} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      {:ok, patterns} = PatternDetector.detect([o1, o1, o1])
      session = sample_session()
      {:ok, biases} = BiasDetector.assess(session)
      assert {:ok, lessons} = LessonExtractor.extract([o1], patterns, biases)
      assert is_list(lessons)
      assert length(lessons) > 0
    end

    test "actionable_lesson returns lesson with type" do
      {:ok, outcome} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      assert {:ok, lesson} = LessonExtractor.actionable_lesson(outcome)
      assert Map.get(lesson, :type) == :actionable
      assert is_float(Map.get(lesson, :applicability))
    end

    test "reusable_lesson returns lesson with type" do
      {:ok, o1} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      {:ok, pattern} = PatternDetector.frequency_pattern([o1, o1, o1])
      assert {:ok, lesson} = LessonExtractor.reusable_lesson(pattern)
      assert Map.get(lesson, :type) == :reusable
      assert is_binary(Map.get(lesson, :description))
    end
  end

  describe "Tier 6 — Meta-Cognition State" do
    test "initialize creates state with awareness and readiness" do
      {:ok, o1} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      assert {:ok, state} = MetaCognitionController.initialize([o1], [], [], [])
      assert is_float(Map.get(state, :awareness_level))
      assert is_float(Map.get(state, :adaptation_readiness))
      assert Map.get(state, :version) == 1
    end

    test "update changes state and increments version" do
      {:ok, o1} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      {:ok, state} = MetaCognitionController.initialize([o1], [], [], [])
      {:ok, o2} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), %{sample_mission() | goals: [:g1], completed_goals: []})
      assert {:ok, updated} = MetaCognitionController.update(state, o2, [], [], [])
      assert Map.get(updated, :version) == 2
      assert Map.get(updated, :outcome_count) == 2
    end

    test "summarize returns string" do
      {:ok, o1} = OutcomeAnalyzer.analyze(sample_decision(), sample_plan(), sample_mission())
      {:ok, state} = MetaCognitionController.initialize([o1], [], [], [])
      assert {:ok, summary} = MetaCognitionController.summarize(state)
      assert is_binary(summary)
      assert String.contains?(summary, "Meta-Cognition")
    end
  end

  describe "Tier 7 — Reflection Replay" do
    test "struct can be constructed and validated" do
      replay = %ReflectionReplay{id: "rr_test", session_id: 1, schema_version: 1, ontology_version: 1, created_with_phase: "18.7"}
      assert replay.__struct__ == ReflectionReplay
      assert ReflectionReplay.validate(replay) == :ok
    end

    test "validate returns error for nil id" do
      replay = %ReflectionReplay{session_id: 1, schema_version: 1, ontology_version: 1, created_with_phase: "18.7"}
      assert ReflectionReplay.validate(replay) == {:error, [{:id, :required}]}
    end

    test "generate_id produces correct prefix" do
      id = ReflectionReplay.generate_id(%{session_id: 1})
      assert String.starts_with?(id, "rr_")
      assert String.length(id) == 19
    end
  end

  describe "Tier 8 — Reflection Archaeology" do
    test "struct can be constructed and validated" do
      arch = %ReflectionArchaeology{id: "ra_test", session_id: 1, origin: :manual_review, schema_version: 1, ontology_version: 1, created_with_phase: "18.7"}
      assert arch.__struct__ == ReflectionArchaeology
      assert ReflectionArchaeology.validate(arch) == :ok
    end

    test "validate returns error for nil id" do
      arch = %ReflectionArchaeology{session_id: 1, origin: :manual_review, schema_version: 1, ontology_version: 1, created_with_phase: "18.7"}
      assert ReflectionArchaeology.validate(arch) == {:error, [{:id, :required}]}
    end

    test "generate_id produces correct prefix" do
      id = ReflectionArchaeology.generate_id(%{session_id: 1})
      assert String.starts_with?(id, "ra_")
      assert String.length(id) == 19
    end
  end

  describe "Tier 9 — Failure Injection" do
    test "empty outcomes list returns no patterns from detect" do
      assert {:ok, patterns} = PatternDetector.detect([])
      assert patterns == []
    end

    test "empty session assess returns non-empty biases" do
      assert {:ok, biases} = BiasDetector.assess(%{})
      assert length(biases) == 4
    end

    test "missing decision fields in analyze returns outcome" do
      assert {:ok, outcome} = OutcomeAnalyzer.analyze(%{}, %{}, %{})
      assert is_float(Map.get(outcome, :success_score))
    end
  end

  describe "Tier 10 — Stress" do
    test "100 sessions can be created and summarized" do
      sessions = Enum.map(1..100, fn i ->
        decision = %{id: i, session_id: i}
        {:ok, sess} = ReflectionController.start_session(%{}, decision.id, decision.id)
        {:ok, outcome} = OutcomeAnalyzer.analyze(decision, sample_plan(), sample_mission())
        {:ok, s} = ReflectionController.add_outcome(sess, outcome)
        s = Map.put(s, :meta_state, %{})
        {:ok, f} = ReflectionController.finalize(s)
        f
      end)
      assert length(sessions) == 100
      completed = Enum.filter(sessions, fn s -> Map.get(s, :status) == :completed end)
      assert length(completed) == 100
    end

    test "metrics summary aggregates stress data" do
      metrics = ReflectionMetrics.initialize()
      session = sample_session()
      m1 = ReflectionMetrics.record_reflection(metrics, session)
      m2 = ReflectionMetrics.record_pattern(m1, %{type: :frequency})
      bias = %{id: 1, type: :confirmation, severity: 0.3}
      m3 = ReflectionMetrics.record_bias(m2, bias)
      assert {:ok, summary} = ReflectionMetrics.summary(m3)
      assert Map.get(summary, :reflection_count) == 1
      assert Map.get(summary, :pattern_count) == 1
      assert Map.get(summary, :bias_count) == 1
      assert is_float(Map.get(summary, :average_bias_severity))
    end
  end
end
