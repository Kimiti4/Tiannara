defmodule TiannaraRuntime.Cognitive.AttentionValidationTest do
  use ExUnit.Case, async: false
  @moduletag :attention_validation

  alias TiannaraRuntime.Cognitive.Engines.{
    AttentionManager, AttentionPolicy, AttentionQueue, AttentionBudget,
    PriorityEvaluator, ResourceAllocator, FocusState, AttentionReplay
  }

  describe "Tier 1 — Policy Evaluation" do
    test "evaluate returns score" do
      task = %{priority: 0.5, dependency_depth: 2, deadline: 500}
      criteria = AttentionPolicy.get_default_criteria()
      score = AttentionPolicy.evaluate(task, criteria)
      assert is_float(score)
      assert score >= 0
    end

    test "evaluate with higher priority gives higher score" do
      criteria = AttentionPolicy.get_default_criteria()
      low = AttentionPolicy.evaluate(%{priority: 0.1, dependency_depth: 1, deadline: :infinity}, criteria)
      high = AttentionPolicy.evaluate(%{priority: 0.9, dependency_depth: 1, deadline: :infinity}, criteria)
      assert high > low
    end

    test "get_default_criteria returns map" do
      criteria = AttentionPolicy.get_default_criteria()
      assert is_map(criteria)
      assert Map.has_key?(criteria, :priority_weight)
      assert Map.has_key?(criteria, :dependency_depth_weight)
      assert Map.has_key?(criteria, :deadline_urgency_weight)
    end
  end

  describe "Tier 2 — Queue Ordering" do
    test "enqueue sorts by score" do
      queue = AttentionQueue.new()
      {:ok, q1} = AttentionQueue.enqueue(queue, %{id: :low}, 1.0)
      {:ok, q2} = AttentionQueue.enqueue(q1, %{id: :high}, 10.0)
      {:ok, _rest, {high_task, high_score}} = AttentionQueue.dequeue(q2)
      assert high_score == 10.0
      assert high_task.id == :high
    end

    test "dequeue returns first item" do
      queue = AttentionQueue.new()
      {:ok, q} = AttentionQueue.enqueue(queue, %{id: :first}, 5.0)
      {:ok, q2} = AttentionQueue.enqueue(q, %{id: :second}, 3.0)
      assert {:ok, _state, {task, _score}} = AttentionQueue.dequeue(q2)
      assert task.id == :first
    end

    test "dequeue empty returns error" do
      queue = AttentionQueue.new()
      assert AttentionQueue.dequeue(queue) == {:error, :empty}
    end
  end

  describe "Tier 3 — Budget Allocation" do
    test "create sets total/available" do
      budget = AttentionBudget.new(%{cpu: 100, memory: 200})
      assert {:ok, 100} == AttentionBudget.total(budget, :cpu)
      assert {:ok, 100} == AttentionBudget.available(budget, :cpu)
      assert {:ok, 200} == AttentionBudget.total(budget, :memory)
    end

    test "consume deducts from available" do
      budget = AttentionBudget.new(%{cpu: 100, memory: 200})
      {:ok, b1} = AttentionBudget.consume(budget, :cpu, 30)
      assert {:ok, 70} == AttentionBudget.available(b1, :cpu)
      assert {:ok, 100} == AttentionBudget.total(b1, :cpu)
    end

    test "consume insufficient returns error" do
      budget = AttentionBudget.new(%{cpu: 10})
      assert {:error, :insufficient_budget} = AttentionBudget.consume(budget, :cpu, 20)
    end
  end

  describe "Tier 4 — Priority Stability" do
    test "evaluate same task twice gives same score" do
      task = %{priority: 0.7, dependency_depth: 3, deadline: 200}
      criteria = AttentionPolicy.get_default_criteria()
      s1 = PriorityEvaluator.evaluate(task, criteria)
      s2 = PriorityEvaluator.evaluate(task, criteria)
      assert s1 == s2
    end

    test "priority evaluator sorts by score" do
      tasks = [
        %{id: :low, priority: 0.1, dependency_depth: 1, deadline: :infinity},
        %{id: :high, priority: 0.9, dependency_depth: 1, deadline: :infinity},
        %{id: :mid, priority: 0.5, dependency_depth: 1, deadline: :infinity}
      ]
      sorted = PriorityEvaluator.sort_by_score(tasks)
      assert Enum.at(sorted, 0).id == :high
      assert Enum.at(sorted, 1).id == :mid
      assert Enum.at(sorted, 2).id == :low
    end
  end

  describe "Tier 5 — Replay Determinism" do
    test "record creates replay record" do
      _manager = AttentionManager.new()
      state = %{queue: AttentionQueue.new(), allocation: %{}, budget: %{cpu: 100}}
      assert {:ok, replay_record} = AttentionReplay.record(state)
      assert is_map(replay_record)
      assert Map.has_key?(replay_record, :fingerprint)
    end

    test "verify_ordering matches" do
      tasks = [
        %{id: :a, priority: 0.8, dependency_depth: 1, deadline: :infinity},
        %{id: :b, priority: 0.3, dependency_depth: 1, deadline: :infinity}
      ]
      criteria = AttentionPolicy.get_default_criteria()
      {:ok, result} = AttentionReplay.verify_ordering(tasks, criteria)
      assert length(result.ordered) == 2
      assert Enum.at(result.ordered, 0).id == :a
    end
  end

  describe "Tier 6 — Evidence Generation" do
    test "allocate returns allocation map" do
      budgets = %{cpu: 100, memory: 100, simulation: 50, mathematics: 50, research: 50, world_model: 50}
      {:ok, result} = AttentionManager.allocate([], budgets, %{})
      assert is_map(result)
      assert Map.has_key?(result, :allocation)
      assert Map.has_key?(result, :queue)
      assert Map.has_key?(result, :budget)
    end

    test "allocate returns all tasks scored" do
      tasks = [
        %{id: :a, priority: 0.5, dependency_depth: 1, deadline: :infinity},
        %{id: :b, priority: 0.3, dependency_depth: 1, deadline: :infinity},
        %{id: :c, priority: 0.7, dependency_depth: 1, deadline: :infinity}
      ]
      budgets = %{cpu: 100, memory: 100}
      {:ok, result} = AttentionManager.allocate(tasks, budgets, %{})
      assert map_size(result.allocation) == 3
    end
  end

  describe "Tier 7 — Resource Exhaustion" do
    test "allocate full budget exhausts resources" do
      tasks = [%{cpu: 100, memory: 0}]
      budgets = %{cpu: 100, memory: 100}
      {:ok, result} = ResourceAllocator.allocate(tasks, budgets)
      assert result.remaining[:cpu] == 0
    end

    test "release restores budget" do
      allocation = %{cpu: %{used: 50, available: 50}, memory: %{used: 30, available: 70}}
      {:ok, updated} = ResourceAllocator.release(allocation, :cpu, 20)
      assert updated.cpu.used == 30
      assert updated.cpu.available == 70
    end
  end

  describe "Tier 8 — Archaeology" do
    test "allocation_history tracks cycles" do
      manager = AttentionManager.new()
      {:ok, m1} = AttentionManager.record_history(manager, %{cycle: 1, tasks: [:a]})
      {:ok, m2} = AttentionManager.record_history(m1, %{cycle: 2, tasks: [:a, :b]})
      assert length(AttentionManager.allocation_history(m2)) == 2
    end

    test "focus state tracks active tasks" do
      focus = FocusState.new()
      queue = AttentionQueue.new()
      {:ok, q} = AttentionQueue.enqueue(queue, %{id: :task_a}, 5.0)
      {:ok, f} = FocusState.set(focus, q, %{cpu: 50})
      assert length(f.active_tasks) > 0
      assert Enum.at(f.active_tasks, 0).id == :task_a
    end
  end

  describe "Tier 9 — Failure Injection" do
    test "dequeue empty returns error" do
      queue = AttentionQueue.new()
      assert AttentionQueue.dequeue(queue) == {:error, :empty}
    end

    test "consume beyond budget returns error" do
      budget = AttentionBudget.new(%{cpu: 5})
      assert {:error, :insufficient_budget} = AttentionBudget.consume(budget, :cpu, 10)
    end

    test "allocate with empty tasks returns ok" do
      budgets = %{cpu: 100, memory: 100}
      assert {:ok, _result} = AttentionManager.allocate([], budgets, %{})
    end
  end

  describe "Tier 10 — Stress" do
    test "1000 allocations succeed" do
      tasks = Enum.map(1..1000, fn i ->
        %{id: i, priority: :rand.uniform() / 1000, dependency_depth: 1, deadline: :infinity}
      end)
      budgets = %{cpu: 100000, memory: 100000}
      {:ok, result} = AttentionManager.allocate(tasks, budgets, %{})
      assert length(result.scored_tasks) == 1000
    end

    test "budget rebalance resets available" do
      budget = AttentionBudget.new(%{cpu: 100, memory: 200})
      {:ok, b1} = AttentionBudget.consume(budget, :cpu, 70)
      {:ok, b2} = AttentionBudget.consume(b1, :memory, 50)
      {:ok, reb} = AttentionBudget.rebalance(b2)
      assert {:ok, 100} == AttentionBudget.available(reb, :cpu)
      assert {:ok, 200} == AttentionBudget.available(reb, :memory)
    end
  end
end
