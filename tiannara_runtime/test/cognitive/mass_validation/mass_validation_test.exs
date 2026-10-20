defmodule TiannaraRuntime.Cognitive.Runtime.MassValidationTest do
  use ExUnit.Case, async: false
  @moduletag :mass_validation
  @tag timeout: 120000

  alias TiannaraRuntime.Cognitive.Runtime.{CognitiveRuntime, MissionOrchestrator, EvidenceRouter, ReplayCoordinator, ArchaeologyCoordinator}

  describe "10k mission initialization" do
    test "creates 10k missions with unique IDs and status :created" do
      config = %{environment: :validation, campaign: "10k_init"}
      missions =
        for i <- 1..10_000 do
          {:ok, mission} = MissionOrchestrator.create_mission("mass_traj_#{i}", config)
          mission
        end
      ids = Enum.map(missions, fn m -> Map.get(m, :id) end)
      unique_ids = Enum.uniq(ids)
      assert length(ids) == 10_000
      assert length(unique_ids) == 10_000
      assert Enum.all?(missions, fn m -> Map.get(m, :status) == :created end)
    end
  end

  describe "10k mission lifecycle" do
    test "create, execute, complete 10k missions" do
      config = %{environment: :validation, campaign: "10k_lifecycle"}
      results =
        for i <- 1..10_000 do
          {:ok, mission} = MissionOrchestrator.create_mission("lifecycle_traj_#{i}", config)
          {:ok, executed} = MissionOrchestrator.execute(mission)
          {:ok, completed} = MissionOrchestrator.complete(executed)
          Map.get(completed, :status)
        end
      assert length(results) == 10_000
      assert Enum.all?(results, fn s -> s == :completed end)
    end
  end

  describe "evidence routing determinism" do
    test "same inputs produce same output hashes" do
      evidence_data = %{source: :planner, payload: "determinism_check", timestamp: 42}
      results =
        for _ <- 1..10_000 do
          {:ok, evidence} = EvidenceRouter.route(:planner, :validation, evidence_data)
          Map.get(evidence, :output_hash)
        end
      unique_hashes = Enum.uniq(results)
      assert length(unique_hashes) == 1, "Expected all output hashes identical, got #{length(unique_hashes)} unique"
    end
  end

  describe "replay determinism" do
    test "record and verify 10k replays" do
      subsystems = %{orchestrator: MissionOrchestrator, router: EvidenceRouter, replay: ReplayCoordinator}
      results =
        for i <- 1..10_000 do
          mission = %{id: "replay_mission_#{i}", status: :completed, trajectory_id: "replay_traj_#{i}"}
          {:ok, replay} = ReplayCoordinator.record(mission, subsystems)
          ReplayCoordinator.verify(replay, mission, subsystems)
        end
      successes = Enum.count(results, fn r -> r == {:ok, :verified} end)
      assert successes == 10_000
    end
  end

  describe "archaeology completeness" do
    test "all 10k archaeology records have origin and narrative" do
      results =
        for i <- 1..10_000 do
          mission = %{id: "arch_mission_#{i}", status: :completed, stages: [:planning, :execution, :review]}
          evidence_chain = [%{id: "ev_#{i}_1"}, %{id: "ev_#{i}_2"}]
          replay = %{mission_root: "root_#{i}"}
          {:ok, archaeology} = ArchaeologyCoordinator.record(mission, evidence_chain, replay)
          archaeology
        end
      assert length(results) == 10_000
      assert Enum.all?(results, fn a -> is_binary(Map.get(a, :origin)) and byte_size(Map.get(a, :origin)) > 0 end)
      assert Enum.all?(results, fn a -> is_binary(Map.get(a, :mission_narrative)) and byte_size(Map.get(a, :mission_narrative)) > 0 end)
    end
  end

  describe "failure injection" do
    test "abort 50 of 100 missions, verify counts" do
      config = %{environment: :validation, campaign: "failure_inject"}
      missions =
        for i <- 1..100 do
          {:ok, mission} = MissionOrchestrator.create_mission("fail_traj_#{i}", config)
          mission
        end
      results =
        missions
        |> Enum.with_index()
        |> Enum.map(fn {mission, idx} ->
          if rem(idx, 2) == 0 do
            {:ok, executed} = MissionOrchestrator.execute(mission)
            MissionOrchestrator.complete(executed)
            :completed
          else
            {:ok, aborted} = MissionOrchestrator.abort(mission, "injected_failure")
            Map.get(aborted, :status)
          end
        end)
      completed_count = Enum.count(results, fn s -> s == :completed end)
      aborted_count = Enum.count(results, fn s -> s == :aborted end)
      assert completed_count == 50
      assert aborted_count == 50
    end
  end

  describe "mixed lifecycle stress" do
    test "interleave create/execute/complete/abort for 1k missions" do
      config = %{environment: :validation, campaign: "mixed_stress"}
      results =
        for i <- 1..1000 do
          {:ok, mission} = MissionOrchestrator.create_mission("stress_traj_#{i}", config)
          case rem(i, 4) do
            0 ->
              {:ok, executed} = MissionOrchestrator.execute(mission)
              {:ok, completed} = MissionOrchestrator.complete(executed)
              Map.get(completed, :status)
            1 ->
              {:ok, executed} = MissionOrchestrator.execute(mission)
              Map.get(executed, :status)
            2 ->
              {:ok, aborted} = MissionOrchestrator.abort(mission, "stress_abort")
              Map.get(aborted, :status)
            3 ->
              Map.get(mission, :status)
          end
        end
      completed = Enum.count(results, fn s -> s == :completed end)
      active = Enum.count(results, fn s -> s == :active end)
      aborted = Enum.count(results, fn s -> s == :aborted end)
      created = Enum.count(results, fn s -> s == :created end)
      assert completed + active + aborted + created == 1000
      assert completed > 0
      assert active > 0
      assert aborted > 0
      assert created > 0
    end
  end
end
