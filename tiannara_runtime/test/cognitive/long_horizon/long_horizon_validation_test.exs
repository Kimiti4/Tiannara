defmodule TiannaraRuntime.Cognitive.LongHorizon.LongHorizonValidationTest do
  use ExUnit.Case, async: false
  @moduletag :long_horizon
  @moduletag timeout: 180000

  alias TiannaraRuntime.Cognitive.Runtime.{MissionOrchestrator, ReplayCoordinator, ArchaeologyCoordinator, EvidenceRouter}

  @stages [:planning, :execution, :review, :reflection]

  defp run_mission_cycle(trajectory_id, config \\ %{}) do
    {:ok, mission} = MissionOrchestrator.create_mission(trajectory_id, config)
    {:ok, executed} = MissionOrchestrator.execute(mission)

    mission_with_stages = advance_through_stages(executed)

    {:ok, completed} = MissionOrchestrator.complete(mission_with_stages)
    evidence_chain = build_evidence_chain(completed)
    {:ok, replay} = ReplayCoordinator.record(completed, %{stages: length(@stages)})
    {:ok, archaeology} = ArchaeologyCoordinator.record(completed, evidence_chain, replay)

    %{
      mission: completed,
      evidence_chain: evidence_chain,
      replay: replay,
      archaeology: archaeology,
      success: true
    }
  end

  defp advance_through_stages(mission) do
    Enum.reduce(@stages, mission, fn stage, m ->
      {:ok, m} = MissionOrchestrator.advance_stage(m, stage)
      m
    end)
  end

  defp build_evidence_chain(mission) do
    stages = Map.get(mission, :stages, [])
    Enum.reduce(stages, [], fn stage, chain ->
      {:ok, evidence} = EvidenceRouter.route(:mission_orchestrator, stage, %{stage: stage, mission_id: Map.get(mission, :id)})
      {:ok, chain} = EvidenceRouter.append(chain, evidence)
      chain
    end)
  end

  defp run_batch(count, start_index \\ 0) do
    results =
      Enum.map(start_index..(start_index + count - 1)//1, fn i ->
        run_mission_cycle("traj_#{i}", %{batch: div(i, 100)})
      end)

    completed = Enum.filter(results, & &1.success)
    %{
      total: length(results),
      completed: length(completed),
      results: completed,
      completion_rate: length(completed) / max(length(results), 1)
    }
  end

  defp batch_completion_rate(batch_result) do
    batch_result.completion_rate
  end

  describe "10-year simulation (1000 missions)" do
    @tag :ten_year
    test "completion rate >= 98%, evidence per mission > 0, archaeology per mission > 0" do
      result = run_batch(1000)
      assert result.completion_rate >= 0.98

      for r <- result.results do
        assert length(r.evidence_chain) > 0
        assert r.archaeology.origin != nil
        assert r.archaeology.mission_narrative != nil
        assert r.archaeology.evidence_lineage != nil
      end
    end
  end

  describe "25-year simulation (2500 missions)" do
    @tag :twenty_five_year
    test "replay success rate >= 99%" do
      result = run_batch(2500)

      replay_results =
        Enum.map(result.results, fn r ->
          case ReplayCoordinator.verify(r.replay, r.mission, %{stages: length(@stages)}) do
            {:ok, :verified} -> true
            _ -> false
          end
        end)

      replay_success = Enum.count(replay_results, & &1)
      replay_rate = replay_success / max(length(replay_results), 1)
      assert replay_rate >= 0.99
    end
  end

  describe "50-year simulation (5000 missions)" do
    @tag :fifty_year
    test "evidence growth linear with mission count" do
      result = run_batch(5000)

      for r <- result.results do
        assert length(r.evidence_chain) == length(@stages)
      end
    end
  end

  describe "100-year simulation (10000 missions)" do
    @tag :hundred_year
    test "mission completion rate, replay integrity, archaeology completeness, evidence generation" do
      result = run_batch(10000)
      assert result.completion_rate >= 0.98

      for r <- result.results do
        {:ok, verified} = ReplayCoordinator.verify(r.replay, r.mission, %{stages: length(@stages)})
        assert verified == :verified

        assert r.archaeology.origin != nil
        assert r.archaeology.mission_narrative != nil
        assert r.archaeology.evidence_lineage != nil
        assert r.archaeology.subsystem_summaries != nil
        assert r.archaeology.replay_verification != nil

        assert length(r.evidence_chain) > 0
      end
    end
  end

  describe "cognitive stability over time" do
    @tag :cognitive_stability
    test "per-batch health metrics remain consistent (stddev < 0.15)" do
      batches =
        Enum.map(0..9, fn batch_idx ->
          result = run_batch(100, batch_idx * 100)
          batch_completion_rate(result)
        end)

      avg = Enum.sum(batches) / length(batches)
      variance = Enum.reduce(batches, 0, fn b, acc -> acc + (b - avg) ** 2 end) / length(batches)
      stddev = :math.sqrt(variance)
      assert stddev < 0.15
    end
  end

  describe "evidence growth tracking" do
    @tag :evidence_growth
    test "evidence_chain length over 5000 missions grows proportionally" do
      total_missions = 5000
      checkpoints = [100, 500, 1000, 2000, 3000, 4000, 5000]

      {_final_chain, lengths} =
        Enum.reduce(1..total_missions//1, {[], %{}}, fn i, {chain, len_map} ->
          {:ok, ev1} = EvidenceRouter.route(:mission, :planning, %{mission_index: i})
          {:ok, ev2} = EvidenceRouter.route(:mission, :execution, %{mission_index: i})
          {:ok, ev3} = EvidenceRouter.route(:mission, :review, %{mission_index: i})
          {:ok, ev4} = EvidenceRouter.route(:mission, :reflection, %{mission_index: i})

          {:ok, chain} = EvidenceRouter.append(chain, ev1)
          {:ok, chain} = EvidenceRouter.append(chain, ev2)
          {:ok, chain} = EvidenceRouter.append(chain, ev3)
          {:ok, chain} = EvidenceRouter.append(chain, ev4)

          new_len_map = if i in checkpoints, do: Map.put(len_map, i, length(chain)), else: len_map
          {chain, new_len_map}
        end)

      for mission_count <- checkpoints, Map.has_key?(lengths, mission_count) do
        chain_len = Map.get(lengths, mission_count)
        expected = 4 * mission_count
        assert chain_len == expected
      end
    end
  end

  describe "archaeology completeness" do
    @tag :archaeology_completeness
    test "every completed mission has archaeology with origin, narrative, lineage" do
      result = run_batch(1000)

      for r <- result.results do
        assert r.archaeology.origin != nil
        assert r.archaeology.mission_narrative != nil
        assert r.archaeology.evidence_lineage != nil
        assert is_list(r.archaeology.evidence_lineage)
        assert length(r.archaeology.evidence_lineage) == length(r.evidence_chain)
      end
    end
  end
end
