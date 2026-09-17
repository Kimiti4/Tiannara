defmodule TiannaraRuntime.Cognitive.Planning.GoalDecomposer do
  alias TiannaraRuntime.Cognitive.Planning.Goal

  def decompose(mission) do
    objective = Map.get(mission, :objective, "default")
    {:ok, top_goal} = Goal.new(%{description: objective, parent_goal: nil, sub_goals: [], status: :pending})
    sub_descriptions = [
      "sub_#{objective}_1",
      "sub_#{objective}_2",
      "sub_#{objective}_3"
    ]
    sub_goals =
      Enum.map(sub_descriptions, fn desc ->
        {:ok, g} = Goal.new(%{description: desc, parent_goal: top_goal.id, sub_goals: [], status: :pending})
        g
      end)
    result = %{top_goal: top_goal, sub_goals: sub_goals}
    {:ok, result}
  end

  def get_hierarchy(decomposition) do
    sub_count = length(decomposition.sub_goals)
    {:ok, %{levels: [decomposition.top_goal | decomposition.sub_goals], goal_count: sub_count + 1}}
  end

  def validate_graph(decomposition) do
    top_goal = decomposition.top_goal
    sub_goals = decomposition.sub_goals
    cond do
      is_nil(top_goal.id) ->
        {:error, :invalid_reference}
      Enum.any?(sub_goals, fn sg -> sg.parent_goal != top_goal.id end) ->
        {:error, :invalid_reference}
      true ->
        :ok
    end
  end
end
