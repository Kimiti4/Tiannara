defmodule Tiannara.Executive.Cognitive.ECRTest do
  use ExUnit.Case, async: false

  alias Tiannara.Executive.Cognitive.{
    ExecutiveBlackboard, WorkingMemory, ContextManager,
    AttentionScheduler, HeartbeatEngine, ExecutiveCycle,
    ReflectionEngine, ExecutiveCognitiveRuntime
  }

  describe "ExecutiveBlackboard" do
    test "post and read entries" do
      :ok = ExecutiveBlackboard.post(:observations, %{id: 1, value: "test"})
      entries = ExecutiveBlackboard.read(:observations)
      assert length(entries) == 1
      assert hd(entries).id == 1
    end

    test "read_latest returns most recent" do
      ExecutiveBlackboard.post(:metrics, %{cycle: 1})
      ExecutiveBlackboard.post(:metrics, %{cycle: 2})
      assert ExecutiveBlackboard.read_latest(:metrics).cycle == 2
    end

    test "topics returns all topics" do
      ExecutiveBlackboard.post(:a, 1)
      ExecutiveBlackboard.post(:b, 2)
      assert :a in ExecutiveBlackboard.topics()
      assert :b in ExecutiveBlackboard.topics()
    end

    test "clear_topic removes all entries" do
      ExecutiveBlackboard.post(:temp, "value")
      ExecutiveBlackboard.clear_topic(:temp)
      assert ExecutiveBlackboard.read(:temp) == []
    end

    test "status returns counts" do
      ExecutiveBlackboard.post(:x, 1)
      ExecutiveBlackboard.read(:x)
      status = ExecutiveBlackboard.status()
      assert status.total_posts >= 1
      assert status.total_reads >= 1
    end

    test "max entries per topic is enforced" do
      for i <- 1..150 do
        ExecutiveBlackboard.post(:overflow, i)
      end
      assert length(ExecutiveBlackboard.read(:overflow)) == 100
    end
  end

  describe "WorkingMemory" do
    test "store and retrieve" do
      WorkingMemory.store(:test_key, %{data: "hello"})
      assert WorkingMemory.retrieve(:test_key) == %{data: "hello"}
    end

    test "retrieve missing key returns nil" do
      assert WorkingMemory.retrieve(:nonexistent) == nil
    end

    test "clear removes all data" do
      WorkingMemory.store(:a, 1)
      WorkingMemory.store(:b, 2)
      WorkingMemory.clear()
      assert WorkingMemory.retrieve(:a) == nil
      assert WorkingMemory.retrieve(:b) == nil
    end

    test "slots returns stored keys" do
      WorkingMemory.store(:x, 10)
      WorkingMemory.store(:y, 20)
      assert :x in WorkingMemory.slots()
      assert :y in WorkingMemory.slots()
    end

    test "overwrite updates value" do
      WorkingMemory.store(:k, "first")
      WorkingMemory.store(:k, "second")
      assert WorkingMemory.retrieve(:k) == "second"
    end
  end

  describe "ContextManager" do
    test "interpret returns structured context" do
      obs = [%{type: :system_health, value: %{status: :ok}}, %{type: :anomaly, value: %{severity: :high}}]
      context = ContextManager.interpret(obs)
      assert context.observations_count == 2
      assert context.overall_urgency > 0.5
      assert context.confidence == 0.85
    end

    test "current_context returns last interpreted context" do
      ContextManager.interpret([%{type: :test}])
      ctx = ContextManager.current_context()
      assert ctx.observations_count >= 0
    end

    test "status returns interpretation count" do
      ContextManager.interpret([%{type: :a}])
      ContextManager.interpret([%{type: :b}])
      assert ContextManager.status().interpretations_count >= 2
    end

    test "empty observations produces empty context" do
      context = ContextManager.interpret([])
      assert context.observations_count == 0
      assert context.overall_urgency == 0.0
    end

    test "urgency mapping for different types" do
      anomaly_ctx = ContextManager.interpret([%{type: :anomaly}])
      health_ctx = ContextManager.interpret([%{type: :system_health}])
      assert anomaly_ctx.overall_urgency > health_ctx.overall_urgency
    end
  end

  describe "AttentionScheduler" do
    test "prioritize returns sorted priorities" do
      context = %{urgency: %{critical: %{count: 1, urgency: 0.9}, low: %{count: 5, urgency: 0.2}}}
      priorities = AttentionScheduler.prioritize(context)
      assert length(priorities) == 2
      assert hd(priorities).priority >= List.last(priorities).priority
    end

    test "queue returns current priorities" do
      AttentionScheduler.prioritize(%{urgency: %{a: %{count: 1, urgency: 0.5}}})
      assert length(AttentionScheduler.queue()) == 1
    end

    test "active_count returns queue length" do
      AttentionScheduler.prioritize(%{urgency: %{b: %{count: 1, urgency: 0.5}, c: %{count: 1, urgency: 0.3}}})
      assert AttentionScheduler.active_count() == 2
    end

    test "prioritize with empty context returns empty list" do
      assert AttentionScheduler.prioritize(%{}) == []
    end

    test "priority ordering is deterministic" do
      ctx = %{urgency: %{high: %{count: 1, urgency: 0.9}, medium: %{count: 1, urgency: 0.5}, low: %{count: 1, urgency: 0.1}}}
      p1 = AttentionScheduler.prioritize(ctx)
      p2 = AttentionScheduler.prioritize(ctx)
      assert Enum.map(p1, & &1.target) == Enum.map(p2, & &1.target)
    end
  end

  describe "HeartbeatEngine" do
    test "status returns engine state" do
      status = HeartbeatEngine.status()
      assert status.interval_ms == 5_000
      assert status.beat_count >= 0
      assert status.started_at
    end

    test "uptime_seconds returns positive integer" do
      assert is_integer(HeartbeatEngine.uptime_seconds())
      assert HeartbeatEngine.uptime_seconds() >= 0
    end

    test "trigger sends heartbeat" do
      assert HeartbeatEngine.trigger() == :ok
    end
  end

  describe "ExecutiveCycle" do
    test "status returns valid phase" do
      status = ExecutiveCycle.status()
      assert status.current_phase in [:observe, :interpret, :prioritize, :investigate, :plan, :execute, :validate, :learn]
      assert status.cycles_completed >= 0
    end

    test "advance moves through phases" do
      status1 = ExecutiveCycle.status()
      assert :ok = ExecutiveCycle.advance()
      Process.sleep(10)
      status2 = ExecutiveCycle.status()
      assert status2.current_phase != status1.current_phase
    end

    test "cycles_completed returns count" do
      assert is_integer(ExecutiveCycle.cycles_completed())
    end

    test "advance eight times completes one cycle" do
      start = ExecutiveCycle.cycles_completed()
      for _ <- 1..8, do: ExecutiveCycle.advance()
      Process.sleep(10)
      assert ExecutiveCycle.cycles_completed() >= start + 1
    end
  end

  describe "ReflectionEngine" do
    test "reflect generates structured reflection" do
      ReflectionEngine.reflect()
      Process.sleep(10)
      reflection = ReflectionEngine.last_reflection()
      assert reflection != nil
      assert reflection.id
      assert reflection.assumptions
      assert reflection.bottlenecks
      assert reflection.next_experiments
      assert reflection.confidence == 0.7
    end

    test "status returns reflection count" do
      ReflectionEngine.reflect()
      ReflectionEngine.reflect()
      assert ReflectionEngine.status().total_reflections >= 2
    end

    test "last_reflection is the most recent" do
      ReflectionEngine.reflect()
      r1 = ReflectionEngine.last_reflection()
      ReflectionEngine.reflect()
      r2 = ReflectionEngine.last_reflection()
      assert r2.timestamp >= r1.timestamp
    end
  end

  describe "ExecutiveCognitiveRuntime" do
    test "status returns all subsystem statuses" do
      s = ExecutiveCognitiveRuntime.status()
      assert s.heartbeat
      assert s.cycle
      assert s.attention
      assert s.working_memory
      assert s.reflection
      assert s.blackboard
    end

    test "health returns runtime health map" do
      h = ExecutiveCognitiveRuntime.health()
      assert h.status == :healthy
      assert is_integer(h.uptime_seconds)
      assert is_integer(h.cycles_completed)
      assert h.active_attentions >= 0
    end
  end
end
