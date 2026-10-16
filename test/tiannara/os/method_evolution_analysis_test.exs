defmodule TiannaraOS.MethodEvolutionAnalysisTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.{
    EpisodeIndex,
    InstitutionKernel,
    MethodEvolutionPipeline,
    MethodEvolutionResult,
    ResearchEpisode,
    ResearchInstitution
  }

  defp unique_atom(label) do
    String.to_atom("#{label}_#{System.unique_integer([:positive])}")
  end

  defp start_kernel(institution_id, memory) do
    institution =
      ResearchInstitution.new(institution_id, :test_world, 0)
      |> Map.put(:civilizational_memory, memory)

    {:ok, pid} = InstitutionKernel.start_link(institution_id, institution)

    on_exit(fn ->
      if Process.alive?(pid), do: Process.exit(pid, :kill)
    end)

    pid
  end

  defp finalized(institution_id, topic, opts) do
    episode = ResearchEpisode.new(institution_id, topic, Map.new(opts))
    ResearchEpisode.finalize(episode, Keyword.get(opts, :finalized_tick, 100))
  end

  defp index_of(institution_id, episodes) do
    Enum.reduce(episodes, EpisodeIndex.new(institution_id), fn episode, index ->
      EpisodeIndex.add_entry(index, episode)
    end)
  end

  defp memory_of(index, episodes, stored_ids) do
    %{
      episode_index: index,
      episodes: Map.new(episodes, fn episode -> {episode.episode_id, episode} end),
      stored_episodes: stored_ids
    }
  end

  defp setup_institution(id, episodes) do
    index = index_of(id, episodes)
    start_kernel(id, memory_of(index, episodes, Enum.map(episodes, & &1.episode_id)))
    id
  end

  defp run_pipeline(id) do
    result = MethodEvolutionResult.new(id)
    {:ok, analyzed} = MethodEvolutionPipeline.execute_pipeline(result, id, time_window_months: 6)
    analyzed
  end

  defp analysis_fingerprint(analyzed) do
    %{
      current_performance_metrics: analyzed.current_performance_metrics,
      inefficiencies_detected: analyzed.inefficiencies_detected,
      candidate_improvements: analyzed.candidate_improvements,
      competing_improvements: analyzed.competing_improvements,
      impact_predictions: analyzed.impact_predictions,
      risk_assessments: analyzed.risk_assessments,
      supporting_episodes: analyzed.supporting_episodes,
      evidence_summary: analyzed.evidence_summary
    }
  end

  describe "evidence-derived metrics" do
    test "metrics that episodes cannot support are :insufficient_data, never constants" do
      id = unique_atom(:analysis_unknown)
      episodes = [finalized(id, "alpha", domain: :physics, tick: 1)]
      index = index_of(id, episodes)
      start_kernel(id, memory_of(index, episodes, Enum.map(episodes, & &1.episode_id)))

      analyzed = run_pipeline(id)
      metrics = analyzed.current_performance_metrics

      assert metrics.avg_replication_rate == :insufficient_data
      assert metrics.avg_prediction_accuracy == :insufficient_data
      assert metrics.theory_formation_efficiency == :insufficient_data

      category_metrics =
        Map.drop(metrics, [
          :total_episodes,
          :success_rate,
          :avg_replication_rate,
          :avg_prediction_accuracy,
          :resource_efficiency,
          :collaboration_index,
          :validation_quality,
          :theory_formation_efficiency
        ])

      assert map_size(category_metrics) > 0

      for {category, value} <- category_metrics do
        assert value == :insufficient_data,
               "category #{inspect(category)} must be :insufficient_data, got: #{inspect(value)}"
      end

      assert analyzed.evidence_summary.insufficient_data_metrics ==
               Enum.sort([
                 :avg_replication_rate,
                 :avg_prediction_accuracy,
                 :theory_formation_efficiency,
                 :resource_efficiency
                 | Map.keys(category_metrics)
               ])
    end

    test "derived metrics change when the evidence changes" do
      rich_id = unique_atom(:analysis_rich)

      setup_institution(rich_id, [
        finalized(rich_id, "rich", domain: :physics, tick: 1)
        |> ResearchEpisode.add_contributor(:external_lab)
        |> ResearchEpisode.add_validation("val-1")
        |> ResearchEpisode.add_cost(100.0, :experiment)
        |> ResearchEpisode.update_value_generated(50.0)
      ])

      bare_id = unique_atom(:analysis_bare)
      setup_institution(bare_id, [finalized(bare_id, "bare", domain: :physics, tick: 1)])

      rich = run_pipeline(rich_id).current_performance_metrics
      bare = run_pipeline(bare_id).current_performance_metrics

      assert rich.collaboration_index == 1.0
      assert rich.validation_quality == 1.0
      assert rich.resource_efficiency == 0.5

      assert bare.collaboration_index == 0.0
      assert bare.validation_quality == 0.0
      assert bare.resource_efficiency == :insufficient_data

      refute rich.collaboration_index == bare.collaboration_index
      refute rich.validation_quality == bare.validation_quality
    end

    test "resource efficiency averages only over episodes carrying cost data" do
      id = unique_atom(:analysis_cost)

      costed_a =
        finalized(id, "a", domain: :physics, tick: 1)
        |> ResearchEpisode.add_cost(100.0, :experiment)
        |> ResearchEpisode.update_value_generated(50.0)

      costed_b =
        finalized(id, "b", domain: :physics, tick: 2)
        |> ResearchEpisode.add_cost(200.0, :experiment)
        |> ResearchEpisode.update_value_generated(200.0)

      uncosted = finalized(id, "c", domain: :physics, tick: 3)

      setup_institution(id, [costed_a, costed_b, uncosted])
      metrics = run_pipeline(id).current_performance_metrics

      # (0.5 + 1.0) / 2 — the uncosted episode contributes no ratio
      assert metrics.resource_efficiency == 0.75
    end
  end

  describe "weakness detection and proposals over unknown category data" do
    test "no category is flagged as a weakness when every category metric is unknown" do
      id = unique_atom(:analysis_weak)

      episodes = [
        finalized(id, "alpha", domain: :physics, tick: 1),
        finalized(id, "beta", domain: :biology, tick: 2)
      ]

      index = index_of(id, episodes)
      start_kernel(id, memory_of(index, episodes, Enum.map(episodes, & &1.episode_id)))

      analyzed = run_pipeline(id)

      assert analyzed.inefficiencies_detected == []
      assert analyzed.candidate_improvements == []
      assert analyzed.competing_improvements == []
      assert analyzed.impact_predictions == []
      assert analyzed.risk_assessments == []
      assert analyzed.evidence_summary.weakness_categories == []
      assert analyzed.evidence_summary.improvement_count == 0
      assert analyzed.evidence_summary.competing_count == 0
    end

    test "proposals carry no fabricated confidence and no cloned competing alternatives" do
      inefficiencies = [
        %{
          category: :experiment_design,
          current_performance: 0.4,
          severity: :medium,
          description: "below threshold",
          supporting_evidence: 0
        }
      ]

      {candidates, competing} =
        MethodEvolutionPipeline.generate_improvement_proposals(inefficiencies, [], [
          :experiment_design
        ])

      assert [candidate] = candidates
      assert candidate.confidence == :insufficient_data
      assert candidate.expected_impact == 0.6
      assert candidate.supporting_episode_count == 0
      assert competing == []
    end

    test "impact predictions do not invent intervals or strength labels" do
      predictions =
        MethodEvolutionPipeline.predict_impact_from_evidence(
          [%{category: :experiment_design, expected_impact: 0.6}],
          [finalized(unique_atom(:analysis_impact), "alpha", domain: :physics, tick: 1)]
        )

      assert [prediction] = predictions
      assert prediction.predicted_improvement == 0.6
      assert prediction.confidence_interval == :insufficient_data
      assert prediction.evidence_strength == :insufficient_data
      assert prediction.supporting_episode_ids == []
    end
  end

  describe "deterministic replay" do
    test "the same evidence set produces an identical analysis" do
      id = unique_atom(:analysis_replay)

      episodes = [
        finalized(id, "alpha", domain: :physics, tick: 10)
        |> ResearchEpisode.add_contributor(:external_lab)
        |> ResearchEpisode.add_validation("val-1"),
        finalized(id, "beta", domain: :biology, tick: 20)
        |> ResearchEpisode.add_cost(80.0, :experiment)
        |> ResearchEpisode.update_value_generated(40.0)
      ]

      index = index_of(id, episodes)
      start_kernel(id, memory_of(index, episodes, Enum.map(episodes, & &1.episode_id)))

      first = analysis_fingerprint(run_pipeline(id))
      second = analysis_fingerprint(run_pipeline(id))

      assert first == second
    end
  end

  describe "error propagation with analysis enabled" do
    test "no evidence still yields an error tuple, never an empty confident analysis" do
      id = unique_atom(:analysis_no_evidence)
      start_kernel(id, %{})

      result = MethodEvolutionResult.new(id)

      assert {:error, {:no_evidence, _details}} =
               MethodEvolutionPipeline.execute_pipeline(result, id, time_window_months: 6)
    end

    test "unreachable institution still yields an error tuple" do
      id = unique_atom(:analysis_not_running)
      result = MethodEvolutionResult.new(id)

      assert {:error, :institution_not_running} =
               MethodEvolutionPipeline.execute_pipeline(result, id, time_window_months: 6)
    end
  end
end
