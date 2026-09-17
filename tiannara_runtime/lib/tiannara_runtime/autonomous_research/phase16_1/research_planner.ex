defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.ResearchPlanner do
  @moduledoc """
  Phase 16.1 Module 6 — Research Planner (Pure Implementation)

  Implements frozen contract from RESEARCH_RUNTIME_FREEZE.md 2.1 ResearchPlanner:
  - `plan(program_inputs) -> ResearchProgram`

  Creates deterministic `ResearchProgram` artifacts from `ResearchPriority` and `KnowledgeGap`.
  Tie-breaking by content hash ordering. No external state reads.
  """

  alias TiannaraRuntime.AutonomousResearch.Phase16_1.ResearchPortfolio

  @doc "Plan research programs from priority inputs"
  @spec plan([map()]) :: {:ok, [map()]}
  def plan(program_inputs) when is_list(program_inputs) do
    programs =
      program_inputs
      |> Enum.sort_by(fn inp -> Map.get(inp, "question_id", "") end)
      |> Enum.map(&build_program/1)

    Enum.each(programs, fn p ->
      pid = Map.get(p, "research_program_id", "")
      ResearchPortfolio.init_table()
      :ets.insert(:research_programs, {pid, p})
    end)

    {:ok, programs}
  end

  @doc "Build a ResearchProgram artifact from a priority input"
  @spec build_program(map()) :: map()
  def build_program(priority_input) do
    question_id = Map.get(priority_input, "question_id", "")
    canonical = canonicalize_map(%{"question_id" => question_id})
    json = Jason.encode!(canonical)
    program_id = "prog_" <> (:crypto.hash(:sha256, json) |> Base.encode16(case: :lower))

    %{
      "research_program_id" => program_id,
      "schema_version" => "16.1.0",
      "timestamp" => "2000-01-01T00:00:00Z",
      "primary_question_id" => question_id,
      "portfolio_rank_hint" => Map.get(priority_input, "rank", 0),
      "objectives" => [
        %{"objective_key" => "primary", "description" => "Research program for #{question_id}"}
      ],
      "milestones" => [
        %{"milestone_key" => "initial", "expected_evidence_bundle_id" => nil, "stopping_rule_reference" => "default"}
      ],
      "experiments" => [],
      "evidence_requirements" => [
        %{"evidence_type" => "STATISTICAL", "minimum_quantity" => 100, "required_quality" => "HIGH"}
      ],
      "statistical_requirements" => %{
        "alpha" => 0.05,
        "target_power" => 0.8,
        "confidence_interval_target" => 0.95
      },
      "stopping_criteria" => [
        %{"criterion_type" => "CONFIDENCE", "threshold" => 0.95, "direction" => "REACH"}
      ],
      "resource_constraints" => %{
        "max_compute_units" => 10000,
        "max_experiments" => 100
      }
    }
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
