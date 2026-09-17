defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.ResearchPortfolio do
  @moduledoc """
  Phase 16.1 Module 6 — Research Portfolio (Pure Implementation)

  Implements frozen contract from RESEARCH_RUNTIME_FREEZE.md 2.3 PortfolioManager:
  - select_portfolio(priorities, constraints) -> [ResearchProgram]

  Portfolio tracks:
  - active research
  - completed research
  - failed research
  - archived research

  Deterministic ordering enforced.
  """

  @program_table :research_programs

  def init_table do
    if :ets.info(@program_table) == :undefined do
      :ets.new(@program_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Create a research program"
  @spec create_program(String.t(), map()) :: {:ok, map()}
  def create_program(question_id, objectives) do
    init_table()
    program = build_program(question_id, objectives)
    {:ok, program}
  end

  @doc "Select portfolio deterministically"
  @spec select_portfolio([map()], map()) :: {:ok, [map()]}
  def select_portfolio(questions, _constraints) do
    portfolio = prioritize_programs(questions)
    {:ok, portfolio}
  end

  @doc "Lookup program by ID"
  @spec lookup_program(String.t()) :: {:ok, map()} | :error
  def lookup_program(program_id) do
    case :ets.lookup(@program_table, program_id) do
      [{^program_id, program}] -> {:ok, program}
      [] -> :error
    end
  end

  @doc "List all programs"
  @spec list_programs() :: [map()]
  def list_programs do
    :ets.tab2list(@program_table)
    |> Enum.map(fn {_id, p} -> p end)
  end

  # --- internal helpers ---

defp build_program(question_id, objectives) do
    canonical = canonicalize_map(objectives)
    json = Jason.encode!(canonical)
    program_id = "prog_" <> (:crypto.hash(:sha256, json) |> Base.encode16(case: :lower))

    %{
      "research_program_id" => program_id,
      "schema_version" => "16.1.0",
      "timestamp" => deterministic_timestamp(program_id),
      "primary_question_id" => question_id,
      "portfolio_rank_hint" => 0,
      "objectives" => [%{"objective_key" => "primary", "description" => Map.get(objectives, "description", "")}],
      "milestones" => [%{"milestone_key" => "initial", "expected_evidence_bundle_id" => nil, "stopping_rule_reference" => "default"}],
      "experiments" => [],
      "evidence_requirements" => [%{"evidence_type" => "STATISTICAL", "minimum_quantity" => 100, "required_quality" => "HIGH"}],
      "statistical_requirements" => %{"alpha" => 0.05, "target_power" => 0.8, "confidence_interval_target" => 0.95},
      "stopping_criteria" => [%{"criterion_type" => "CONFIDENCE", "threshold" => 0.95, "direction" => "REACH"}],
      "resource_constraints" => %{"max_compute_units" => 10000, "max_experiments" => 100}
    }
  end

  defp deterministic_timestamp(_seed) do
    "2000-01-01T00:00:00Z"
  end

  defp prioritize_programs(questions) do
    questions
    |> Enum.sort_by(fn q -> Map.get(q, "question_id", "") end)
    |> Enum.take(10)
  end

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term
end
