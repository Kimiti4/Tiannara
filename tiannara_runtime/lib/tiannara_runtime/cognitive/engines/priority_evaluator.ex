defmodule TiannaraRuntime.Cognitive.Engines.PriorityEvaluator do
  @moduledoc false

  alias TiannaraRuntime.Cognitive.Engines.AttentionPolicy

  def evaluate(task, criteria \\ AttentionPolicy.get_default_criteria()) do
    AttentionPolicy.evaluate(task, criteria)
  end

  def sort_by_score(tasks, criteria \\ AttentionPolicy.get_default_criteria()) do
    tasks
    |> Enum.map(fn task -> {task, evaluate(task, criteria)} end)
    |> Enum.sort_by(fn {_t, score} -> -score end)
    |> Enum.map(fn {task, _score} -> task end)
  end
end
