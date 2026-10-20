defmodule TiannaraRuntime.Cognitive.Runtime.RuntimeValidationTest do
  use ExUnit.Case, async: false
  @moduletag :runtime

  alias TiannaraRuntime.Cognitive.Runtime.{
    CognitiveRuntime, MissionOrchestrator, ExecutionCoordinator,
    EvidenceRouter, ReplayCoordinator, ArchaeologyCoordinator
  }

  describe "Tier 1 — Runtime Orchestration" do
    test "initialize returns runtime with status :initialized" do
      assert {:ok, runtime} = CognitiveRuntime.initialize(%{max_missions: 10})
      assert runtime.status == :initialized
      assert runtime.config == %{max_missions: 10}
      assert runtime.missions == []
      assert runtime.subsystems == %{}
    end

    test "register_subsystem adds module to subsystems" do
      {:ok, runtime} = CognitiveRuntime.initialize(%{})
      assert {:ok, updated} = CognitiveRuntime.register_subsystem(runtime, :planner, MissionOrchestrator)
      assert updated.subsystems[:planner] == MissionOrchestrator
    end

    test "start_mission adds active mission to runtime" do
      {:ok, runtime} = CognitiveRuntime.initialize(%{})
      {:ok, {updated, mission}} = CognitiveRuntime.start_mission(runtime, "traj_1")
      assert mission.status == :active
      assert mission.trajectory_id == "traj_1"
      assert length(updated.missions) == 1
    end
  end

  describe "Tier 2 — Mission Lifecycle" do
    test "create_mission returns mission with status :created" do
      assert {:ok, mission} = MissionOrchestrator.create_mission("traj_a", %{})
      assert mission.status == :created
      assert mission.trajectory_id == "traj_a"
      assert mission.current_stage == nil
    end

    test "execute changes status to :active and sets current_stage" do
      {:ok, mission} = MissionOrchestrator.create_mission("traj_a", %{})
      assert {:ok, updated} = MissionOrchestrator.execute(mission)
      assert updated.status == :active
      assert updated.current_stage == :planning
    end

    test "complete changes status to :completed" do
      {:ok, mission} = MissionOrchestrator.create_mission("traj_a", %{})
      {:ok, executed} = MissionOrchestrator.execute(mission)
      assert {:ok, completed} = MissionOrchestrator.complete(executed)
      assert completed.status == :completed
      assert is_integer(completed.completed_at)
    end
  end

  describe "Tier 3 — Execution Coordination" do
    test "initialize returns state with phase :init and step 0" do
      mission = %{id: "m1"}
      assert {:ok, state} = ExecutionCoordinator.initialize(mission)
      assert state.mission_id == "m1"
      assert state.phase == :init
      assert state.step == 0
      assert state.status == :ready
    end

    test "execute_step increments step and substep" do
      mission = %{id: "m1"}
      {:ok, state} = ExecutionCoordinator.initialize(mission)
      assert {:ok, updated} = ExecutionCoordinator.execute_step(state, :step_1)
      assert updated.step == 1
      assert updated.substep == 1
      assert updated.status == :running
    end

    test "transition changes phase and resets step counters" do
      mission = %{id: "m1"}
      {:ok, state} = ExecutionCoordinator.initialize(mission)
      {:ok, stepped} = ExecutionCoordinator.execute_step(state, :step_1)
      assert {:ok, transitioned} = ExecutionCoordinator.transition(stepped, :execute)
      assert transitioned.phase == :execute
      assert transitioned.step == 0
      assert transitioned.substep == 0
    end
  end

  describe "Tier 4 — Evidence Routing" do
    test "route creates evidence with computed hashes" do
      assert {:ok, evidence} = EvidenceRouter.route(:planner, :planning, %{plan: "test"})
      assert evidence.subsystem == :planner
      assert evidence.stage == :planning
      assert is_binary(evidence.input_hash)
      assert is_binary(evidence.output_hash)
      assert evidence.evidence_data == %{plan: "test"}
    end

    test "verify returns true for valid evidence" do
      {:ok, evidence} = EvidenceRouter.route(:planner, :planning, %{plan: "test"})
      assert {:ok, true} = EvidenceRouter.verify(evidence)
    end

    test "append adds evidence to chain" do
      {:ok, evidence} = EvidenceRouter.route(:planner, :planning, %{plan: "test"})
      assert {:ok, chain} = EvidenceRouter.append([], evidence)
      assert length(chain) == 1
      assert hd(chain).id == evidence.id
    end
  end

  describe "Tier 5 — Mission Abort" do
    test "abort changes status to :aborted with reason" do
      {:ok, mission} = MissionOrchestrator.create_mission("traj_abort", %{})
      assert {:ok, aborted} = MissionOrchestrator.abort(mission, "simulation_failure")
      assert aborted.status == :aborted
      assert aborted.abort_reason == "simulation_failure"
    end

    test "advance_stage updates current_stage and appends to stages" do
      {:ok, mission} = MissionOrchestrator.create_mission("traj_adv", %{})
      {:ok, executed} = MissionOrchestrator.execute(mission)
      assert {:ok, advanced} = MissionOrchestrator.advance_stage(executed, :planning)
      assert advanced.current_stage == :planning
      assert advanced.stages == [:planning]
    end

    test "advance_stage multiple times accumulates stages" do
      {:ok, mission} = MissionOrchestrator.create_mission("traj_multi", %{})
      {:ok, m} = MissionOrchestrator.execute(mission)
      {:ok, m} = MissionOrchestrator.advance_stage(m, :planning)
      {:ok, m} = MissionOrchestrator.advance_stage(m, :execution)
      {:ok, m} = MissionOrchestrator.advance_stage(m, :review)
      assert m.stages == [:planning, :execution, :review]
      assert m.current_stage == :review
    end
  end

  describe "Tier 6 — Replay" do
    test "record creates replay with mission_root hash" do
      mission = %{id: "m1", status: :completed}
      subsystems = %{planner: MissionOrchestrator, executor: ExecutionCoordinator}
      assert {:ok, replay} = ReplayCoordinator.record(mission, subsystems)
      assert is_binary(replay.mission_root)
      assert map_size(replay.subsystem_hashes) == 2
      assert is_integer(replay.recorded_at)
    end

    test "verify passes for matching mission and subsystems" do
      mission = %{id: "m1", status: :completed}
      subsystems = %{planner: MissionOrchestrator}
      {:ok, replay} = ReplayCoordinator.record(mission, subsystems)
      assert {:ok, :verified} = ReplayCoordinator.verify(replay, mission, subsystems)
    end

    test "verify fails for modified mission" do
      mission = %{id: "m1", status: :completed}
      subsystems = %{planner: MissionOrchestrator}
      {:ok, replay} = ReplayCoordinator.record(mission, subsystems)
      modified = %{mission | status: :aborted}
      assert {:error, {:root, :mismatch}} = ReplayCoordinator.verify(replay, modified, subsystems)
    end
  end

  describe "Tier 7 — Archaeology" do
    test "record creates archaeology with origin and narrative" do
      mission = %{id: "m1", status: :completed, stages: [:planning, :execution]}
      evidence_chain = [%{id: "ev_1"}, %{id: "ev_2"}]
      replay = %{mission_root: "abc123"}
      assert {:ok, archaeology} = ArchaeologyCoordinator.record(mission, evidence_chain, replay)
      assert String.contains?(archaeology.origin, "m1")
      assert archaeology.replay_verification == :recorded
    end

    test "explain returns formatted string" do
      mission = %{id: "m1", status: :completed, stages: [:planning]}
      evidence_chain = [%{id: "ev_1"}]
      replay = %{mission_root: "abc"}
      {:ok, archaeology} = ArchaeologyCoordinator.record(mission, evidence_chain, replay)
      assert {:ok, explanation} = ArchaeologyCoordinator.explain(archaeology)
      assert is_binary(explanation)
      assert String.contains?(explanation, "m1")
    end

    test "summarize returns counts" do
      mission = %{id: "m1", status: :completed, stages: [:planning, :execution]}
      evidence_chain = [%{id: "ev_1"}, %{id: "ev_2"}, %{id: "ev_3"}]
      replay = %{}
      {:ok, archaeology} = ArchaeologyCoordinator.record(mission, evidence_chain, replay)
      assert {:ok, summary} = ArchaeologyCoordinator.summarize(archaeology)
      assert summary.stages == 2
      assert summary.evidence_count == 3
      assert summary.origin == "mission_m1"
    end
  end

  describe "Tier 8 — Link Subsystems" do
    test "link_subsystem :plan updates plan_id" do
      {:ok, mission} = MissionOrchestrator.create_mission("traj_link", %{})
      assert {:ok, updated} = MissionOrchestrator.link_subsystem(mission, :plan, "plan_abc")
      assert updated.plan_id == "plan_abc"
    end

    test "link_subsystem :decision updates decision_id" do
      {:ok, mission} = MissionOrchestrator.create_mission("traj_link", %{})
      assert {:ok, updated} = MissionOrchestrator.link_subsystem(mission, :decision, "dec_123")
      assert updated.decision_id == "dec_123"
    end

    test "link_subsystem :meta updates meta_id" do
      {:ok, mission} = MissionOrchestrator.create_mission("traj_link", %{})
      assert {:ok, updated} = MissionOrchestrator.link_subsystem(mission, :meta, "meta_xyz")
      assert updated.meta_id == "meta_xyz"
    end
  end

  describe "Tier 9 — Failure Injection" do
    test "get_mission returns :not_found for nonexistent" do
      {:ok, runtime} = CognitiveRuntime.initialize(%{})
      assert {:error, :not_found} = CognitiveRuntime.get_mission(runtime, "nonexistent")
    end

    test "execute_step with nil state raises BadMapError" do
      assert_raise BadMapError, fn ->
        ExecutionCoordinator.execute_step(nil, :step_1)
      end
    end

    test "list_missions returns empty list for fresh runtime" do
      {:ok, runtime} = CognitiveRuntime.initialize(%{})
      assert {:ok, []} = CognitiveRuntime.list_missions(runtime)
    end
  end

  describe "Tier 10 — Stress" do
    test "100 missions through CognitiveRuntime" do
      {:ok, runtime} = CognitiveRuntime.initialize(%{})
      result =
        Enum.reduce(1..100, runtime, fn i, runtime_acc ->
          {:ok, {updated, _mission}} = CognitiveRuntime.start_mission(runtime_acc, "traj_#{i}")
          updated
        end)
      assert {:ok, missions} = CognitiveRuntime.list_missions(result)
      assert length(missions) == 100
    end

    test "mission recycling — create, execute, complete, abort cycle" do
      {:ok, runtime} = CognitiveRuntime.initialize(%{})
      {:ok, {runtime, mission}} = CognitiveRuntime.start_mission(runtime, "cycle_1")
      {:ok, executed} = MissionOrchestrator.execute(mission)
      {:ok, completed} = MissionOrchestrator.complete(executed)
      assert completed.status == :completed

      {:ok, {runtime, mission2}} = CognitiveRuntime.start_mission(runtime, "cycle_2")
      {:ok, aborted} = MissionOrchestrator.abort(mission2, "stress_abort")
      assert aborted.status == :aborted

      assert {:ok, summary} = CognitiveRuntime.summary(runtime)
      assert summary.mission_count == 2
    end

    test "summary returns correct counts after multiple missions" do
      {:ok, runtime} = CognitiveRuntime.initialize(%{})
      {:ok, {r1, m1}} = CognitiveRuntime.start_mission(runtime, "s_1")
      {:ok, {r2, _m2}} = CognitiveRuntime.start_mission(r1, "s_2")
      {:ok, {r3, _m3}} = CognitiveRuntime.start_mission(r2, "s_3")
      assert {:ok, summary} = CognitiveRuntime.summary(r3)
      assert summary.mission_count == 3
    end
  end
end
