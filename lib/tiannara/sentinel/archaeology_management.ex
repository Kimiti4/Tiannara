defmodule Tiannara.Sentinel.ArchaeologyManagement do
  @moduledoc """
  Archaeology Management — failure-as-data recovery from evolutionary ruins.

  Mines failure data across SOPL LawRuins, REA MetaRuins, civilization collapses,
  and failed experiments to extract actionable insights, recovery recommendations,
  and lessons learned. Prevents repeated mistakes by maintaining a knowledge base
  of "what failed, why, and what to try instead."
  """
  use GenServer
  require Logger

  alias Tiannara.Sentinel.EpistemologyArchive

  # ── Public API ──

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Records a failure/ruin event with context.
  """
  def record_ruin(ruin_type, entity_id, context) do
    GenServer.cast(__MODULE__, {:record_ruin, ruin_type, entity_id, context})
  end

  @doc """
  Records a lesson learned from a failure analysis.
  """
  def record_lesson(lesson) do
    GenServer.cast(__MODULE__, {:record_lesson, lesson})
  end

  @doc """
  Analyzes a proposed change against historical failures to see if
  similar approaches have failed before.
  """
  def analyze_proposal(proposal) do
    GenServer.call(__MODULE__, {:analyze_proposal, proposal})
  end

  @doc """
  Returns recovery recommendations based on similar historical failures.
  """
  def recovery_recommendations(ruin_type, context) do
    GenServer.call(__MODULE__, {:recovery_recommendations, ruin_type, context})
  end

  @doc """
  Returns all recorded lessons learned.
  """
  def get_lessons do
    GenServer.call(__MODULE__, :get_lessons)
  end

  @doc """
  Returns a summary of all ruins by type.
  """
  def ruin_summary do
    GenServer.call(__MODULE__, :ruin_summary)
  end

  @doc """
  Mines EpistemologyArchive for collapse patterns and generates
  archaeological insights.
  """
  def mine_collapse_records do
    GenServer.call(__MODULE__, :mine_collapse_records)
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    :ets.new(:archaeology_ruins, [:bag, :public, :named_table])
    :ets.new(:archaeology_lessons, [:set, :public, :named_table])
    Logger.info("🏛️ [ARCHAEOLOGY] Archaeology Management initialized.")
    {:ok, %{
      ruins_table: :archaeology_ruins,
      lessons_table: :archaeology_lessons,
      next_lesson_id: 1
    }}
  end

  @impl true
  def handle_cast({:record_ruin, ruin_type, entity_id, context}, state) do
    entry = {ruin_type, entity_id, context, DateTime.utc_now()}
    :ets.insert(state.ruins_table, entry)
    Logger.info("[ARCHAEOLOGY] Ruin recorded: #{ruin_type} #{entity_id}")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:record_lesson, lesson}, state) do
    id = state.next_lesson_id
    entry = {id, lesson, DateTime.utc_now()}
    :ets.insert(state.lessons_table, entry)
    {:noreply, %{state | next_lesson_id: id + 1}}
  end

  @impl true
  def handle_call({:analyze_proposal, proposal}, _from, state) do
    analysis = analyze_against_history(state, proposal)
    {:reply, analysis, state}
  end

  @impl true
  def handle_call({:recovery_recommendations, ruin_type, context}, _from, state) do
    recs = generate_recommendations(state, ruin_type, context)
    {:reply, recs, state}
  end

  @impl true
  def handle_call(:get_lessons, _from, state) do
    lessons = :ets.tab2list(state.lessons_table)
    |> Enum.map(fn {id, lesson, ts} -> %{id: id, lesson: lesson, recorded_at: ts} end)
    |> Enum.sort_by(& &1.id, :desc)
    {:reply, lessons, state}
  end

  @impl true
  def handle_call(:ruin_summary, _from, state) do
    ruins = :ets.tab2list(state.ruins_table)
    by_type = Enum.group_by(ruins, fn {type, _id, _ctx, _ts} -> type end)
    summary = Map.new(by_type, fn {type, entries} ->
      {type, %{count: length(entries), latest: entries |> Enum.max_by(fn {_, _, _, ts} -> ts end, DateTime) |> elem(3)}}
    end)
    {:reply, summary, state}
  end

  @impl true
  def handle_call(:mine_collapse_records, _from, state) do
    insights = mine_collapses()
    {:reply, insights, state}
  end

  # ── Private Helpers ──

  defp analyze_against_history(state, proposal) do
    proposal_type = Map.get(proposal, :type, :unknown)
    proposal_signature = Map.get(proposal, :signature, Map.get(proposal, :operators, []))

    similar_ruins = :ets.match_object(state.ruins_table, {proposal_type, :_, :_, :_})
    |> Enum.filter(fn {_type, _id, ctx, _ts} ->
      historical_signature = Map.get(ctx, :signature, Map.get(ctx, :operators, []))
      similarity = compute_signature_similarity(proposal_signature, historical_signature)
      similarity > 0.5
    end)

    lessons = :ets.tab2list(state.lessons_table)
    |> Enum.filter(fn {_id, lesson, _ts} ->
      relevant_type = Map.get(lesson, :ruin_type, :unknown)
      relevant_type == proposal_type
    end)

    %{
      proposal: proposal,
      similar_historical_failures_count: length(similar_ruins),
      similar_failures: Enum.map(similar_ruins, fn {_type, id, ctx, ts} ->
        %{entity_id: id, context: ctx, failed_at: ts}
      end),
      applicable_lessons: Enum.map(lessons, fn {_id, lesson, _ts} -> lesson end),
      risk_assessment: if(length(similar_ruins) > 0, do: :caution, else: :no_historical_conflict),
      recommendation: if(length(similar_ruins) > 2, do: :avoid_similar_pattern, else: :proceed_with_monitoring)
    }
  end

  defp generate_recommendations(state, ruin_type, context) do
    similar_ruins = :ets.match_object(state.ruins_table, {ruin_type, :_, :_, :_})

    lessons = :ets.tab2list(state.lessons_table)
    |> Enum.filter(fn {_id, lesson, _ts} ->
      Map.get(lesson, :ruin_type, :unknown) == ruin_type
    end)

    failure_patterns = similar_ruins
    |> Enum.map(fn {_type, _id, ctx, _ts} -> Map.get(ctx, :failure_reason, :unknown) end)
    |> Enum.frequencies()

    recovery_actions = recover_from_ruin_type(ruin_type, context)

    %{
      ruin_type: ruin_type,
      similar_incidents: length(similar_ruins),
      common_failure_patterns: failure_patterns,
      lessons: Enum.map(lessons, fn {_id, lesson, _ts} -> lesson end),
      recovery_actions: recovery_actions,
      confidence: min(length(similar_ruins) * 0.15, 0.9)
    }
  end

  defp recover_from_ruin_type(:sopl_law_ruin, context) do
    signature = Map.get(context, :collapse_signature, :unknown)
    case signature do
      :epistemic_disease -> ["Quarantine affected law species", "Apply immune intervention via ImmuneCoordinator"]
      :infinite_novelty_spiral -> ["Introduce stability constraints", "Re-evaluate acceptance criteria"]
      :conservative_lock_in -> ["Inject novelty operators", "Force exploration of new branches"]
      _ -> ["Review law species health", "Consider rollback to stable ancestor"]
    end
  end

  defp recover_from_ruin_type(:rea_meta_ruin, context) do
    reason = Map.get(context, :failure_reason, :unknown)
    case reason do
      :validation_failed -> ["Strengthen meta-model constraints", "Reduce operator set complexity"]
      :esg_rejected -> ["Simulate with reduced scope", "Test with conservative parameters first"]
      :runtime_collapse -> ["Isolate affected meta-genome", "Analyze runtime telemetry for root cause"]
      _ -> ["Archive meta-genome state", "Re-evaluate fitness criteria"]
    end
  end

  defp recover_from_ruin_type(_ruin_type, _context) do
    ["Analyze root cause via CausalIntelligence", "Record lesson learned", "Consider architecture change"]
  end

  defp mine_collapses do
    records = if Code.ensure_loaded?(EpistemologyArchive) do
      apply(EpistemologyArchive, :get_all_records, [])
    else
      []
    end

    if length(records) == 0 do
      %{
        total_collapses: 0,
        collapse_patterns: %{},
        insights: ["No collapse data available yet"]
      }
    else
      signatures = Enum.map(records, & &1.collapse_signature)
      pattern_counts = Enum.frequencies(signatures)
      total = length(records)

      insights = Enum.map(pattern_counts, fn {sig, count} ->
        pct = Float.round(count / total * 100, 1)
        "#{sig}: #{count}/#{total} collapses (#{pct}%)"
      end)

      %{
        total_collapses: total,
        collapse_patterns: pattern_counts,
        insights: insights,
        most_common_collapse: signatures |> Enum.frequencies() |> Enum.max_by(fn {_k, v} -> v end) |> elem(0)
      }
    end
  end

  defp compute_signature_similarity(sig_a, sig_b) when is_list(sig_a) and is_list(sig_b) do
    if sig_a == [] or sig_b == [] do
      0.0
    else
      set_a = MapSet.new(sig_a)
      set_b = MapSet.new(sig_b)
      intersection = MapSet.intersection(set_a, set_b) |> MapSet.size()
      union = MapSet.union(set_a, set_b) |> MapSet.size()
      intersection / max(union, 1)
    end
  end

  defp compute_signature_similarity(_sig_a, _sig_b), do: 0.0
end
