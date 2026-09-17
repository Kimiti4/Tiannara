defmodule TiannaraRuntime.Cognitive.Engines.AttentionPolicy do
  @moduledoc false

  @default_criteria %{
    priority_weight: 0.4,
    dependency_depth_weight: 0.3,
    deadline_urgency_weight: 0.3
  }

  def get_default_criteria, do: @default_criteria

  def evaluate(task, criteria \\ @default_criteria) do
    priority = Map.get(task, :priority, 0.0)
    dependency_depth = Map.get(task, :dependency_depth, 1)
    deadline = Map.get(task, :deadline, :infinity)

    priority_score = priority * criteria.priority_weight
    depth_score = (1.0 / max(dependency_depth, 1)) * criteria.dependency_depth_weight
    deadline_score = deadline_urgency(deadline) * criteria.deadline_urgency_weight

    priority_score + depth_score + deadline_score
  end

  defp deadline_urgency(:infinity), do: 0.0
  defp deadline_urgency(deadline) when is_integer(deadline) do
    cond do
      deadline < 100 -> 1.0
      deadline < 1000 -> 0.5
      true -> 0.1
    end
  end
end
