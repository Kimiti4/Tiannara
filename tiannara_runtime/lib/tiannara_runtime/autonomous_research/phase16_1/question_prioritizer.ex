defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.QuestionPrioritizer do
  @moduledoc """
  Phase 16.1 Module 2 — Question Prioritizer (Pure Implementation)

  Implements frozen contract from RESEARCH_RUNTIME_FREEZE.md Stage D:
  - Input: generated questions + portfolio selection contract inputs
  - Output: `ResearchPriority` records with deterministic scores

  Frozen behavior:
  - Ranking must be deterministic with content-hash tie-breaking
  """

  @priority_table :research_priorities

  def init_table do
    if :ets.info(@priority_table) == :undefined do
      :ets.new(@priority_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Prioritize questions deterministically"
  @spec prioritize([map()], map()) :: {:ok, [map()]}
  def prioritize(questions, _constraints \\ %{}) when is_list(questions) do
    init_table()
    priorities = score_and_sort(questions)
    Enum.each(priorities, fn p -> :ets.insert(@priority_table, {Map.get(p, "question_id"), p}) end)
    {:ok, priorities}
  end

  @doc "Lookup priority by question ID"
  @spec lookup_priority(String.t()) :: {:ok, map()} | :error
  def lookup_priority(question_id) when is_binary(question_id) do
    case :ets.lookup(@priority_table, question_id) do
      [{^question_id, priority}] -> {:ok, priority}
      [] -> :error
    end
  end

  @doc "List all priorities"
  @spec list_priorities() :: [map()]
  def list_priorities do
    :ets.tab2list(@priority_table)
    |> Enum.map(fn {_id, p} -> p end)
  end

  # --- internal helpers ---

  defp score_and_sort(questions) do
    questions
    |> Enum.map(fn q ->
      novelty = Map.get(q, "priority_hint", %{}) |> Map.get("novelty", 0.5)
      feasibility = Map.get(q, "priority_hint", %{}) |> Map.get("feasibility", 0.5)
      uncertainty_red = Map.get(q, "expected_uncertainty_reduction", 0.5)

      %{
        "question_id" => Map.get(q, "question_id", ""),
        "knowledge_gap_id" => Map.get(q, "knowledge_gap_id", ""),
        "score_components" => %{
          "novelty" => novelty,
          "feasibility" => feasibility,
          "uncertainty_reduction" => uncertainty_red
        },
        "total_score" => novelty * 0.3 + feasibility * 0.3 + uncertainty_red * 0.4,
        "tie_breaker" => Map.get(q, "question_id", "")
      }
    end)
    |> Enum.sort_by(fn p -> {-(Map.get(p, "total_score", 0.0)), Map.get(p, "tie_breaker", "")} end)
    |> Enum.with_index(1)
    |> Enum.map(fn {p, idx} -> Map.put(p, "rank", idx) end)
  end
end
