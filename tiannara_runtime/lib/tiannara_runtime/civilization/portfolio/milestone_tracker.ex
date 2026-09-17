defmodule TiannaraRuntime.Civilization.Portfolio.MilestoneTracker do
  def initialize() do
    {:ok, %{milestones: %{}, program_milestones: %{}}}
  end

  def add_milestone(tracker, program_id, milestone) do
    id = Map.get(milestone, :id, "ms_#{:erlang.unique_integer([:positive])}")
    milestone = Map.put(milestone, :id, id)
    milestones = Map.put(tracker.milestones, id, milestone)
    prog_ids = Map.get(tracker.program_milestones, program_id, [])
    program_milestones = Map.put(tracker.program_milestones, program_id, prog_ids ++ [id])
    {:ok, %{tracker | milestones: milestones, program_milestones: program_milestones}}
  end

  def complete(tracker, milestone_id) do
    case Map.get(tracker.milestones, milestone_id) do
      nil -> {:ok, tracker}
      milestone ->
        completed = Map.put(milestone, :status, :completed)
        completed = Map.put(completed, :completed_at, :erlang.unique_integer([:positive]))
        {:ok, %{tracker | milestones: Map.put(tracker.milestones, milestone_id, completed)}}
    end
  end

  def get_program_milestones(tracker, program_id) do
    ids = Map.get(tracker.program_milestones, program_id, [])
    milestones = Enum.map(ids, fn id -> Map.get(tracker.milestones, id) end)
    {:ok, milestones}
  end

  def metrics(tracker) do
    total = map_size(tracker.milestones)
    completed = Enum.count(tracker.milestones, fn {_id, m} -> Map.get(m, :status) == :completed end)
    rate = if total == 0, do: 0.0, else: completed / total
    {:ok, %{total: total, completed: completed, completion_rate: rate}}
  end
end
