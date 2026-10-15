defmodule TiannaraOS.MethodEvolutionPipelineRetrievalTest do
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

  defp retrieve(institution_id, months) do
    MethodEvolutionPipeline.retrieve_episodes_for_analysis(institution_id, months)
  end

  describe "retrieval of a populated index" do
    test "returns the real finalized episodes with verifiable identity and source linkage" do
      id = unique_atom(:retr_populated)

      episodes = [
        finalized(id, "third topic", domain: :physics, tick: 30),
        finalized(id, "first topic", domain: :physics, tick: 10),
        finalized(id, "second topic", domain: :biology, tick: 20)
      ]

      index = index_of(id, episodes)
      start_kernel(id, memory_of(index, episodes, Enum.map(episodes, & &1.episode_id)))

      assert {:ok, retrieval} = retrieve(id, 6)

      assert Enum.map(retrieval.episodes, & &1.start_tick) == [10, 20, 30]
      assert retrieval.exclusions == []

      assert retrieval.provenance.institution_id == id
      assert retrieval.provenance.index_entries == 3
      assert retrieval.provenance.returned == 3
      assert retrieval.provenance.excluded == 0
      assert retrieval.provenance.source == :institution_kernel_civilizational_memory

      assert retrieval.provenance.time_window_months == 6
      assert retrieval.provenance.time_window_applied == false
      assert retrieval.provenance.time_window_reason == :no_tick_calendar_conversion_defined

      for episode <- retrieval.episodes do
        assert %ResearchEpisode{} = episode
        assert episode.institution_id == id
        assert episode.status == :finalized

        entry = EpisodeIndex.get_entry(index, episode.episode_id)
        assert entry.episode_id == episode.episode_id
        assert entry.topic == episode.topic
      end
    end

    test "kernel that is not running is reported, never treated as an evidence set" do
      id = unique_atom(:retr_not_running)

      assert {:error, :institution_not_running} = retrieve(id, 6)
    end

    test "non-atom institution id is rejected explicitly" do
      assert {:error, {:invalid_institution_id, "not_an_atom"}} = retrieve("not_an_atom", 6)
    end
  end

  describe "no-evidence outcomes" do
    test "empty index yields an explicit no-evidence result, not an empty confident analysis" do
      id = unique_atom(:retr_empty)
      start_kernel(id, %{})

      assert {:error, {:no_evidence, details}} = retrieve(id, 6)
      assert details.index_entries == 0
      assert details.exclusions == []
      assert details.provenance.institution_id == id
      assert details.provenance.returned == 0
      assert details.provenance.time_window_applied == false
    end

    test "index whose references are all invalid yields no-evidence with every exclusion reported" do
      id = unique_atom(:retr_all_excluded)

      episode = finalized(id, "orphaned", domain: :physics, tick: 5)
      index = EpisodeIndex.add_entry(EpisodeIndex.new(id), episode)

      start_kernel(id, %{episode_index: index, episodes: %{}, stored_episodes: []})

      assert {:error, {:no_evidence, details}} = retrieve(id, 6)
      assert details.index_entries == 1
      assert [%{episode_id: ep_id, reason: :stale_reference, detail: nil}] = details.exclusions
      assert ep_id == episode.episode_id
      assert details.provenance.excluded == 1
      assert details.provenance.returned == 0
    end

    test "stored references absent from the index are reported and never counted as evidence" do
      id = unique_atom(:retr_not_indexed)
      start_kernel(id, %{episode_index: EpisodeIndex.new(id), episodes: %{}, stored_episodes: ["ep_ghost"]})

      assert {:error, {:no_evidence, details}} = retrieve(id, 6)
      assert details.index_entries == 0

      assert [%{episode_id: "ep_ghost", reason: :not_indexed, detail: %{occurrences: 1}}] =
               details.exclusions
    end

    test "structurally malformed memory state is rejected explicitly" do
      id = unique_atom(:retr_invalid_state)
      start_kernel(id, %{episode_index: :not_an_index, episodes: %{}, stored_episodes: []})

      assert {:error, {:invalid_memory_state, ^id}} = retrieve(id, 6)
    end
  end

  describe "stale, mismatched, unfinished and duplicate references" do
    test "stale reference is excluded with a reason and never silently counted" do
      id = unique_atom(:retr_stale)

      episode = finalized(id, "vanishing", domain: :physics, tick: 7)
      index = EpisodeIndex.add_entry(EpisodeIndex.new(id), episode)

      start_kernel(id, %{
        episode_index: index,
        episodes: %{},
        stored_episodes: [episode.episode_id]
      })

      assert {:error, {:no_evidence, details}} = retrieve(id, 6)

      assert [%{episode_id: ep_id, reason: :stale_reference, detail: nil}] = details.exclusions
      assert ep_id == episode.episode_id
    end

    test "valid evidence alongside a stale reference returns only the resolvable episode" do
      id = unique_atom(:retr_stale_mixed)

      valid = finalized(id, "kept", domain: :physics, tick: 1)
      stale = finalized(id, "dropped", domain: :physics, tick: 2)

      index =
        EpisodeIndex.new(id)
        |> EpisodeIndex.add_entry(valid)
        |> EpisodeIndex.add_entry(stale)

      start_kernel(id, memory_of(index, [valid], [stale.episode_id, valid.episode_id]))

      assert {:ok, retrieval} = retrieve(id, 6)

      assert Enum.map(retrieval.episodes, & &1.episode_id) == [valid.episode_id]
      assert [%{episode_id: stale_id, reason: :stale_reference}] = retrieval.exclusions
      assert stale_id == stale.episode_id
      assert retrieval.provenance.index_entries == 2
      assert retrieval.provenance.returned == 1
      assert retrieval.provenance.excluded == 1
    end

    test "episode owned by another institution is excluded as a provenance mismatch" do
      id = unique_atom(:retr_owner_mismatch)
      foreign = unique_atom(:retr_owner_other)

      episode = finalized(foreign, "foreign work", domain: :physics, tick: 4)
      index = EpisodeIndex.add_entry(EpisodeIndex.new(id), episode)

      start_kernel(id, memory_of(index, [episode], [episode.episode_id]))

      assert {:error, {:no_evidence, details}} = retrieve(id, 6)

      assert [%{episode_id: ep_id, reason: :institution_mismatch, detail: ^foreign}] =
               details.exclusions

      assert ep_id == episode.episode_id
    end

    test "index owned by another institution excludes every reference with an ownership reason" do
      id = unique_atom(:retr_index_mismatch)
      foreign = unique_atom(:retr_index_other)

      episode = finalized(id, "indexed elsewhere", domain: :physics, tick: 4)
      index = EpisodeIndex.add_entry(EpisodeIndex.new(foreign), episode)

      start_kernel(id, memory_of(index, [episode], [episode.episode_id]))

      assert {:error, {:no_evidence, details}} = retrieve(id, 6)

      assert [%{episode_id: ep_id, reason: :index_institution_mismatch, detail: ^foreign}] =
               details.exclusions

      assert ep_id == episode.episode_id
    end

    test "unfinished episode is excluded with its actual status, never counted as evidence" do
      id = unique_atom(:retr_unfinished)

      active = ResearchEpisode.new(id, "still running", %{domain: :physics, tick: 9})
      index = EpisodeIndex.add_entry(EpisodeIndex.new(id), active)

      start_kernel(id, memory_of(index, [active], [active.episode_id]))

      assert {:error, {:no_evidence, details}} = retrieve(id, 6)

      assert [%{episode_id: ep_id, reason: :status_not_finalized, detail: :active}] =
               details.exclusions

      assert ep_id == active.episode_id
    end

    test "duplicate stored reference does not inflate the evidence count" do
      id = unique_atom(:retr_duplicate)

      episode = finalized(id, "counted once", domain: :physics, tick: 6)
      index = EpisodeIndex.add_entry(EpisodeIndex.new(id), episode)

      start_kernel(id, memory_of(index, [episode], [episode.episode_id, episode.episode_id]))

      assert {:ok, retrieval} = retrieve(id, 6)

      assert length(retrieval.episodes) == 1
      assert [%{episode_id: ep_id, reason: :duplicate_reference, detail: %{occurrences: 2}}] =
               retrieval.exclusions

      assert ep_id == episode.episode_id
      assert retrieval.provenance.index_entries == 1
      assert retrieval.provenance.returned == 1
    end
  end

  describe "execute_pipeline consumption of real retrieval" do
    test "analyzes exactly the retrieved episodes and records retrieval provenance" do
      id = unique_atom(:retr_pipeline_ok)

      episodes = [
        finalized(id, "alpha", domain: :physics, tick: 10),
        finalized(id, "beta", domain: :biology, tick: 20)
      ]

      index = index_of(id, episodes)
      start_kernel(id, memory_of(index, episodes, Enum.map(episodes, & &1.episode_id)))

      result = MethodEvolutionResult.new(id)

      assert {:ok, analyzed} =
               MethodEvolutionPipeline.execute_pipeline(result, id, time_window_months: 6)

      assert %MethodEvolutionResult{} = analyzed
      assert analyzed.episodes_analyzed == 2
      assert Enum.sort(analyzed.supporting_episodes) == Enum.sort(Enum.map(episodes, & &1.episode_id))

      assert analyzed.evidence_summary.total_episodes_analyzed == 2
      assert analyzed.evidence_summary.index_entries == 2
      assert analyzed.evidence_summary.exclusions == []
      assert analyzed.evidence_summary.time_window_months == 6
      assert analyzed.evidence_summary.time_window_applied == false
      assert analyzed.evidence_summary.time_window_reason == :no_tick_calendar_conversion_defined
    end

    test "stale and duplicate references reduce the analyzed set to resolvable episodes only" do
      id = unique_atom(:retr_pipeline_mixed)

      valid = finalized(id, "real", domain: :physics, tick: 1)
      stale = finalized(id, "ghost", domain: :physics, tick: 2)

      index =
        EpisodeIndex.new(id)
        |> EpisodeIndex.add_entry(valid)
        |> EpisodeIndex.add_entry(stale)

      start_kernel(id, memory_of(index, [valid], [stale.episode_id, valid.episode_id, valid.episode_id]))

      result = MethodEvolutionResult.new(id)

      assert {:ok, analyzed} =
               MethodEvolutionPipeline.execute_pipeline(result, id, time_window_months: 6)

      assert analyzed.episodes_analyzed == 1
      assert analyzed.supporting_episodes == [valid.episode_id]
      assert analyzed.evidence_summary.index_entries == 2

      assert Enum.map(analyzed.evidence_summary.exclusions, & &1.reason)
             |> Enum.sort() == [:duplicate_reference, :stale_reference]
    end

    test "no evidence yields an error tuple and no result struct at all" do
      id = unique_atom(:retr_pipeline_empty)
      start_kernel(id, %{})

      result = MethodEvolutionResult.new(id)

      assert {:error, {:no_evidence, details}} =
               MethodEvolutionPipeline.execute_pipeline(result, id, time_window_months: 6)

      assert details.index_entries == 0
    end

    test "unreachable institution yields an error tuple and no result struct at all" do
      id = unique_atom(:retr_pipeline_missing)
      result = MethodEvolutionResult.new(id)

      assert {:error, :institution_not_running} =
               MethodEvolutionPipeline.execute_pipeline(result, id, time_window_months: 6)
    end
  end
end
