defmodule TiannaraRuntime.Civilization.Planning.CivilizationPlanner do
  def create_plan(_planner, name, horizon) do
    plan = %{
      id: "plan_#{:erlang.unique_integer([:positive])}",
      name: name,
      horizon: horizon,
      milestones: [],
      objectives: [],
      resources: %{},
      status: :draft,
      created_at: :erlang.unique_integer([:positive])
    }
    {:ok, plan}
  end

  def revise_plan(planner, plan_id, changes) do
    case Map.get(planner, plan_id) do
      nil -> {:error, :not_found}
      plan -> {:ok, Map.merge(plan, changes)}
    end
  end

  def compare_plans(planner, plan_a_id, plan_b_id) do
    plan_a = Map.get(planner, plan_a_id, %{})
    plan_b = Map.get(planner, plan_b_id, %{})
    comparison = %{
      milestone_count_diff: length(Map.get(plan_a, :milestones, [])) - length(Map.get(plan_b, :milestones, [])),
      horizon_diff: Map.get(plan_a, :horizon, 0) - Map.get(plan_b, :horizon, 0),
      resource_allocation: %{
        a: Map.get(plan_a, :resources, %{}),
        b: Map.get(plan_b, :resources, %{})
      }
    }
    {:ok, comparison}
  end

  def approve_plan(planner, plan_id) do
    case Map.get(planner, plan_id) do
      nil -> {:error, :not_found}
      plan -> {:ok, Map.put(plan, :status, :approved)}
    end
  end

  def metrics(planner) do
    plans = Map.values(planner)
    plan_count = length(plans)
    approved = Enum.count(plans, &(Map.get(&1, :status) == :approved))
    draft = Enum.count(plans, &(Map.get(&1, :status) == :draft))
    {:ok, %{plan_count: plan_count, approved: approved, draft: draft}}
  end
end
