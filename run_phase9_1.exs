goal = %Tiannara.ASC.Constitution.Goal{
  id: "goal_01",
  objective: "Improve Transfer Success Rate",
  success_metric: "Transfer Success Rate",
  target_value: 0.25,
  compute_budget: 500,
  deadline_epochs: 3,
  mode: :mission
}

Tiannara.ASC.Executive.run_mission(goal, fn active_goal ->
  # Task Generator ensures the Blackboard is seeded with the Executive's intent
  %Tiannara.ASC.Civilization.EngineeringTask{
    id: "task_#{:erlang.unique_integer([:positive])}",
    goal: active_goal.objective,
    assigned_genome: %{methodology: :default, exploration_bias: 0.5, exploitation_bias: 0.8}
  }
end)
