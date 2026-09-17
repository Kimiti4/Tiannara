defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.QuestionGenerator do
  @moduledoc """
  Phase 16.1 Module 2 — Question Generation Engine (Pure Implementation)

  Implements frozen contract from RESEARCH_RUNTIME_FREEZE.md 2.2 QuestionGenerator:
  - generate_questions(gap_inputs) -> [ResearchQuestion]

  Questions are generated only from:
  - observations
  - contradictions
  - uncertainty
  - knowledge gaps

  Deterministic rule: derived seeds must be content-hash derived.
  """

  @question_table :research_questions

  def init_table do
    if :ets.info(@question_table) == :undefined do
      :ets.new(@question_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Generate research questions from knowledge gap inputs (deterministic)"
  @spec generate_questions([map()]) :: {:ok, [map()]}
  def generate_questions(gap_inputs) when is_list(gap_inputs) do
    init_table()
    questions = Enum.map(gap_inputs, &build_question/1)
    Enum.each(questions, fn q -> :ets.insert(@question_table, {Map.get(q, "question_id"), q}) end)
    {:ok, questions}
  end

  @doc "Lookup question by ID"
  @spec lookup_question(String.t()) :: {:ok, map()} | :error
  def lookup_question(question_id) when is_binary(question_id) do
    case :ets.lookup(@question_table, question_id) do
      [{^question_id, question}] -> {:ok, question}
      [] -> :error
    end
  end

  @doc "List all generated questions"
  @spec list_questions() :: [map()]
  def list_questions do
    :ets.tab2list(@question_table)
    |> Enum.map(fn {_id, q} -> q end)
  end

  # --- internal helpers ---

  defp build_question(%{"knowledge_gap_id" => gap_id, "gap_type" => gap_type, "domain" => domain, "description" => description}) do
    canonical = canonicalize_map(%{"gap_id" => gap_id, "gap_type" => gap_type, "domain" => domain, "description" => description})
    json = Jason.encode!(canonical)
    question_id = "q_" <> (:crypto.hash(:sha256, json) |> Base.encode16(case: :lower))

    %{
      "question_id" => question_id,
      "schema_version" => "16.1.0",
      "knowledge_gap_id" => gap_id,
      "title" => "#{domain}: Investigate #{gap_type} dynamics",
      "description" => description,
      "expected_uncertainty_reduction" => estimate_uncertainty_reduction(gap_type),
      "estimated_impact" => 0.5,
      "estimated_cost" => %{"compute_units" => 1000, "evidence_budget" => 100},
      "dependencies" => [],
      "required_validation_types" => ["STATISTICAL", "REPLAY", "AUDIT"],
      "stopping_criteria" => [%{"criterion_type" => "CONFIDENCE", "threshold" => 0.95, "direction" => "REACH"}],
      "priority_hint" => %{"novelty" => 0.7, "feasibility" => 0.8}
    }
  end

  defp estimate_uncertainty_reduction("UNCERTAINTY" <> _), do: 0.9
  defp estimate_uncertainty_reduction("CONTRADICTION" <> _), do: 0.8
  defp estimate_uncertainty_reduction("MISSING_EVIDENCE" <> _), do: 0.7
  defp estimate_uncertainty_reduction(_), do: 0.5

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term
end
