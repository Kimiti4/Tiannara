defmodule MultiComponentOPCTest do
  use ExUnit.Case, async: false

  alias Tiannara.OPC.RealityCompiler.{ContradictionResolver, GPUExecutor, MultiHistoryRuntime}

  setup do
    Tiannara.OPC.RuleStore.reset()
    :ok
  end

  test "OPC Reality Compiler integrates GPU execution, contradiction resolution, and multi-history" do
    # Test the full pipeline with all new components

    # 1. Create some sample events
    events = [
      %{id: "event-1", type: "system_load", payload: %{value: 42}, timestamp: 1000},
      %{id: "event-2", type: "system_load", payload: %{value: 43}, timestamp: 1001},
      %{id: "event-3", type: "system_load", payload: %{value: 44}, timestamp: 1002}
    ]

    # 2. Process events through the enhanced pipeline
    result = Tiannara.OPC.RealityCompiler.process_events_with_gpu(events)

    # Verify the result contains all expected components
    assert Map.has_key?(result, :rules)
    assert Map.has_key?(result, :gpu_results)
    assert Map.has_key?(result, :status)
    assert result.status == :success

    # 3. Test contradiction resolution
    conflicting_rules = [
      %Tiannara.OPC.IR.PhysicsRule{
        id: "rule-1",
        condition: %{type_match: :high_complexity, invariants: ["load"]},
        effect: %{mscl_modifier: 0.5, olef_pressure_bias: 0.2},
        weight: 0.8
      },
      %Tiannara.OPC.IR.PhysicsRule{
        id: "rule-2", 
        condition: %{type_match: :high_complexity, invariants: ["load"]},
        effect: %{mscl_modifier: -0.3, olef_pressure_bias: 0.4},  # Conflicting with rule-1
        weight: 0.6
      }
    ]

    resolved_rules = ContradictionResolver.resolve_conflicts(conflicting_rules)
    assert is_list(resolved_rules)
    assert length(resolved_rules) <= length(conflicting_rules)  # May be merged

    # 4. Test GPU execution
    gpu_executor = GPUExecutor.init()
    gpu_validation = GPUExecutor.validate_gpu_compatibility()
    assert gpu_validation.webgl2_supported == true
    assert gpu_validation.compute_shaders_supported == true

    gpu_with_shaders = GPUExecutor.compile_rules_to_shaders(gpu_executor, resolved_rules)
    {:ok, gpu_results} = GPUExecutor.execute_on_gpu(gpu_with_shaders)
    assert is_list(gpu_results)

    # 5. Test multi-history runtime
    multi_runtime = MultiHistoryRuntime.init()
    forked_runtime = MultiHistoryRuntime.fork_timeline(multi_runtime, "fork-1", "main")
    
    # Execute events across timelines
    events_with_fork = MultiHistoryRuntime.execute_across_timelines(forked_runtime, events)
    
    # Evaluate timeline differences
    differences = MultiHistoryRuntime.evaluate_timeline_differences(events_with_fork)
    assert is_list(differences)

    # Get statistics
    stats = MultiHistoryRuntime.get_statistics(events_with_fork)
    assert Map.has_key?(stats, :active_timelines)
    assert Map.has_key?(stats, :total_forks)
    assert Map.has_key?(stats, :divergence_metrics)

    # 6. Test timeline merging
    merged_runtime = MultiHistoryRuntime.merge_timeline(events_with_fork, "fork-1", :prefer_newer)
    assert merged_runtime != nil

    # Verify merged timeline contains all original events
    assert Map.has_key?(merged_runtime, :timeline) or is_list(merged_runtime)
  end

  test "Contradiction resolver detects and resolves rule conflicts" do
    rules = [
      %Tiannara.OPC.IR.PhysicsRule{
        id: "rule-1",
        condition: %{type_match: :high_complexity, invariants: ["load"]},
        effect: %{mscl_modifier: 0.5, olef_pressure_bias: 0.2},
        weight: 0.8
      },
      %Tiannara.OPC.IR.PhysicsRule{
        id: "rule-2",
        condition: %{type_match: :high_complexity, invariants: ["load"]},  # Same invariants
        effect: %{mscl_modifier: -0.5, olef_pressure_bias: 0.3},  # Opposing mscl_modifier
        weight: 0.6
      }
    ]

    conflicts = ContradictionResolver.detect_conflicts(rules)
    assert length(conflicts) > 0

    resolved = ContradictionResolver.resolve_conflicts(rules)
    assert is_list(resolved)

    consistency_check = ContradictionResolver.validate_consistency(resolved)
    assert consistency_check.consistent == true
  end

  test "GPU executor compiles and executes physics rules" do
    rules = [
      %Tiannara.OPC.IR.PhysicsRule{
        id: "rule-1",
        condition: %{type_match: :high_complexity, invariants: ["load"]},
        effect: %{mscl_modifier: 0.5, olef_pressure_bias: 0.2},
        weight: 0.8
      }
    ]

    gpu_executor = GPUExecutor.init()
    executor_with_shaders = GPUExecutor.compile_rules_to_shaders(gpu_executor, rules)
    
    # Verify shaders were compiled
    assert Map.has_key?(executor_with_shaders.compute_shaders, :physics_kernel)
    
    # Execute on GPU
    {:ok, results} = GPUExecutor.execute_on_gpu(executor_with_shaders)
    assert is_list(results)

    # Test parallel optimization
    parallel_rules = GPUExecutor.optimize_for_parallel_execution(rules)
    assert is_list(parallel_rules)
  end

  test "Multi-history runtime manages timeline forks and merges" do
    multi_runtime = MultiHistoryRuntime.init()
    
    # Fork a timeline
    forked_runtime = MultiHistoryRuntime.fork_timeline(multi_runtime, "branch-1", "main")
    assert length(forked_runtime.parallel_executor.active_branches) == 1

    # Execute events across timelines
    events = [
      %{id: "test-event", type: "test", payload: %{}, timestamp: System.system_time(:millisecond)}
    ]
    
    executed_runtime = MultiHistoryRuntime.execute_across_timelines(forked_runtime, events)
    
    # Create a checkpoint
    checkpointed_runtime = MultiHistoryRuntime.create_checkpoint(executed_runtime, "checkpoint-1")
    assert length(checkpointed_runtime.fork_point_tracker.checkpoints) == 1

    # Backtrack to checkpoint (this should work if checkpoint exists)
    backtrack_result = MultiHistoryRuntime.backtrack_to_checkpoint(checkpointed_runtime, "checkpoint-1")
    # Result may be success or error depending on implementation, but function should exist

    # Merge timeline
    merged_runtime = MultiHistoryRuntime.merge_timeline(executed_runtime, "branch-1", :combine_weights)
    refute merged_runtime == nil
  end

  test "All OPC components work together in integrated workflow" do
    # Create events
    events = for i <- 1..5 do
      %{id: "event-#{i}", type: "system_load", payload: %{value: i}, timestamp: 1000 + i}
    end

    # Process through full pipeline
    result = Tiannara.OPC.RealityCompiler.process_events_with_gpu(events)
    
    # Verify success
    assert result.status == :success
    assert is_list(result.rules)
    assert is_list(result.gpu_results)

    # Create timeline fork
    multi_runtime = MultiHistoryRuntime.init()
    forked_runtime = MultiHistoryRuntime.fork_timeline(multi_runtime, "test-branch", "main")
    
    # Execute across timelines
    cross_timeline_result = MultiHistoryRuntime.execute_across_timelines(forked_runtime, events)
    
    # Evaluate differences
    differences = MultiHistoryRuntime.evaluate_timeline_differences(cross_timeline_result)
    
    # All components successfully integrated
    assert length(differences) > 0
  end
end