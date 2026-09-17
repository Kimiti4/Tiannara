# Integration test for Sentinel Activation Layer
# Run with: elixir test/activation_integration.exs

Code.require_file("lib/tiannara/sentinel/activation/event.ex")
Code.require_file("lib/tiannara/sentinel/activation/intelligence.ex")
Code.require_file("lib/tiannara/sentinel/activation/causal.ex")
Code.require_file("lib/tiannara/sentinel/activation/recommendation.ex")
Code.require_file("lib/tiannara/sentinel/activation/dialogue.ex")
Code.require_file("lib/tiannara/sentinel/activation/crav_controller.ex")
Code.require_file("lib/tiannara/sentinel/activation/approval.ex")
Code.require_file("lib/tiannara/sentinel/activation/memory.ex")
Code.require_file("lib/tiannara/sentinel/activation/engine.ex")
Code.require_file("lib/tiannara/observatory/observatory.ex")
Code.require_file("lib/tiannara/memory/memory.ex")
Code.require_file("lib/tiannara/stubs/reality_graph.ex")
Code.require_file("lib/tiannara/stubs/sandbox.ex")

defmodule ActivationIntegrationTest do
  def run do
    test_event_creation()
    test_intelligence()
    test_causal()
    test_recommendations()
    test_crav()
    test_approval()
    test_dialogue()
    test_memory()
    test_engine()
    test_noise_filtering()
    IO.puts("\n=== ALL INTEGRATION TESTS PASSED ===")
  end

  defp assert(condition, message) do
    if condition do
      IO.puts("  PASS: #{message}")
    else
      IO.puts("  FAIL: #{message}")
      raise "Test failed: #{message}"
    end
  end

  defp test_event_creation do
    event = Tiannara.Sentinel.Activation.Event.new(%{
      source: :rea,
      category: :scientific,
      severity: :warning,
      observation: "Genome diversity decreased 40%",
      confidence: 0.82
    })
    assert event.id != nil, "Event has an ID"
    assert event.source == :rea, "Event source is :rea"
    assert event.category == :scientific, "Event category is :scientific"
    assert event.severity == :warning, "Event severity is :warning"
    assert event.confidence == 0.82, "Event confidence is 0.82"
    IO.puts("1. EVENT: #{event.id} #{event.category}/#{event.severity}")
  end

  defp test_intelligence do
    event = Tiannara.Sentinel.Activation.Event.new(%{
      source: :rea,
      category: :scientific,
      severity: :warning,
      observation: "Diversity decline",
      confidence: 0.82
    })
    result = Tiannara.Sentinel.Activation.Intelligence.evaluate(event)
    assert result.importance > 0, "Importance is positive"
    assert result.priority != :ignore, "Priority is not ignore"
    IO.puts("2. INTELLIGENCE: importance=#{Float.round(result.importance, 4)} priority=#{result.priority}")
  end

  defp test_causal do
    event = Tiannara.Sentinel.Activation.Event.new(%{
      source: :rea,
      category: :scientific,
      severity: :warning,
      observation: "Genome convergence detected"
    })
    interpreted = Tiannara.Sentinel.Activation.Causal.interpret(event)
    assert interpreted.interpretation != nil, "Interpretation is present"
    assert interpreted.confidence != nil, "Confidence is present"
    IO.puts("3. CAUSAL: #{interpreted.interpretation} (conf=#{Float.round(interpreted.confidence, 2)})")
  end

  defp test_recommendations do
    event = Tiannara.Sentinel.Activation.Event.new(%{
      source: :rea,
      category: :scientific,
      severity: :warning,
      observation: "Diversity decline",
      confidence: 0.82
    })
    recs = Tiannara.Sentinel.Activation.Recommendation.generate(event)
    assert length(recs) > 0, "Recommendations are generated"
    has_action = Enum.all?(recs, fn r -> r[:action] != nil end)
    has_rollback = Enum.all?(recs, fn r -> r[:rollback_plan] != nil end)
    has_validation = Enum.all?(recs, fn r -> r[:validation_method] != nil end)
    assert has_action, "All recs have action"
    assert has_rollback, "All recs have rollback plan"
    assert has_validation, "All recs have validation method"
    IO.puts("4. RECOMMENDATIONS: #{length(recs)} generated")
    Enum.each(recs, fn r -> IO.puts("   - #{r[:action]} (gain=#{r[:expected_gain]} risk=#{r[:risk]})") end)
  end

  defp test_crav do
    event = Tiannara.Sentinel.Activation.Event.new(%{
      source: :constitution,
      category: :constitutional,
      severity: :critical,
      observation: "Constitutional violation"
    })
    result = Tiannara.Sentinel.Activation.CRAVController.maybe_trigger(event)
    assert result == {:triggered, "full_constitutional"}, "Constitutional critical triggers full suite"
    IO.puts("5. CRAV: #{inspect(result)}")
  end

  defp test_approval do
    event = Tiannara.Sentinel.Activation.Event.new(%{
      source: :rea,
      category: :scientific,
      severity: :warning,
      observation: "Test approval"
    })
    rec = %{action: "Run simulation", expected_gain: 0.18, risk: 0.05, confidence: 0.8}
    proposal = Tiannara.Sentinel.Activation.Approval.propose(event, rec)
    assert proposal[:proposal_id] != nil, "Proposal has ID"
    assert proposal[:risk_score] == 0.05, "Proposal risk is 0.05"
    assert proposal[:status] == :pending, "Proposal is pending"
    IO.puts("6. APPROVAL: #{proposal[:proposal_id]} risk=#{proposal[:risk_score]}")
  end

  defp test_dialogue do
    event = Tiannara.Sentinel.Activation.Event.new(%{
      source: :rea,
      category: :scientific,
      severity: :info,
      observation: "Test dialogue"
    })
    result = Tiannara.Sentinel.Activation.Dialogue.initiate(event, [])
    assert result == :ok, "Dialogue initiated"
    IO.puts("7. DIALOGUE: sent")
  end

  defp test_memory do
    event = Tiannara.Sentinel.Activation.Event.new(%{
      source: :rea,
      category: :scientific,
      severity: :info,
      observation: "Test memory",
      interpretation: "Test interpretation",
      confidence: 0.8
    })
    outcome = %{action: "Test action"}
    result = Tiannara.Sentinel.Activation.Memory.record_outcome(event, outcome, :success)
    assert result == :ok, "Memory recorded"
    IO.puts("8. MEMORY: recorded")
  end

  defp test_engine do
    result = Tiannara.Sentinel.Activation.Engine.process(%{
      source: :rea,
      category: :scientific,
      severity: :warning,
      observation: "Engine test observation",
      confidence: 0.82
    })
    assert result[:event] != nil, "Engine produces event"
    assert result[:event][:interpretation] != nil, "Engine interprets event"
    assert result[:importance] > 0, "Engine scores importance"
    assert result[:priority] != :ignore, "Engine sets priority"
    assert length(result[:recommendations]) > 0, "Engine generates recommendations"
    IO.puts("9. ENGINE: priority=#{result[:priority]} recs=#{length(result[:recommendations])}")
  end

  defp test_noise_filtering do
    result = Tiannara.Sentinel.Activation.Engine.process(%{
      source: :runtime,
      category: :runtime,
      severity: :info,
      observation: "Minor fluctuation",
      confidence: 0.2
    })
    assert result[:priority] == :ignore, "Noise is ignored"
    assert result[:importance] == 0.0, "Noise importance is 0"
    assert result[:recommendations] == [], "Noise has no recommendations"
    IO.puts("10. NOISE: correctly filtered (priority=#{result[:priority]})")
  end
end

ActivationIntegrationTest.run()
