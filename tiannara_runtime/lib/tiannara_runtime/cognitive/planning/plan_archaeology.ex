defmodule TiannaraRuntime.Cognitive.Planning.PlanArchaeology do
  @moduledoc "Phase 18.5 — Deterministic planning archaeology recording and explanation"

  defstruct [:id, :artifact, :session_id, :origin, :lineage, :recorded_at]

  def record(artifact, session, origin) do
    lineage = %{
      goal_lineage: Map.get(session, :goal_hierarchy, %{}),
      constraint_lineage: Map.get(session, :constraints, []),
      alternative_lineage: Map.get(session, :alternatives, []),
      selection_lineage: Map.get(session, :ranked_alternatives, [])
    }
    archaeology = %{id: "arch_#{:erlang.unique_integer([:positive])}", artifact: artifact, session_id: session.id, origin: origin, lineage: lineage, recorded_at: :erlang.system_time(:millisecond)}
    {:ok, archaeology}
  end

  def explain(archaeology_record) do
    goal_count = length(Map.get(archaeology_record.lineage, :goal_lineage, %{}) |> Map.get(:goals, []))
    alt_count = length(Map.get(archaeology_record.lineage, :alternative_lineage, []))
    explanation = "Goal X was created because #{archaeology_record.origin}. " <>
      "It involved #{goal_count} goals and #{alt_count} alternatives. " <>
      "Selection was based on ranked evaluation of #{alt_count} candidates."
    {:ok, explanation}
  end

  def get_lineage(archaeology_record) do
    {:ok, archaeology_record.lineage}
  end
end
