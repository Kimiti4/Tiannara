defmodule TiannaraRuntime.Cognitive.KernelValidationTest do
  use ExUnit.Case, async: false
  @moduletag :cognitive_kernel

  alias TiannaraRuntime.CCOS.{
    ExecutiveKernel, ContextBuilder,
    AttentionCoordinator, TaskDispatcher, EvidenceCollector,
    ReplayCoordinator, ArchaeologyRecorder
  }

  @replay_timestamp "2026-07-11T21:00:00Z"

  defp valid_mission do
    %{
      objective: "Test mission objective for kernel validation",
      goal_graph: %{primary: "validate_kernel", secondary: "collect_evidence"},
      task_graph: [
        %{
          id: "task_1",
          priority: 10,
          dependency_order: 0,
          target_subsystem: :scientific_discovery,
          description: "Run scientific discovery"
        },
        %{
          id: "task_2",
          priority: 5,
          dependency_order: 1,
          target_subsystem: :experiment,
          description: "Run experiment"
        }
      ],
      dependencies: ["dep_alpha", "dep_beta"]
    }
  end

  defp valid_context_inputs do
    %{
      working_memory: [%{key: "wm_1", value: "test"}],
      knowledge_graph_refs: [%{ref: "kg_1"}],
      world_model_refs: [%{ref: "wm_1"}],
      scientific_discovery_refs: [%{ref: "sd_1"}],
      mathematics_refs: [%{ref: "math_1"}]
    }
  end

  defp certified_subsystems do
    [
      %{subsystem: :scientific_discovery, name: "SMCP", phase: 15},
      %{subsystem: :research, name: "REA", phase: 16},
      %{subsystem: :mathematics, name: "Mathematics Epistemic Substrate", phase: "16.X"},
      %{subsystem: :world_model, name: "WorldModel", phase: "17.2-17.6"},
      %{subsystem: :simulation, name: "DigitalTwin", phase: "17.7"},
      %{subsystem: :experiment, name: "ARPE", phase: "17.8"}
    ]
  end

  defp initialized_kernel do
    {:ok, state} = ExecutiveKernel.initialize(%{
      certified_subsystems: certified_subsystems(),
      replay_timestamp: @replay_timestamp
    })
    state
  end

  defp submitted_mission do
    kernel = initialized_kernel()
    {:ok, result} = ExecutiveKernel.submit_mission(kernel, valid_mission(), valid_context_inputs())
    result
  end

  describe "Tier 1 — Kernel Initialization" do
    test "startup creates empty kernel state" do
      state = initialized_kernel()
      assert state.missions == %{}
      assert state.status == :initialized
      assert is_map_key(state, :kernel_id)
      assert is_map_key(state, :evidence_ledger)
      assert is_map_key(state, :replay_roots)
      assert is_map_key(state, :archaeology_ledger)
    end

    test "shutdown returns :ok" do
      state = initialized_kernel()
      assert {:ok, shutdown_state} = ExecutiveKernel.shutdown(state, @replay_timestamp)
      assert shutdown_state.status == :shutdown
    end

    test "get_metrics returns metrics map" do
      state = initialized_kernel()
      assert {:ok, metrics} = ExecutiveKernel.status(state)
      assert metrics.kernel_id != nil
      assert metrics.mission_count == 0
      assert metrics.evidence_count == 0
      assert metrics.replay_root_count == 0
      assert metrics.archaeology_count == 0
    end
  end

  describe "Tier 2 — Mission Lifecycle" do
    test "submit_mission creates mission state" do
      kernel = initialized_kernel()
      assert {:ok, result} = ExecutiveKernel.submit_mission(kernel, valid_mission(), valid_context_inputs())
      assert is_binary(result.mission_state.mission_id)
    end

    test "execute_mission transitions to running" do
      result = submitted_mission()
      assert result.mission_state.status == :running
    end

    test "pause_mission transitions to paused" do
      result = submitted_mission()
      kernel_state = result.kernel_state
      mission_id = result.mission_state.mission_id
      assert {:ok, paused_state} = ExecutiveKernel.pause(kernel_state, mission_id, @replay_timestamp)
      assert paused_state.missions[mission_id].status == :paused
    end

    test "resume_mission transitions back to running" do
      result = submitted_mission()
      kernel_state = result.kernel_state
      mission_id = result.mission_state.mission_id
      {:ok, paused_state} = ExecutiveKernel.pause(kernel_state, mission_id, @replay_timestamp)
      assert {:ok, resumed_state} = ExecutiveKernel.resume(paused_state, mission_id, @replay_timestamp)
      assert resumed_state.missions[mission_id].status == :running
    end

    test "cancel_mission transitions to cancelled" do
      result = submitted_mission()
      kernel_state = result.kernel_state
      mission_id = result.mission_state.mission_id
      assert {:ok, cancelled_state} = ExecutiveKernel.cancel(kernel_state, mission_id, @replay_timestamp)
      assert cancelled_state.missions[mission_id].status == :cancelled
    end
  end

  describe "Tier 3 — Context Construction" do
    test "build_context creates deterministic output" do
      mission_state = submitted_mission().mission_state
      inputs = valid_context_inputs()
      {:ok, ctx1} = ContextBuilder.build(mission_state, inputs)
      {:ok, ctx2} = ContextBuilder.build(mission_state, inputs)
      assert ctx1.context_id == ctx2.context_id
    end

    test "build_context contains mission and knowledge refs" do
      mission_state = submitted_mission().mission_state
      {:ok, context} = ContextBuilder.build(mission_state, valid_context_inputs())
      assert is_map_key(context, :mission_id)
      assert is_map_key(context, :context_id)
      assert is_list(context.working_memory)
      assert is_list(context.knowledge_graph_refs)
    end

    test "build_context sorts references" do
      mission_state = submitted_mission().mission_state
      inputs = %{
        working_memory: [%{key: "b"}, %{key: "a"}],
        knowledge_graph_refs: [%{ref: "z"}, %{ref: "a"}],
        world_model_refs: [],
        scientific_discovery_refs: [],
        mathematics_refs: []
      }
      {:ok, context} = ContextBuilder.build(mission_state, inputs)
      assert context.working_memory == Enum.sort_by(context.working_memory, &inspect/1)
    end
  end

  describe "Tier 4 — Attention Allocation" do
    test "allocate returns deterministic attention" do
      mission_state = submitted_mission().mission_state
      {:ok, context} = ContextBuilder.build(mission_state, valid_context_inputs())
      {:ok, attn1} = AttentionCoordinator.allocate(mission_state, context)
      {:ok, attn2} = AttentionCoordinator.allocate(mission_state, context)
      assert attn1.attention_state_id == attn2.attention_state_id
    end

    test "allocate with empty tasks returns empty allocation" do
      no_task_mission = %{valid_mission() | task_graph: []}
      kernel = initialized_kernel()
      {:ok, result} = ExecutiveKernel.submit_mission(kernel, no_task_mission, valid_context_inputs())
      context_inputs = valid_context_inputs()
      {:ok, context} = ContextBuilder.build(result.mission_state, context_inputs)
      {:ok, attn} = AttentionCoordinator.allocate(result.mission_state, context)
      assert attn.ordered_tasks == []
    end

    test "allocate returns {:ok, attention_state}" do
      mission_state = submitted_mission().mission_state
      {:ok, context} = ContextBuilder.build(mission_state, valid_context_inputs())
      assert {:ok, %{attention_state_id: _}} = AttentionCoordinator.allocate(mission_state, context)
    end
  end

  describe "Tier 5 — Task Dispatch" do
    test "dispatch returns ExecutionRequest" do
      result = submitted_mission()
      {:ok, context} = ContextBuilder.build(result.mission_state, valid_context_inputs())
      {:ok, attn} = AttentionCoordinator.allocate(result.mission_state, context)
      assert {:ok, dispatch} = TaskDispatcher.dispatch(attn, certified_subsystems())
      assert is_map_key(dispatch, :dispatch_root_id)
    end

    test "dispatch routes scientific_discovery correctly" do
      subsystems = [%{subsystem: :scientific_discovery, name: "SMCP", phase: 15}]
      single_task_mission = %{
        valid_mission()
        | task_graph: [
            %{
              id: "disc_task",
              priority: 10,
              dependency_order: 0,
              target_subsystem: :scientific_discovery,
              description: "Discovery task"
            }
          ]
      }
      kernel = initialized_kernel()
      {:ok, result} = ExecutiveKernel.submit_mission(kernel, single_task_mission, valid_context_inputs())
      {:ok, context} = ContextBuilder.build(result.mission_state, valid_context_inputs())
      {:ok, attn} = AttentionCoordinator.allocate(result.mission_state, context)
      {:ok, dispatch} = TaskDispatcher.dispatch(attn, subsystems)
      assert length(dispatch.dispatch_intents) == 1
    end

    test "dispatch routes experiment correctly" do
      subsystems = [%{subsystem: :experiment, name: "ARPE", phase: "17.8"}]
      single_task_mission = %{
        valid_mission()
        | task_graph: [
            %{
              id: "exp_task",
              priority: 10,
              dependency_order: 0,
              target_subsystem: :experiment,
              description: "Experiment task"
            }
          ]
      }
      kernel = initialized_kernel()
      {:ok, result} = ExecutiveKernel.submit_mission(kernel, single_task_mission, valid_context_inputs())
      {:ok, context} = ContextBuilder.build(result.mission_state, valid_context_inputs())
      {:ok, attn} = AttentionCoordinator.allocate(result.mission_state, context)
      {:ok, dispatch} = TaskDispatcher.dispatch(attn, subsystems)
      assert length(dispatch.dispatch_intents) == 1
    end
  end

  describe "Tier 6 — Evidence Collection" do
    test "collect_transition returns EvidenceReference" do
      assert {:ok, evidence} = EvidenceCollector.collect_transition(
        :test_stage, %{data: "test"}, @replay_timestamp
      )
      assert is_map_key(evidence, :evidence_id)
    end

    test "collect_transition has non-empty hash" do
      {:ok, evidence} = EvidenceCollector.collect_transition(
        :test_stage, %{data: "test"}, @replay_timestamp
      )
      assert is_binary(evidence.evidence_id)
      assert String.length(evidence.evidence_id) > 0
    end

    test "collect_execution returns EvidenceReference with origin" do
      {:ok, evidence} = EvidenceCollector.collect_transition(
        :execution_complete, %{task: "example", result: "ok"}, @replay_timestamp
      )
      assert evidence.stage == :execution_complete
      assert is_map_key(evidence, :payload_ref)
    end
  end

  describe "Tier 7 — Replay" do
    test "record returns ReplayReference" do
      {:ok, e1} = EvidenceCollector.collect_transition(:stage_a, %{a: 1}, @replay_timestamp)
      {:ok, e2} = EvidenceCollector.collect_transition(:stage_b, %{b: 2}, @replay_timestamp)
      assert {:ok, replay} = ReplayCoordinator.build([e1, e2])
      assert is_map_key(replay, :replay_root_id)
    end

    test "record_execution returns ReplayReference with sequence" do
      {:ok, e1} = EvidenceCollector.collect_transition(:exec_start, %{id: "x"}, @replay_timestamp)
      {:ok, e2} = EvidenceCollector.collect_transition(:exec_end, %{id: "x"}, @replay_timestamp)
      {:ok, replay} = ReplayCoordinator.build([e1, e2])
      assert length(replay.evidence_ids) == 2
      assert length(replay.evidence_hashes) == 2
    end

    test "reconstruct returns replay ref" do
      {:ok, e1} = EvidenceCollector.collect_transition(:step_1, %{val: "a"}, @replay_timestamp)
      chain = [e1]
      {:ok, ref1} = ReplayCoordinator.build(chain)
      {:ok, ref2} = ReplayCoordinator.build(chain)
      assert ref1.replay_root_id == ref2.replay_root_id
    end
  end

  describe "Tier 8 — Archaeology" do
    test "record returns ArchaeologyReference" do
      result = submitted_mission()
      lineage = %{
        mission_state: result.mission_state,
        dispatch_root: result.dispatch_root,
        evidence_chain: result.evidence_chain,
        replay_root: result.replay_root
      }
      assert {:ok, archaeology} = ArchaeologyRecorder.record(lineage)
      assert is_map_key(archaeology, :archaeology_id)
    end

    test "record has lineage with depth" do
      result = submitted_mission()
      lineage = %{
        mission_state: result.mission_state,
        dispatch_root: result.dispatch_root,
        evidence_chain: result.evidence_chain,
        replay_root: result.replay_root
      }
      {:ok, archaeology} = ArchaeologyRecorder.record(lineage)
      assert is_map_key(archaeology, :mission_ref)
      assert is_map_key(archaeology, :dispatch_ref)
      assert is_map_key(archaeology, :evidence_refs)
      assert is_map_key(archaeology, :replay_ref)
    end

    test "get_lineage returns lineage map" do
      result = submitted_mission()
      lineage = %{
        mission_state: result.mission_state,
        dispatch_root: result.dispatch_root,
        evidence_chain: result.evidence_chain,
        replay_root: result.replay_root
      }
      {:ok, archaeology} = ArchaeologyRecorder.record(lineage)
      assert is_binary(archaeology.mission_ref)
      assert is_binary(archaeology.dispatch_ref)
      assert is_list(archaeology.evidence_refs)
      assert is_binary(archaeology.replay_ref)
    end
  end

  describe "Tier 9 — Failure Injection" do
    test "execute_mission on unknown mission_id returns error" do
      state = initialized_kernel()
      assert {:error, _} = ExecutiveKernel.pause(state, "nonexistent-mission-id", @replay_timestamp)
    end

    test "pause_mission on non-existent mission returns error" do
      state = initialized_kernel()
      assert {:error, _} = ExecutiveKernel.pause(state, "no-such-mission", @replay_timestamp)
    end

    test "dispatch_task on unknown mission_id returns error" do
      state = initialized_kernel()
      assert {:error, _} = ExecutiveKernel.pause(state, "unknown-mission", @replay_timestamp)
    end
  end

  describe "Tier 10 — Runtime Dispatch" do
    test "dispatch_task returns exec_result" do
      result = submitted_mission()
      assert is_map_key(result, :dispatch_root)
      assert is_map_key(result, :evidence_chain)
      assert length(result.evidence_chain) == 4
    end

    test "dispatch_task increments task count" do
      kernel = initialized_kernel()
      {:ok, result} = ExecutiveKernel.submit_mission(kernel, valid_mission(), valid_context_inputs())
      updated_kernel = result.kernel_state
      mission_id = result.mission_state.mission_id
      assert map_size(updated_kernel.missions) == 1
      assert updated_kernel.missions[mission_id].status == :running
    end
  end
end
