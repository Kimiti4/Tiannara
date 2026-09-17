defmodule TiannaraRuntime.Cognitive.Planning.PlanAssembler do
  @moduledoc "Phase 18.5 — Deterministic plan assembly from planning artifacts"

  def assemble(goal_hierarchy, task_graph, alternatives, ranked_alternatives, constraints) do
    {:ok, ranked} = ranked_alternatives
    top_ranked = hd(ranked)
    plan = %{id: "plan_#{:erlang.unique_integer([:positive])}", chosen_alternative: top_ranked.alternative, constraints: constraints, status: :ready}
    session = %{id: "sess_#{:erlang.unique_integer([:positive])}", goal_hierarchy: goal_hierarchy, task_graph: task_graph, alternatives: alternatives, ranked_alternatives: ranked, plan: plan, status: :active}
    {:ok, %{plan: plan, session: session}}
  end

  def to_execution_intent(plan) do
    intent = %{plan_id: plan.id, chosen_alternative_id: plan.chosen_alternative, constraints: plan.constraints, status: :ready}
    {:ok, intent}
  end
end
