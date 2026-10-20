defmodule TiannaraRuntime.Cognitive.Metacognition.MetacognitionValidationTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.Cognitive.Metacognition.{
    SelfMonitor,
    ConfidenceEstimator,
    UncertaintyAnalyzer,
    HealthEvaluator,
    EscalationEngine,
    IntrospectionEngine,
    MetaController,
    MetaReplay,
    MetaArchaeology
  }

  describe "Tier 1 — Session Management" do
    test "initialize_session returns {:ok, session} with status :initialized" do
      assert {:ok, session} = MetaController.initialize_session(%{test: true})
      assert session.status == :initialized
      assert String.starts_with?(session.session_id, "mc_")
    end

    test "record_step with :monitor and :confidence appends to respective lists" do
      assert {:ok, session} = MetaController.initialize_session(%{})
      assert {:ok, s1} = MetaController.record_step(session, :monitor, %{load: 0.5})
      assert {:ok, s2} = MetaController.record_step(s1, :confidence, %{value: 0.8})
      assert length(s2.monitors) == 1
      assert length(s2.confidence_estimates) == 1
      assert hd(s2.monitors) == %{load: 0.5}
      assert hd(s2.confidence_estimates) == %{value: 0.8}
    end

    test "finalize changes session status to :completed" do
      assert {:ok, session} = MetaController.initialize_session(%{})
      assert {:ok, completed} = MetaController.finalize(session)
      assert completed.status == :completed
      assert Map.has_key?(completed, :completed_at)
    end
  end

  describe "Tier 2 — Self-Monitoring" do
    test "measure returns map with 5 dimension keys" do
      state = %{throughput: 50.0, error_count: 2, total_operations: 100, latency_ms: 15.0, memory_used: 500, memory_limit: 1000}
      assert {:ok, dims} = SelfMonitor.measure(state)
      assert Map.has_key?(dims, :cognitive_load)
      assert Map.has_key?(dims, :throughput)
      assert Map.has_key?(dims, :error_rate)
      assert Map.has_key?(dims, :latency_ms)
      assert Map.has_key?(dims, :memory_pressure)
      assert dims.throughput == 50.0
      assert dims.error_rate == 0.02
      assert dims.memory_pressure == 0.5
    end

    test "track appends a monitor state to history list" do
      assert {:ok, history} = SelfMonitor.track(%{load: 0.3}, [])
      assert history == [%{load: 0.3}]
      assert {:ok, updated} = SelfMonitor.track(%{load: 0.5}, history)
      assert updated == [%{load: 0.3}, %{load: 0.5}]
    end

    test "trend computes average of dimensions over a window" do
      m1 = %{cognitive_load: 0.2, throughput: 10.0, error_rate: 0.01, latency_ms: 5.0, memory_pressure: 0.3}
      m2 = %{cognitive_load: 0.4, throughput: 20.0, error_rate: 0.02, latency_ms: 15.0, memory_pressure: 0.5}
      m3 = %{cognitive_load: 0.6, throughput: 30.0, error_rate: 0.03, latency_ms: 25.0, memory_pressure: 0.7}
      assert {:ok, trend} = SelfMonitor.trend([m1, m2, m3], 2)
      assert trend.cognitive_load == 0.5
      assert trend.throughput == 25.0
      assert trend.error_rate == 0.025
      assert trend.latency_ms == 20.0
      assert trend.memory_pressure == 0.6
      assert trend.window == 2
    end
  end

  describe "Tier 3 — Confidence" do
    test "estimate returns {:ok, estimate} with a value" do
      evidence = [%{quality: 0.9}, %{quality: 0.7}, %{quality: 0.2}]
      assert {:ok, est} = ConfidenceEstimator.estimate(evidence)
      assert is_float(est.value)
      assert est.value > 0
      assert est.source == :evidence_quality
    end

    test "calibrate produces 10 calibration buckets" do
      outcomes = [1, 0, 1, 1, 0, 1]
      predictions = [0.9, 0.3, 0.8, 0.7, 0.2, 0.6]
      assert {:ok, cal} = ConfidenceEstimator.calibrate(outcomes, predictions)
      assert length(cal.calibration_curve) == 10
      assert Map.has_key?(cal, :miscalibration)
      assert Map.has_key?(cal, :calibrated_at)
    end

    test "is_calibrated returns boolean based on threshold" do
      calibration = %{miscalibration: 0.05}
      assert {:ok, true} = ConfidenceEstimator.is_calibrated(calibration, 0.1)
      assert {:ok, false} = ConfidenceEstimator.is_calibrated(calibration, 0.01)
    end
  end

  describe "Tier 4 — Uncertainty" do
    test "analyze returns map with aleatoric, epistemic, and total keys" do
      assert {:ok, result} = UncertaintyAnalyzer.analyze(%{type: :decision}, %{field_a: "a", field_b: nil}, [0.8, 0.6, 0.9])
      assert Map.has_key?(result, :aleatoric)
      assert Map.has_key?(result, :epistemic)
      assert Map.has_key?(result, :total)
      assert is_float(result.aleatoric)
      assert is_float(result.epistemic)
      assert is_float(result.total)
    end

    test "aleatoric computes variance from outcomes" do
      {:ok, zero} = UncertaintyAnalyzer.aleatoric([])
      assert zero == 0.0
      assert {:ok, val} = UncertaintyAnalyzer.aleatoric([0.5, 0.7])
      assert val > 0.0
    end

    test "total computes RMS of aleatoric and epistemic capped at 1.0" do
      {:ok, val_zero} = UncertaintyAnalyzer.total(0.0, 0.0)
      assert val_zero == 0.0
      assert {:ok, val} = UncertaintyAnalyzer.total(0.5, 0.5)
      assert val <= 1.0
      assert val > 0.0
    end
  end

  describe "Tier 5 — Health" do
    test "assess returns 6 dimension keys in dimensions map" do
      monitors = [
        %{cognitive_load: 0.2, error_rate: 0.01, latency_ms: 5.0, memory_pressure: 0.3, throughput: 50.0},
        %{cognitive_load: 0.3, error_rate: 0.02, latency_ms: 10.0, memory_pressure: 0.4, throughput: 60.0}
      ]
      assert {:ok, health} = HealthEvaluator.assess(monitors, %{max_throughput: 100.0})
      assert map_size(health.dimensions) == 6
      assert Map.has_key?(health.dimensions, :cognitive_load)
      assert Map.has_key?(health.dimensions, :error_density)
      assert Map.has_key?(health.dimensions, :response_time_variance)
      assert Map.has_key?(health.dimensions, :resource_pressure)
      assert Map.has_key?(health.dimensions, :stability_index)
      assert Map.has_key?(health.dimensions, :throughput_health)
    end

    test "overall health is the average of all six dimension values" do
      monitors = [
        %{cognitive_load: 0.1, error_rate: 0.0, latency_ms: 2.0, memory_pressure: 0.1, throughput: 80.0}
      ]
      assert {:ok, health} = HealthEvaluator.assess(monitors, %{max_throughput: 100.0})
      expected_avg = Enum.sum(Map.values(health.dimensions)) / map_size(health.dimensions)
      assert health.overall == expected_avg
    end

    test "compare returns deltas and overall_delta between two health assessments" do
      h1 = %{dimensions: %{a: 0.2, b: 0.5}, overall: 0.35, status: :healthy}
      h2 = %{dimensions: %{a: 0.8, b: 0.3}, overall: 0.55, status: :degraded}
      assert {:ok, result} = HealthEvaluator.compare(h1, h2)
      assert_in_delta result.deltas.a, 0.6, 0.0001
      assert result.deltas.b == -0.2
      assert_in_delta result.overall_delta, 0.2, 0.0001
      assert result.status_change == {:healthy, :degraded}
    end
  end

  describe "Tier 6 — Escalation" do
    test "evaluate returns level based on health, uncertainty, and confidence" do
      health = %{status: :healthy, overall: 0.2}
      uncertainty = %{total: 0.1}
      confidence = %{miscalibration: 0.05}
      assert {:ok, decision} = EscalationEngine.evaluate(health, uncertainty, confidence)
      assert decision.level == :normal
      assert decision.reason == "All systems nominal"
    end

    test "escalate changes the decision level" do
      decision = %{level: :normal, reason: "All nominal", decided_at: 1}
      assert {:ok, escalated} = EscalationEngine.escalate(decision, :critical)
      assert escalated.level == :critical
      assert String.contains?(escalated.reason, "Escalated")
    end

    test "de_escalate lowers the escalation level" do
      decision = %{level: :critical, reason: "Critical", decided_at: 1}
      assert {:ok, d1} = EscalationEngine.de_escalate(decision)
      assert d1.level == :warning
      assert {:ok, d2} = EscalationEngine.de_escalate(d1)
      assert d2.level == :info
      assert {:ok, d3} = EscalationEngine.de_escalate(d2)
      assert d3.level == :normal
      assert {:ok, d4} = EscalationEngine.de_escalate(d3)
      assert d4.level == :normal
    end
  end

  describe "Tier 7 — Introspection" do
    test "introspect returns findings for all five aspects" do
      session = %{evidence: [%{id: 1}], archaeology: %{layer: 1}, evidence_chain: %{}, bias_assessments: [%{type: :confirmation}]}
      constitution = %{trigger: :manual}
      assert {:ok, result} = IntrospectionEngine.introspect(session, constitution)
      assert length(result.findings) == 5
      assert result.status == :completed
      assert result.trigger == :manual
    end

    test "check_finding returns pass for determinism when evidence is a list" do
      session = %{evidence: [%{id: 1}]}
      assert {:ok, finding} = IntrospectionEngine.check_finding(:determinism, session, %{})
      assert finding.result == :pass
      assert finding.aspect == :determinism
    end

    test "summarize returns a formatted string with pass/fail counts" do
      findings = [
        %{result: :pass, aspect: :determinism},
        %{result: :fail, aspect: :replay},
        %{result: :pass, aspect: :archaeology},
        %{result: :warning, aspect: :evidence},
        %{result: :pass, aspect: :bias}
      ]
      introspection = %{findings: findings, status: :completed}
      assert {:ok, summary} = IntrospectionEngine.summarize(introspection)
      assert is_binary(summary)
      assert String.contains?(summary, "3 passed")
      assert String.contains?(summary, "1 failed")
      assert String.contains?(summary, "1 warning")
    end
  end

  describe "Tier 8 — Replay" do
    test "struct %MetaReplay{} can be constructed directly" do
      replay = %MetaReplay{session_id: "s1", state_root: "abc", schema_version: 1}
      assert replay.session_id == "s1"
      assert replay.state_root == "abc"
      assert replay.id == nil
    end

    test "validate passes when session_id is present and schema_version matches" do
      replay = %MetaReplay{session_id: "s1", schema_version: 1}
      assert MetaReplay.validate(replay) == :ok
    end

    test "generate_id returns string starting with mr_" do
      id = MetaReplay.generate_id(%{session_id: "s1"})
      assert String.starts_with?(id, "mr_")
      assert String.length(id) == 19
    end
  end

  describe "Tier 9 — Archaeology" do
    test "struct %MetaArchaeology{} can be constructed directly" do
      arch = %MetaArchaeology{session_id: "s1", origin: :replay, schema_version: 1}
      assert arch.session_id == "s1"
      assert arch.origin == :replay
    end

    test "validate passes when session_id is present and schema_version matches" do
      arch = %MetaArchaeology{session_id: "s1", schema_version: 1}
      assert MetaArchaeology.validate(arch) == :ok
    end

    test "generate_id returns string starting with ma_" do
      id = MetaArchaeology.generate_id(%{session_id: "s1"})
      assert String.starts_with?(id, "ma_")
      assert String.length(id) == 19
    end
  end

  describe "Tier 10 — Stress" do
    test "100 sessions can be initialized through MetaController" do
      sessions = for i <- 1..100, do: MetaController.initialize_session(%{index: i})
      assert length(sessions) == 100
      Enum.each(sessions, fn {:ok, s} -> assert s.status == :initialized end)
    end

    test "metrics tracking records step counts across a session lifecycle" do
      assert {:ok, session} = MetaController.initialize_session(%{})
      steps = [
        {:monitor, %{load: 0.3}},
        {:monitor, %{load: 0.5}},
        {:confidence, %{value: 0.8}},
        {:uncertainty, %{total: 0.2}},
        {:health, %{overall: 0.4}},
        {:escalation, %{level: :normal}},
        {:introspection, %{findings: []}}
      ]
      session = Enum.reduce(steps, session, fn {type, data}, acc ->
        {:ok, updated} = MetaController.record_step(acc, type, data)
        updated
      end)
      assert {:ok, completed} = MetaController.finalize(session)
      assert completed.status == :completed
      assert length(completed.monitors) == 2
      assert length(completed.confidence_estimates) == 1
      assert length(completed.uncertainty_estimates) == 1
      assert length(completed.health_assessments) == 1
      assert length(completed.escalations) == 1
      assert length(completed.introspections) == 1
    end

    test "summarize returns correct counts for a fully populated session" do
      assert {:ok, session} = MetaController.initialize_session(%{})
      s1 = elem(MetaController.record_step(session, :monitor, %{}), 1)
      s2 = elem(MetaController.record_step(s1, :confidence, %{}), 1)
      s3 = elem(MetaController.record_step(s2, :uncertainty, %{}), 1)
      s4 = elem(MetaController.record_step(s3, :health, %{}), 1)
      s5 = elem(MetaController.record_step(s4, :escalation, %{}), 1)
      s6 = elem(MetaController.record_step(s5, :introspection, %{}), 1)
      assert {:ok, summary} = MetaController.summarize(s6)
      assert summary.monitor_count == 1
      assert summary.confidence_count == 1
      assert summary.uncertainty_count == 1
      assert summary.health_count == 1
      assert summary.escalation_count == 1
      assert summary.introspection_count == 1
      assert summary.status == :initialized
    end
  end
end
